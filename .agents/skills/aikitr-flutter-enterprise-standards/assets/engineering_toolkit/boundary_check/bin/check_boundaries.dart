import 'dart:convert';
import 'dart:io';

import 'package:flutter_architecture_checks/boundary_check.dart';

void main(List<String> args) {
  try {
    String option(String key) {
      final index = args.indexOf(key);
      if (index < 0 || index + 1 >= args.length) {
        throw FormatException('Required option: $key');
      }
      return args[index + 1];
    }

    final report = scanBoundaries(
      project: Directory(option('--root')),
      config: File(option('--config')),
    );
    stdout.writeln(
      jsonEncode({
        'ok': report.findings.isEmpty,
        'suppressed': report.suppressed,
        'findings': [
          for (final finding in report.findings)
            {
              'code': finding.code,
              'source': finding.source,
              'target': finding.target,
              'detail': finding.detail,
            },
        ],
      }),
    );
    exitCode = report.findings.isEmpty ? 0 : 1;
  } on Object catch (error) {
    stderr.writeln('Boundary check could not complete: $error');
    exitCode = 2;
  }
}
