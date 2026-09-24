import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bus_stop.dart';
import '../screens/tracking/bus_info.dart';

class BusService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // BUSES
  // ============================================================

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
        latestLocation = await _supabase
            .from('bus_locations')
            .select()
            .eq('bus_id', busId)
            .order('updated_at', ascending: false)
            .limit(1)
            .maybeSingle();
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
      return await _supabase
          .from('bus_locations')
          .select()
          .eq('bus_id', busId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // STOPS
  // ============================================================

  /// Fetch ALL stops for a bus (both morning and evening).
  Future<List<BusStop>> getAllStops(String busId) async {
    try {
      final res = await _supabase
          .from('bus_stops')
          .select()
          .eq('bus_id', busId)
          .order('sequence', ascending: true);

      return (res as List)
          .map((e) => BusStop.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetch stops for a bus filtered by direction ('morning' or 'evening').
  Future<List<BusStop>> getBusStops(
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

      return (res as List)
          .map((e) => BusStop.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // STUDENT BUS (stub)
  // ============================================================

  Future<BusInfo?> getStudentBus(String studentId) async {
    return null;
  }
}