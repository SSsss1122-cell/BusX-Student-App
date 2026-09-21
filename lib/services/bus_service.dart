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

      // Get latest location for this bus
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

  /// Fetch live location for a specific bus (used by tracking screen).
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

  /// Fetch the route stops for a bus, in order.
  Future<List<Map<String, dynamic>>> getBusStops(String busId) async {
    try {
      final res = await _supabase
          .from('bus_stops')
          .select()
          .eq('bus_id', busId)
          .order('sequence', ascending: true);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  /// Fetch the student's own bus (based on students_new.routes if applicable).
  /// For now, returns null — extend later.
  Future<BusInfo?> getStudentBus(String studentId) async {
    return null;
  }
}
