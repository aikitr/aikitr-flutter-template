import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/template_initializer.dart';

void main() {
  late Directory sandbox;
  late Directory source;
  late Directory target;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('template-initializer-');
    source = Directory('${sandbox.path}/template')..createSync();
    target = Directory('${sandbox.path}/generated-app');
    File('${source.path}/pubspec.yaml')
        .writeAsStringSync('name: app_template\n');
    File(
      '${source.path}/README.md',
    ).writeAsStringSync('# __APP_DISPLAY_NAME__\nBundle: __APP_BUNDLE_ID__\n');
    Directory('${source.path}/lib').createSync();
    File('${source.path}/lib/app_config.dart')
        .writeAsStringSync("const fallbackBundleId = '__APP_BUNDLE_ID__';\n");
    File('${source.path}/LICENSE').writeAsStringSync('license text');
    Directory('${source.path}/.git').createSync();
    File('${source.path}/.git/config').writeAsStringSync('git metadata');
    Directory('${source.path}/.dart_tool').createSync();
    File('${source.path}/.dart_tool/package_config.json')
        .writeAsStringSync('generated cache');
    Directory('${source.path}/.vscode').createSync();
    File('${source.path}/.vscode/settings.json')
        .writeAsStringSync('editor settings');
    Directory('${source.path}/build').createSync();
    File('${source.path}/build/output').writeAsStringSync('build output');
    File('${source.path}/.DS_Store').writeAsStringSync('Finder metadata');
    File('${source.path}/.flutter-plugins-dependencies')
        .writeAsStringSync('plugin cache');
  });

  tearDown(() async {
    if (await sandbox.exists()) await sandbox.delete(recursive: true);
  });

  test(
    'copies the template, substitutes project identity, and skips caches',
    () async {
      await initializeTemplate(
        templateRoot: source,
        targetDirectory: target,
        projectName: 'My Weather App',
        displayName: 'My Weather',
        bundleIdentifier: 'com.example.weather',
      );

      expect(
        File('${target.path}/pubspec.yaml').readAsStringSync(),
        'name: my_weather_app\n',
      );
      expect(
        File('${target.path}/README.md').readAsStringSync(),
        '# My Weather\nBundle: com.example.weather\n',
      );
      expect(File('${target.path}/LICENSE').readAsStringSync(), 'license text');
      expect(
        File('${target.path}/lib/app_config.dart').readAsStringSync(),
        "const fallbackBundleId = 'com.example.weather';\n",
      );
      expect(Directory('${target.path}/.git').existsSync(), isFalse);
      expect(Directory('${target.path}/.dart_tool').existsSync(), isFalse);
      expect(Directory('${target.path}/.vscode').existsSync(), isFalse);
      expect(Directory('${target.path}/build').existsSync(), isFalse);
      expect(File('${target.path}/.DS_Store').existsSync(), isFalse);
      expect(
        File('${target.path}/.flutter-plugins-dependencies').existsSync(),
        isFalse,
      );
      expect(
        File('${source.path}/pubspec.yaml').readAsStringSync(),
        'name: app_template\n',
      );
    },
  );

  test('refuses to write into a non-empty target directory', () async {
    target.createSync();
    final sentinel = File('${target.path}/keep.txt')..writeAsStringSync('keep');

    await expectLater(
      initializeTemplate(
        templateRoot: source,
        targetDirectory: target,
        projectName: 'Weather',
        displayName: 'Weather',
        bundleIdentifier: 'com.example.weather',
      ),
      throwsA(isA<FileSystemException>()),
    );

    expect(sentinel.readAsStringSync(), 'keep');
  });

  test(
    'rejects an invalid bundle identifier before creating the target',
    () async {
      await expectLater(
        initializeTemplate(
          templateRoot: source,
          targetDirectory: target,
          projectName: 'Weather',
          displayName: 'Weather',
          bundleIdentifier: 'com..weather',
        ),
        throwsArgumentError,
      );

      expect(target.existsSync(), isFalse);
    },
  );
}
