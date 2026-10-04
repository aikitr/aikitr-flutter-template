import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app/app.dart';
import 'app/app_config.dart';

Future<void> runTemplateApp(AppEnvironment environment) async {
  WidgetsFlutterBinding.ensureInitialized();
  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  final AppConfig config = AppConfig.forEnvironment(
    environment,
    bundleIdentifier: packageInfo.packageName,
  );
  if (kDebugMode) {
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((LogRecord record) {
      debugPrint('${record.level.name}: ${record.message}');
    });
  }
  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const TemplateApp(),
    ),
  );
}
