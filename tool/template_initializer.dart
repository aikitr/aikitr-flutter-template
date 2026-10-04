import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

const Set<String> _excludedDirectoryNames = <String>{
  '.git',
  '.idea',
  '.vscode',
  '.DS_Store',
  '.dart_tool',
  '.fvm',
  '.flutter-plugins',
  '.flutter-plugins-dependencies',
  '.packages',
  'build',
  'coverage',
  'ephemeral',
  'Generated.xcconfig',
  'flutter_export_environment.sh',
};

Future<void> initializeTemplate({
  required Directory templateRoot,
  required Directory targetDirectory,
  required String projectName,
  required String displayName,
  required String bundleIdentifier,
}) async {
  final String packageName = _packageName(projectName);
  final String cleanDisplayName = displayName.trim();
  _validateDisplayName(cleanDisplayName);
  _validateBundleIdentifier(bundleIdentifier);

  final String sourcePath = path.normalize(templateRoot.absolute.path);
  final String targetPath = path.normalize(targetDirectory.absolute.path);
  if (targetPath == sourcePath || path.isWithin(sourcePath, targetPath)) {
    throw ArgumentError.value(
      targetDirectory.path,
      'targetDirectory',
      'The destination must be outside the template directory.',
    );
  }
  if (!await Directory(sourcePath).exists()) {
    throw ArgumentError.value(templateRoot.path, 'templateRoot', 'Not found.');
  }

  final Directory destination = Directory(targetPath);
  if (await destination.exists()) {
    final List<FileSystemEntity> existing = await destination
        .list(followLinks: false)
        .take(1)
        .toList();
    if (existing.isNotEmpty) {
      throw FileSystemException(
        'The destination directory must be empty.',
        destination.path,
      );
    }
  } else {
    await destination.create(recursive: true);
  }

  await _copyDirectory(
    Directory(sourcePath),
    destination,
    packageName: packageName,
    displayName: cleanDisplayName,
    bundleIdentifier: bundleIdentifier,
  );
}

String _packageName(String name) {
  final String normalized = name
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '')
      .toLowerCase();
  if (normalized.isEmpty ||
      !RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(normalized)) {
    throw ArgumentError.value(
      name,
      'projectName',
      'Cannot form a Dart package name.',
    );
  }
  const Set<String> reserved = <String>{
    'abstract',
    'as',
    'assert',
    'async',
    'await',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'default',
    'do',
    'else',
    'enum',
    'export',
    'extends',
    'extension',
    'external',
    'factory',
    'false',
    'final',
    'finally',
    'for',
    'function',
    'get',
    'hide',
    'if',
    'implements',
    'import',
    'in',
    'interface',
    'is',
    'late',
    'library',
    'mixin',
    'new',
    'null',
    'on',
    'operator',
    'part',
    'required',
    'rethrow',
    'return',
    'sealed',
    'set',
    'show',
    'static',
    'super',
    'switch',
    'sync',
    'this',
    'throw',
    'true',
    'try',
    'typedef',
    'var',
    'void',
    'while',
    'with',
    'yield',
  };
  return reserved.contains(normalized) ? '${normalized}_app' : normalized;
}

void _validateDisplayName(String displayName) {
  if (displayName.isEmpty || displayName.contains(RegExp(r'[\r\n]'))) {
    throw ArgumentError.value(
      displayName,
      'displayName',
      'Must be a single non-empty line.',
    );
  }
}

void _validateBundleIdentifier(String bundleIdentifier) {
  final RegExp validIdentifier = RegExp(
    r'^[A-Za-z][A-Za-z0-9-]*(\.[A-Za-z][A-Za-z0-9-]*)+$',
  );
  if (!validIdentifier.hasMatch(bundleIdentifier)) {
    throw ArgumentError.value(
      bundleIdentifier,
      'bundleIdentifier',
      'Use a reverse-domain identifier such as com.example.weather.',
    );
  }
}

Future<void> _copyDirectory(
  Directory source,
  Directory destination, {
  required String packageName,
  required String displayName,
  required String bundleIdentifier,
}) async {
  await for (final FileSystemEntity entry in source.list(
    followLinks: false,
    recursive: false,
  )) {
    final String name = path.basename(entry.path);
    if (_excludedDirectoryNames.contains(name)) continue;
    final String outputPath = path.join(destination.path, name);
    final FileSystemEntityType type = await FileSystemEntity.type(
      entry.path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.directory) {
      final Directory child = Directory(outputPath)..createSync();
      await _copyDirectory(
        Directory(entry.path),
        child,
        packageName: packageName,
        displayName: displayName,
        bundleIdentifier: bundleIdentifier,
      );
      continue;
    }
    if (type != FileSystemEntityType.file) continue;

    final File output = await File(entry.path).copy(outputPath);
    await _replaceTextTokens(
      output,
      packageName: packageName,
      displayName: displayName,
      bundleIdentifier: bundleIdentifier,
    );
  }
}

Future<void> _replaceTextTokens(
  File file, {
  required String packageName,
  required String displayName,
  required String bundleIdentifier,
}) async {
  final List<int> bytes = await file.readAsBytes();
  String source;
  try {
    source = utf8.decode(bytes);
  } on FormatException {
    return;
  }
  final String output = source
      .replaceAll('app_template', packageName)
      .replaceAll(
        '__APP_DISPLAY_NAME__',
        _jsonSafeDisplayName(file, displayName),
      )
      .replaceAll('__APP_BUNDLE_ID__', bundleIdentifier);
  if (output != source) await file.writeAsString(output, flush: true);
}

String _jsonSafeDisplayName(File file, String displayName) {
  if (!file.path.endsWith('.arb')) return displayName;
  final String quoted = jsonEncode(displayName);
  return quoted.substring(1, quoted.length - 1);
}
