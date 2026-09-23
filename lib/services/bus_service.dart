
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/tracking/bus_info.dart';

class BusService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all buses for an institution, with their latest location attached.
  Future<List<BusInfo>> getInstitutionBuses(String institutionId) async {
    final busesResponse = await _supabase
        .from('buses')
        .select()
        .eq('institution_id', institutionId);

    final buses = List<Map<String, dynamic>>.from(busesResponse);
    final List<BusInfo> result = [];

    for (final bus in buses) {
      final busId = bus['id']?.toString();
      if (busId == null) continue;

      Map<String, dynamic>? latestLocation;
      try {
        final locResponse = await _supabase
            .from('bus_locations')
            .select()
            .eq('bus_id', busId)
            .order('updated_at', ascending: false)
            .limit(1)
            .maybeSingle();
        latestLocation = locResponse;
      } catch (_) {
        latestLocation = null;
      }

      result.add(BusInfo.fromMap(bus, location: latestLocation));
    }

    return result;
  }

  /// Fetch live location for a specific bus.
  Future<Map<String, dynamic>?> getLatestLocation(String busId) async {
    try {
      final res = await _supabase
          .from('bus_locations')
          .select()
          .eq('bus_id', busId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return res;
    } catch (_) {
      return null;
    }
  }

  /// Fetch ALL stops for a bus (both morning and evening).
  /// The caller decides which direction to display based on context.
  Future<List<Map<String, dynamic>>> getAllStops(String busId) async {
    try {
      final res = await _supabase
          .from('bus_stops')
          .select()
          .eq('bus_id', busId)
          .order('sequence', ascending: true);

      final list = List<Map<String, dynamic>>.from(res);
      // Filter out rows that don't belong to this bus
      list.removeWhere((s) => s['bus_id'] == null);
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Fetch stops for a specific direction ('morning' or 'evening'),
  /// strictly ordered by sequence.
  Future<List<Map<String, dynamic>>> getBusStops(
    String busId, {
    String? direction,
  }) async {
    try {
      var query = _supabase
          .from('bus_stops')
          .select()
          .eq('bus_id', busId);

      if (direction != null && direction.isNotEmpty) {
        query = query.eq('direction', direction);
      }

      final res = await query.order('sequence', ascending: true);

      final list = List<Map<String, dynamic>>.from(res)
          .where((s) => s['bus_id'] != null)
          .toList();

      // Defensive client-side sort
      list.sort((a, b) {
        final sa = (a['sequence'] as num?)?.toInt() ?? 999999;
        final sb = (b['sequence'] as num?)?.toInt() ?? 999999;
        return sa.compareTo(sb);
      });

      return list;
    } catch (_) {
      return [];
    }
  }

  Future<BusInfo?> getStudentBus(String studentId) async {
    return null;
  }
}
