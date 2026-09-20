
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/tracking/bus_info.dart';

class BusService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─────────────────────────────────────────────
  // Get all active buses belonging to an institution
  // ─────────────────────────────────────────────

  Future<List<BusInfo>> getInstitutionBuses(
    String institutionId,
  ) async {
    try {
      final response = await _supabase
          .from('buses')
          .select()
          .eq('institution_id', institutionId)
          .eq('is_active', true)
          .order('bus_number');

      return (response as List)
          .map(
            (item) => BusInfo.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Unable to load buses.');
    }
  }

  // ─────────────────────────────────────────────
  // Get latest location of a bus
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>?> getLatestBusLocation(
    String busId,
  ) async {
    try {
      final response = await _supabase
          .from('bus_locations')
          .select()
          .eq('bus_id', busId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Unable to load bus location.');
    }
  }

  // ─────────────────────────────────────────────
  // Get stops for a bus
  // ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getBusStops(
    String busId,
  ) async {
    try {
      final response = await _supabase
          .from('bus_stops')
          .select()
          .eq('bus_id', busId)
          .order('sequence');

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Unable to load bus stops.');
    }
  }
}

