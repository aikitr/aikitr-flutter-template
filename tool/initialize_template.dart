import 'dart:io';

import 'package:path/path.dart' as path;

import 'template_initializer.dart';

const String _usage = '''
Initialize a clean copy of the Flutter iOS template.

Usage:
  dart run tool/initialize_template.dart \\
    --target <directory> --project-name <name> \\
    --display-name <name> --bundle-id <com.example.app>

The destination must be empty or not exist. Bundle ID is the production ID;
the dev and staging flavors automatically add .dev and .staging.
''';

Future<void> main(List<String> arguments) async {
  if (arguments.contains('--help') || arguments.contains('-h')) {
    stdout.write(_usage);
    return;
  }
  try {
    final Map<String, String> options = _parseOptions(arguments);
    const Set<String> required = <String>{
      '--target',
      '--project-name',
      '--display-name',
      '--bundle-id',
    };
    final Set<String> missing = required.difference(options.keys.toSet());
    if (missing.isNotEmpty) {
      throw FormatException('Missing required options: ${missing.join(', ')}');
    }
    final String scriptPath = path.fromUri(Platform.script);
    final Directory templateRoot = Directory(
      path.normalize(path.join(path.dirname(scriptPath), '..')),
    );
    final Directory destination = Directory(options['--target']!);
    await initializeTemplate(
      templateRoot: templateRoot,
      targetDirectory: destination,
      projectName: options['--project-name']!,
      displayName: options['--display-name']!,
      bundleIdentifier: options['--bundle-id']!,
    );
    stdout
      ..writeln('Created ${destination.absolute.path}')
      ..writeln('Next steps:')
      ..writeln('  cd "${destination.path}"')
      ..writeln('  fvm flutter pub get')
      ..writeln('  fvm dart run build_runner build')
      ..writeln('  fvm flutter gen-l10n')
      ..writeln(
        '  fvm flutter run --flavor dev --target lib/main_dev.dart '
        '--dart-define-from-file=config/dev.json',
      );
  } on Object catch (error) {
    stderr
      ..writeln(error)
      ..writeln()
      ..write(_usage);
    exitCode = 64;
  }
}

Map<String, String> _parseOptions(List<String> arguments) {
  if (arguments.length.isOdd) {
    throw const FormatException(
      'Options must be provided as name/value pairs.',
    );
  }
  final Map<String, String> options = <String, String>{};
  for (int index = 0; index < arguments.length; index += 2) {
    final String name = arguments[index];
    const Set<String> supported = <String>{
      '--target',
      '--project-name',
      '--display-name',
      '--bundle-id',
    };
    if (!supported.contains(name)) {
      throw FormatException('Unknown option: $name');
    }
    if (options.containsKey(name)) {
      throw FormatException('Repeated option: $name');
    }
    options[name] = arguments[index + 1];
  }
  return options;
}
