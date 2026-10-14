import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_version_info.dart';

class AppUpdateService {
  Future<AppVersionInfo?> fetchInfo(String platform) async {
    try {
      debugPrint('🔍 Querying app_versions for platform=$platform');

      final row = await Supabase.instance.client
          .from('app_versions')
          .select()
          .eq('platform', platform)
          .maybeSingle();

      debugPrint('🔍 Row from DB = $row');

      if (row == null) return null;
      return AppVersionInfo.fromMap(row);
    } catch (e, st) {
      debugPrint('🔍 DB error: $e');
      debugPrint('🔍 Stack: $st');
      return null;
    }
  }
}