import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unflavored Runner configuration is isolated as dev', () {
    for (final String mode in <String>['Debug', 'Release']) {
      final String config = File('ios/Flutter/$mode.xcconfig')
          .readAsStringSync();
      expect(config, contains('#include "Generated.xcconfig"'));
      expect(config, isNot(contains('FLUTTER_TARGET =')));
      expect(
        config,
        contains(r'APP_EFFECTIVE_BUNDLE_ID = $(APP_BASE_BUNDLE_ID).dev'),
      );
      expect(
        config,
        contains(r'APP_DISPLAY_NAME = $(APP_BASE_DISPLAY_NAME) (Dev)'),
      );
    }
  });

  group('iOS flavor configuration', () {
    for (final String flavor in <String>['dev', 'staging', 'prod']) {
      test('$flavor scheme preserves Flutter target and configurations', () {
        final String scheme = File(
          'ios/Runner.xcodeproj/xcshareddata/xcschemes/$flavor.xcscheme',
        ).readAsStringSync();
        final String target = 'lib/main_$flavor.dart';
        expect(File(target).existsSync(), isTrue, reason: target);
        expect(
          File('README.md').readAsStringSync(),
          contains('--target $target'),
        );

        expect(_actionConfiguration(scheme, 'TestAction'), 'Debug-$flavor');
        expect(_actionConfiguration(scheme, 'LaunchAction'), 'Debug-$flavor');
        expect(
          _actionConfiguration(scheme, 'ProfileAction'),
          'Profile-$flavor',
        );
        expect(
          _actionConfiguration(scheme, 'ArchiveAction'),
          'Release-$flavor',
        );

        for (final String mode in <String>['Debug', 'Release', 'Profile']) {
          final File config = File('ios/Flutter/Flavor-$mode-$flavor.xcconfig');
          expect(config.existsSync(), isTrue, reason: config.path);
          expect(
            config.readAsStringSync(),
            isNot(contains('FLUTTER_TARGET =')),
          );
        }

        final String releaseConfig = File(
          'ios/Flutter/Flavor-Release-$flavor.xcconfig',
        ).readAsStringSync();
        final String bundleSuffix = flavor == 'prod' ? '' : '.$flavor';
        final String displaySuffix = switch (flavor) {
          'dev' => ' (Dev)',
          'staging' => ' (Staging)',
          _ => '',
        };
        expect(
          releaseConfig,
          contains(
            'APP_EFFECTIVE_BUNDLE_ID = \$(APP_BASE_BUNDLE_ID)$bundleSuffix',
          ),
        );
        expect(
          releaseConfig,
          contains(
            'APP_DISPLAY_NAME = \$(APP_BASE_DISPLAY_NAME)$displaySuffix',
          ),
        );

        final String project = File('ios/Runner.xcodeproj/project.pbxproj')
            .readAsStringSync();
        for (final String mode in <String>['Debug', 'Release', 'Profile']) {
          expect(project, contains('name = $mode-$flavor;'));
          expect(
            RegExp(
              'baseConfigurationReference = [A-F0-9]+ /\\* '
              'Flavor-$mode-$flavor\\.xcconfig \\*/;',
            ).allMatches(project).length,
            greaterThanOrEqualTo(2),
            reason: 'Project and app targets must share $mode-$flavor settings',
          );
        }
      });
    }
  });
}

String _actionConfiguration(String scheme, String action) {
  final RegExpMatch? match = RegExp(
    '<$action\\s+buildConfiguration\\s*=\\s*"([^"]+)"',
  ).firstMatch(scheme);
  expect(match, isNotNull, reason: '$action should select a configuration');
  return match!.group(1)!;
}
