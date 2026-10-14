import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'app_update_service.dart';
import '../models/app_version_info.dart';

class VersionChecker {
  static Future<(AppVersionInfo, bool)?> check() async {
    if (kIsWeb) {
      debugPrint('🔍 kIsWeb → skip');
      return null;
    }

    final platform =
        defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

    debugPrint('🔍 Platform = $platform');

    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      debugPrint('🔍 Not mobile → skip');
      return null;
    }

    final info = await AppUpdateService().fetchInfo(platform);
    debugPrint('🔍 DB info = $info');

    if (info == null) {
      debugPrint('🔍 DB returned null — no row');
      return null;
    }

    final pkg = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(pkg.buildNumber) ?? 0;

    debugPrint('🔍 Current build = $currentBuild');
    debugPrint('🔍 Latest build  = ${info.latestBuild}');
    debugPrint('🔍 Force update  = ${info.forceUpdate}');

    if (currentBuild >= info.latestBuild) {
      debugPrint('🔍 No update needed');
      return null;
    }

    debugPrint('🔍 ✅ Update available!');
    return (info, info.forceUpdate);
  }
}