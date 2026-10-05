import 'dart:io';

import 'package:flutter_architecture_checks/boundary_check.dart';
import 'package:test/test.dart';

void main() {
  late Directory fixture;
  late String policy;

  setUp(() {
    fixture = Directory.systemTemp.createTempSync('flutter_boundaries_');
    File('${fixture.path}/pubspec.yaml').writeAsStringSync('name: fixture\n');
    Directory('${fixture.path}/lib').createSync();
    policy = File('test/fixtures/architecture.yaml').readAsStringSync();
  });
  tearDown(() => fixture.deleteSync(recursive: true));

  void source(String path, String content) {
    final file = File('${fixture.path}/$path');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  ScanReport check() {
    final config = File('${fixture.path}/architecture.yaml')
      ..writeAsStringSync(policy);
    return scanBoundaries(
      project: fixture,
      config: config,
      now: DateTime.utc(2026, 10, 4),
    );
  }

  test('accepts presentation using its domain contract', () {
    source('lib/features/orders/domain/order.dart', 'class Order {}');
    source(
      'lib/features/orders/presentation/page.dart',
      "import 'package:fixture/features/orders/domain/order.dart';",
    );
    expect(check().findings, isEmpty);
  });

  test('rejects direct cross-feature implementation imports', () {
    source('lib/features/payments/data/stripe.dart', 'class Stripe {}');
    source(
      'lib/features/orders/presentation/page.dart',
      "import '../../payments/data/stripe.dart';",
    );
    expect(check().findings.map((f) => f.code), contains('cross_feature'));
  });

  test('checks the conditional URI, even when its platform is inactive', () {
    source('lib/features/orders/domain/order.dart', 'class Order {}');
    source('lib/features/orders/data/order_io.dart', 'class Order {}');
    source(
      'lib/features/orders/presentation/page.dart',
      "import '../domain/order.dart'\n"
          "if (dart.library.io) '../data/order_io.dart';",
    );
    expect(check().findings.map((f) => f.code), contains('layer'));
  });

  test('follows barrel exports when evaluating the consumer', () {
    source('lib/features/orders/data/order.dart', 'class Order {}');
    source('lib/features/orders/orders.dart', "export 'data/order.dart';");
    source(
      'lib/features/orders/application/load.dart',
      "import '../orders.dart';",
    );
    expect(
      check().findings.any(
        (f) =>
            f.code == 'transitive_layer' &&
            f.source.endsWith('application/load.dart'),
      ),
      isTrue,
    );
  });

  test('applies consumer package rules to external barrel exports', () {
    policy = policy.replaceFirst(
      'packages: [collection, meta, freezed_annotation]',
      'packages: [collection, meta, freezed_annotation, flutter]',
    );
    source(
      'lib/features/orders/orders.dart',
      "export 'package:flutter/widgets.dart';",
    );
    source(
      'lib/features/orders/application/load.dart',
      "import '../orders.dart';",
    );
    expect(check().findings.map((f) => f.code), contains('transitive_package'));
  });

  test('applies consumer SDK rules to indirect barrel exports', () {
    policy = policy.replaceFirst(
      'dart: [core, async, collection, math]',
      'dart: [core, async, collection, math, io]',
    );
    source('lib/features/orders/orders.dart', "export 'dart:io';");
    source(
      'lib/features/orders/application/load.dart',
      "import '../orders.dart';",
    );
    expect(check().findings.map((f) => f.code), contains('transitive_dart'));
  });

  test('reports feature cycles through approved public contracts', () {
    policy = policy.replaceFirst('cross_feature: []', '''
cross_feature:
  - {from: orders, to: payments}
  - {from: payments, to: orders}
''');
    source('lib/features/orders/orders.dart', "export 'domain/order.dart';");
    source(
      'lib/features/payments/payments.dart',
      "export 'domain/payment.dart';",
    );
    source(
      'lib/features/orders/domain/order.dart',
      "import '../../payments/payments.dart';",
    );
    source(
      'lib/features/payments/domain/payment.dart',
      "import '../../orders/orders.dart';",
    );
    expect(check().findings.map((f) => f.code), contains('feature_cycle'));
  });

  test('part directives cannot cross a feature or layer', () {
    source(
      'lib/features/orders/domain/order.dart',
      "part '../data/order_part.dart';",
    );
    source(
      'lib/features/orders/data/order_part.dart',
      "part of '../domain/order.dart';",
    );
    expect(check().findings.map((f) => f.code), contains('part_boundary'));
  });

  test('blocks src access into a third-party package', () {
    source(
      'lib/app/composition/wiring.dart',
      "import 'package:vendor/src/internal.dart';",
    );
    expect(check().findings.map((f) => f.code), contains('package_src'));
  });

  test('expired exceptions fail even if the underlying import was removed', () {
    policy = policy.replaceFirst('exceptions: []', '''
exceptions:
  - rule: layer
    source: lib/features/orders/presentation/page.dart
    target: lib/features/orders/data/order.dart
    owner: orders_team
    reason: migration
    issue: ARCH-1
    expires: '2026-10-04'
''');
    expect(check().findings.map((f) => f.code), contains('expired_exception'));
  });

  test('a valid exact exception suppresses only the specified edge', () {
    source('lib/features/orders/data/order.dart', 'class Order {}');
    source(
      'lib/features/orders/presentation/page.dart',
      "import '../data/order.dart';",
    );
    policy = policy.replaceFirst('exceptions: []', '''
exceptions:
  - rule: layer
    source: lib/features/orders/presentation/page.dart
    target: lib/features/orders/data/order.dart
    owner: orders_team
    reason: migration
    issue: ARCH-1
    expires: '2026-11-01'
''');
    expect(check().findings, isEmpty);
  });

  test('an active but unused exception must be removed', () {
    policy = policy.replaceFirst('exceptions: []', '''
exceptions:
  - rule: layer
    source: lib/features/orders/presentation/page.dart
    target: lib/features/orders/data/order.dart
    owner: orders_team
    reason: migration
    issue: ARCH-1
    expires: '2026-11-01'
''');
    expect(check().findings.map((f) => f.code), contains('unused_exception'));
  });

  test('syntactically invalid Dart cannot silently pass', () {
    source('lib/features/orders/domain/order.dart', 'class {');
    expect(check().findings.map((f) => f.code), contains('parse_error'));
  });

  test('ignores comments and string contents that resemble directives', () {
    source(
      'lib/features/orders/domain/order.dart',
      '// import "package:flutter/material.dart";\n'
          'const sample = "import forbidden";',
    );
    expect(check().findings, isEmpty);
  });

  test('unclassified sources cannot bypass the policy', () {
    source('lib/misc/orders.dart', 'class Order {}');
    expect(check().findings.map((f) => f.code), contains('unclassified'));
  });

  test('relative paths cannot escape the lib source scope', () {
    source(
      'lib/features/orders/domain/order.dart',
      "import '../../../../outside.dart';",
    );
    expect(check().findings.map((f) => f.code), contains('outside_scope'));
  });

  test('own package URIs must resolve to an existing source', () {
    source(
      'lib/features/orders/domain/order.dart',
      "import 'package:fixture/features/orders/domain/missing.dart';",
    );
    expect(check().findings.map((f) => f.code), contains('missing_source'));
  });

  test('source symlinks cannot hide an unchecked source tree', () {
    source('lib/features/orders/domain/order.dart', 'class Order {}');
    Link('${fixture.path}/lib/hidden').createSync('features/orders/domain');
    expect(check().findings.map((f) => f.code), contains('source_symlink'));
  });

  test(
    'named part-of fails clearly instead of silently skipping ownership',
    () {
      source(
        'lib/features/orders/domain/order_part.dart',
        'part of order_library;',
      );
      expect(check().findings.map((f) => f.code), contains('unsupported_part'));
    },
  );

  ProcessResult command() => Process.runSync(Platform.resolvedExecutable, [
    'run',
    'bin/check_boundaries.dart',
    '--root',
    fixture.path,
    '--config',
    '${fixture.path}/architecture.yaml',
  ]);

  test('CLI returns zero for a valid project', () {
    source('lib/features/orders/domain/order.dart', 'class Order {}');
    check();
    expect(command().exitCode, 0);
  });

  test('CLI returns one for an architecture violation', () {
    source('lib/features/orders/presentation/page.dart', "import 'dart:io';");
    check();
    expect(command().exitCode, 1);
  });

  test('CLI returns two if the policy cannot be read', () {
    File('${fixture.path}/architecture.yaml').writeAsStringSync('groups: []');
    expect(command().exitCode, 2);
  });
}
