import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class Finding {
  const Finding(this.code, this.source, this.target, this.detail);
  final String code;
  final String source;
  final String target;
  final String detail;
}

class ScanReport {
  const ScanReport(this.findings, {this.suppressed = 0});
  final List<Finding> findings;
  final int suppressed;
}

ScanReport scanBoundaries({
  required Directory project,
  required File config,
  DateTime? now,
}) {
  final root = project.resolveSymbolicLinksSync();
  final lib = p.join(root, 'lib');
  if (!Directory(lib).existsSync()) {
    throw const FormatException('Project must contain lib/.');
  }
  final pubspec = _map(
    loadYaml(File(p.join(root, 'pubspec.yaml')).readAsStringSync()),
  );
  final packageName = _required(pubspec, 'name');
  final policy = _map(loadYaml(config.readAsStringSync()));
  if (policy['schema_version'] != 1) {
    throw const FormatException('Unsupported boundary policy schema.');
  }
  final groups = _list(
    policy['groups'],
  ).map((value) => _Group(_map(value))).toList();
  if (groups.isEmpty ||
      groups.map((g) => g.id).toSet().length != groups.length) {
    throw const FormatException('Groups must have distinct IDs.');
  }
  final ids = groups.map((g) => g.id).toSet();
  for (final group in groups) {
    if (group.allow.any((id) => id != '*' && !ids.contains(id))) {
      throw FormatException('Unknown allowed group for ${group.id}.');
    }
  }
  final approvals = _list(policy['cross_feature']).map((value) {
    final record = _map(value);
    return '${_required(record, 'from')}->${_required(record, 'to')}';
  }).toSet();
  final exceptions = _list(
    policy['exceptions'],
  ).map((value) => _Exception(_map(value))).toList();
  if (exceptions.map((e) => e.key).toSet().length != exceptions.length) {
    throw const FormatException('Duplicate exact exceptions.');
  }
  final today = (now ?? DateTime.now()).toUtc();
  final issues = <Finding>[];
  final nodes = <String, _Node>{};
  String relative(String path) =>
      p.relative(path, from: root).split(p.separator).join('/');
  void add(String code, String source, String target, String detail) =>
      issues.add(Finding(code, source, target, detail));

  for (final entity in Directory(
    lib,
  ).listSync(recursive: true, followLinks: false)) {
    if (entity is Link) {
      add(
        'source_symlink',
        relative(entity.path),
        '',
        'Symlink source is outside the supported policy.',
      );
      continue;
    }
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = relative(entity.path);
    final matches = groups.where(
      (g) => g.files.any((glob) => glob.matches(path)),
    );
    if (matches.isEmpty) {
      add('unclassified', path, '', 'No boundary group matches this source.');
      continue;
    }
    final node = _Node(path, matches.first);
    nodes[path] = node;
    final parsed = parseString(
      content: entity.readAsStringSync(),
      path: entity.path,
      throwIfDiagnostics: false,
    );
    if (parsed.errors.isNotEmpty) {
      add(
        'parse_error',
        path,
        '',
        'Dart syntax errors; run dart/flutter analyze for diagnostics.',
      );
      continue;
    }
    for (final directive in parsed.unit.directives) {
      if (directive is UriBasedDirective) {
        final uri = directive.uri.stringValue;
        if (uri == null) {
          add('invalid_uri', path, '', 'Directive must use a static URI.');
          continue;
        }
        node.refs.add(
          _Ref(uri, directive is ExportDirective, directive is PartDirective),
        );
        if (directive is NamespaceDirective) {
          for (final variant in directive.configurations) {
            final value = variant.uri.stringValue;
            if (value == null) {
              add('invalid_uri', path, '', 'Conditional URI must be static.');
            } else {
              node.refs.add(_Ref(value, directive is ExportDirective, false));
            }
          }
        }
      } else if (directive is PartOfDirective) {
        final uri = directive.uri?.stringValue;
        if (uri == null) {
          add(
            'unsupported_part',
            path,
            '',
            'Named part-of needs an explicit library-aware checker.',
          );
        } else {
          node.refs.add(_Ref(uri, false, true));
        }
      }
    }
  }

  final featureGraph = <String, Set<String>>{};
  for (final node in nodes.values) {
    for (final ref in node.refs) {
      final uri = Uri.tryParse(ref.uri);
      if (uri == null || uri.hasQuery || uri.hasFragment) {
        add('invalid_uri', node.path, ref.uri, 'Invalid source URI.');
        continue;
      }
      if (uri.scheme == 'dart') {
        if (ref.isExport) node.externalExports.add(uri);
        if (!_allows(node.group.dart, uri.path)) {
          add('dart', node.path, ref.uri, 'SDK library is not allowed.');
        }
        continue;
      }
      String target;
      if (uri.scheme == 'package') {
        final segments = uri.pathSegments;
        if (segments.length < 2 ||
            segments.any((s) => s.isEmpty || s == '..' || s == '.')) {
          add('invalid_uri', node.path, ref.uri, 'Invalid package URI.');
          continue;
        }
        if (segments.first != packageName) {
          if (ref.isExport) node.externalExports.add(uri);
          if (segments.skip(1).contains('src')) {
            add(
              'package_src',
              node.path,
              ref.uri,
              'Third-party package src is private implementation.',
            );
          }
          if (!_allows(node.group.packages, segments.first)) {
            add(
              'package',
              node.path,
              ref.uri,
              'Package is not allowed for this layer.',
            );
          }
          continue;
        }
        target = p.posix.normalize('lib/${segments.skip(1).join('/')}');
      } else if (uri.scheme.isEmpty &&
          !uri.hasAuthority &&
          !p.posix.isAbsolute(uri.path)) {
        target = p.posix.normalize(
          p.posix.join(p.posix.dirname(node.path), uri.path),
        );
      } else {
        add(
          'outside_scope',
          node.path,
          ref.uri,
          'Only dart/package and project-local lib URIs are supported.',
        );
        continue;
      }
      if (!target.startsWith('lib/')) {
        add('outside_scope', node.path, target, 'URI escapes lib/.');
        continue;
      }
      final destination = nodes[target];
      if (destination == null) {
        add(
          'missing_source',
          node.path,
          target,
          'Source is missing, unclassified, or not a regular Dart file.',
        );
        continue;
      }
      node.edges.add(destination);
      if (ref.isExport) node.exports.add(destination);
      if (!_allows(node.group.allow, destination.group.id)) {
        add(
          'layer',
          node.path,
          target,
          'Layer ${node.group.id} cannot depend on ${destination.group.id}.',
        );
      }
      final from = _feature(node.path);
      final to = _feature(target);
      if (ref.isPart && (from != to || node.group.id != destination.group.id)) {
        add(
          'part_boundary',
          node.path,
          target,
          'Part and owner must remain in the same feature and layer.',
        );
      }
      if (from != null && to != null && from != to && !node.isAssembly) {
        featureGraph.putIfAbsent(from, () => <String>{}).add(to);
        if (target != 'lib/features/$to/$to.dart' ||
            !approvals.contains('$from->$to')) {
          add(
            'cross_feature',
            node.path,
            target,
            'Cross-feature access needs an approved narrow public contract.',
          );
        }
      }
    }
  }

  for (final consumer in nodes.values) {
    for (final imported in consumer.edges) {
      final visited = <String>{imported.path};
      void exported(_Node node) {
        for (final uri in node.externalExports) {
          final sdk = uri.scheme == 'dart';
          final allowed = sdk ? consumer.group.dart : consumer.group.packages;
          final name = sdk ? uri.path : uri.pathSegments.first;
          if (!_allows(allowed, name)) {
            add(
              sdk ? 'transitive_dart' : 'transitive_package',
              consumer.path,
              uri.toString(),
              'Export chain exposes a library not allowed for the consumer.',
            );
          }
        }
        for (final target in node.exports) {
          if (!visited.add(target.path)) continue;
          if (!_allows(consumer.group.allow, target.group.id)) {
            add(
              'transitive_layer',
              consumer.path,
              target.path,
              'Export chain exposes a forbidden layer.',
            );
          }
          exported(target);
        }
      }

      exported(imported);
    }
  }
  final completed = <String>{};
  final stack = <String>[];
  void visit(String feature) {
    if (stack.contains(feature)) {
      add(
        'feature_cycle',
        feature,
        feature,
        'Feature cycle: ${[...stack.skip(stack.indexOf(feature)), feature].join(' -> ')}',
      );
      return;
    }
    if (completed.contains(feature)) return;
    stack.add(feature);
    for (final next in featureGraph[feature] ?? <String>{}) {
      visit(next);
    }
    stack.removeLast();
    completed.add(feature);
  }

  for (final feature in featureGraph.keys) {
    visit(feature);
  }

  final deduplicated = <String, Finding>{};
  for (final issue in issues) {
    deduplicated['${issue.code}|${issue.source}|${issue.target}'] = issue;
  }
  final valid = <String, _Exception>{};
  for (final record in exceptions) {
    if (!today.isBefore(record.expires)) {
      add(
        'expired_exception',
        record.source,
        record.target,
        'Exception expired at ${record.expires.toIso8601String()}.',
      );
    } else {
      valid[record.key] = record;
    }
  }
  // Expiry findings were appended after deduplication; they must still block.
  final finalIssues = issues
      .where((f) => f.code == 'expired_exception')
      .toList();
  final used = <String>{};
  for (final entry in deduplicated.entries) {
    if (valid.containsKey(entry.key)) {
      used.add(entry.key);
    } else {
      finalIssues.add(entry.value);
    }
  }
  for (final record in valid.values) {
    if (!used.contains(record.key)) {
      finalIssues.add(
        Finding(
          'unused_exception',
          record.source,
          record.target,
          'Exception no longer matches a violation.',
        ),
      );
    }
  }
  finalIssues.sort(
    (a, b) => '${a.source}|${a.code}|${a.target}'.compareTo(
      '${b.source}|${b.code}|${b.target}',
    ),
  );
  return ScanReport(List.unmodifiable(finalIssues), suppressed: used.length);
}

Map<dynamic, dynamic> _map(Object? value) {
  if (value is! Map) throw const FormatException('Expected YAML mapping.');
  return value;
}

List<dynamic> _list(Object? value) {
  if (value is! List) throw const FormatException('Expected YAML list.');
  return value;
}

String _required(Map<dynamic, dynamic> map, String key) {
  final value = map[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing non-empty $key.');
  }
  return value;
}

List<String> _strings(Object? value) => _list(value).map((item) {
  if (item is! String || item.isEmpty)
    throw const FormatException('Expected string list.');
  return item;
}).toList();

bool _allows(List<String> allowed, String value) =>
    allowed.contains('*') || allowed.contains(value);

String? _feature(String path) =>
    RegExp(r'^lib/features/([^/]+)/').firstMatch(path)?.group(1);

class _Group {
  _Group(Map<dynamic, dynamic> record)
    : id = _required(record, 'id'),
      files = _strings(record['files']).map(Glob.new).toList(),
      allow = _strings(record['allow']),
      packages = _strings(record['packages']),
      dart = _strings(record['dart']);
  final String id;
  final List<Glob> files;
  final List<String> allow;
  final List<String> packages;
  final List<String> dart;
}

class _Node {
  _Node(this.path, this.group);
  final String path;
  final _Group group;
  final refs = <_Ref>[];
  final edges = <_Node>[];
  final exports = <_Node>[];
  final externalExports = <Uri>[];
  bool get isAssembly => group.id == 'entry' || group.id == 'composition';
}

class _Ref {
  _Ref(this.uri, this.isExport, this.isPart);
  final String uri;
  final bool isExport;
  final bool isPart;
}

class _Exception {
  _Exception(Map<dynamic, dynamic> record)
    : code = _required(record, 'rule'),
      source = _required(record, 'source'),
      target = _required(record, 'target'),
      expires = _date(_required(record, 'expires')) {
    for (final key in ['owner', 'reason', 'issue']) {
      _required(record, key);
    }
    if (![
          'layer',
          'transitive_layer',
          'transitive_package',
          'transitive_dart',
          'cross_feature',
          'package',
          'dart',
        ].contains(code) ||
        !source.startsWith('lib/') ||
        !source.endsWith('.dart') ||
        source.contains('..') ||
        [source, target].any((s) => s.contains('*') || s.contains('?'))) {
      throw const FormatException(
        'Exception must name an exact suppressible source/target/rule.',
      );
    }
  }
  final String code;
  final String source;
  final String target;
  final DateTime expires;
  String get key => '$code|$source|$target';
  static DateTime _date(String value) {
    final parsed = DateTime.tryParse(value);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
        parsed == null ||
        parsed.toIso8601String().split('T').first != value) {
      throw const FormatException('expires must be a valid YYYY-MM-DD.');
    }
    return DateTime.utc(parsed.year, parsed.month, parsed.day);
  }
}
