"""Read-only gate for repositories that commit generated Dart sources."""

import argparse
import json
import os
from pathlib import Path, PurePosixPath
import subprocess
import sys

CACHE_PARTS = {".dart_tool", ".git", ".fvm", ".idea", "__pycache__"}


def inspect_sources(root, paths):
    root = Path(root).resolve(strict=True)

    def git(*args):
        result = subprocess.run(
            ["git", *args], cwd=root, capture_output=True, check=True
        )
        return result.stdout

    repository = Path(os.fsdecode(git("rev-parse", "--show-toplevel")).strip()).resolve()
    if root != repository:
        raise ValueError("--root must be the Git repository root")
    scopes = []
    for value in paths:
        scope = PurePosixPath(value)
        if scope.is_absolute() or ".." in scope.parts or not scope.parts:
            raise ValueError("source scopes must be non-empty relative paths")
        if not (root / scope).resolve().is_relative_to(root):
            raise ValueError("source scope resolves outside the repository")
        scopes.append(scope.as_posix())
    if not scopes:
        raise ValueError("at least one source scope is required")

    def names(data):
        return {os.fsdecode(name) for name in data.split(b"\0") if name}

    def is_source(name):
        parts = PurePosixPath(name).parts
        if CACHE_PARTS.intersection(parts):
            return False
        # build/coverage are caches only at a package root, not lib/build etc.
        for index, part in enumerate(parts):
            if part in {"build", "coverage"}:
                parent = root.joinpath(*parts[:index])
                if (parent / "pubspec.yaml").is_file():
                    return False
        return True

    # HEAD compares both the index and working tree; new outputs need ls-files.
    tracked = names(git("diff", "--name-only", "-z", "HEAD", "--", *scopes))
    untracked = names(git("ls-files", "-z", "--others", "--exclude-standard", "--", *scopes))
    ignored = names(git("ls-files", "-z", "--others", "--ignored", "--exclude-standard", "--", *scopes))
    unexpected = tracked | untracked | {name for name in ignored if name.endswith(".dart")}
    return sorted(name for name in unexpected if is_source(name))


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".")
    parser.add_argument("--paths", nargs="+", default=["lib", "test", "integration_test", "tool"])
    args = parser.parse_args(argv)
    try:
        changes = inspect_sources(args.root, args.paths)
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f"Generated source check could not complete: {error}", file=sys.stderr)
        return 2
    print(json.dumps({"ok": not changes, "unexpected_sources": changes}, ensure_ascii=False))
    return 1 if changes else 0


if __name__ == "__main__":
    sys.exit(main())
