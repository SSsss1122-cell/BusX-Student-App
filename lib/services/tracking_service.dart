import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bus_stop.dart';
import '../screens/tracking/bus_info.dart';
import '../screens/tracking/geo_utils.dart';

class TrackingService {
  final SupabaseClient _sb = Supabase.instance.client;

  Stream<BusInfo> watchBus(String busId) {
    final controller = StreamController<BusInfo>();

    _fetchBusWithLocation(busId).then((b) {
      if (b != null) controller.add(b);
    });

    final channel = _sb
        .channel('bus_loc_$busId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bus_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'bus_id',
            value: busId,
          ),
          callback: (_) async {
            final fresh = await _fetchBusWithLocation(busId);
            if (fresh != null) controller.add(fresh);
          },
        )
        .subscribe();

    controller.onCancel = () {
      _sb.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }

  Future<BusInfo?> _fetchBusWithLocation(String busId) async {
    final bus =
        await _sb.from('buses').select().eq('id', busId).maybeSingle();
    if (bus == null) return null;

    final loc = await _sb
        .from('bus_locations')
        .select()
        .eq('bus_id', busId)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return BusInfo.fromMap(bus, location: loc);
  }

  /// Force-refresh a bus + its latest location.
  Future<BusInfo?> getBusById(String busId) async {
    return _fetchBusWithLocation(busId);
  }

  Future<List<BusStop>> getStops(String busId, {String? direction}) async {
    var q = _sb.from('bus_stops').select().eq('bus_id', busId);
    if (direction != null && direction.isNotEmpty) {
      q = q.eq('direction', direction);
    }
    final res = await q.order('sequence', ascending: true);
    return (res as List)
        .map((e) => BusStop.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  static String autoDirection(DateTime now) {
    final h = now.hour;
    if (h >= 5 && h < 13) return 'morning';
    return 'evening';
  }

  static List<StopEta> computeStopEtas({
    required List<BusStop> stops,
    required double? busLat,
    required double? busLng,
    required double? speedKmh,
    required bool busIsLive,
  }) {
    if (stops.isEmpty) return [];

    if (busLat == null || busLng == null) {
      return stops
          .map((s) => StopEta(
                stop: s,
                distanceMeters: null,
                etaMinutes: s.estimatedTime,
                passed: false,
                isNext: false,
                isCurrent: false,
              ))
          .toList();
    }

    final distances = stops
        .map((s) =>
            GeoUtils.distanceInMeters(busLat, busLng, s.latitude, s.longitude))
        .toList();

    int currentIdx = 0;
    double minD = double.infinity;
    for (var i = 0; i < distances.length; i++) {
      if (distances[i] < minD) {
        minD = distances[i];
        currentIdx = i;
      }
    }

    final effectiveSpeed =
        (speedKmh != null && speedKmh > 3) ? speedKmh : 25.0;

    final list = <StopEta>[];
    for (var i = 0; i < stops.length; i++) {
      final s = stops[i];
      final d = distances[i];

      int? eta;
      if (i == currentIdx) {
        eta = 0;
      } else if (i > currentIdx) {
        eta = (d / (effectiveSpeed * 1000 / 60)).round();
      } else {
        eta = null;
      }

      if (!busIsLive && s.estimatedTime != null && i >= currentIdx) {
        eta = s.estimatedTime;
      }

      list.add(StopEta(
        stop: s,
        distanceMeters: d,
        etaMinutes: eta,
        passed: i < currentIdx,
        isNext: i == currentIdx + 1,
        isCurrent: i == currentIdx,
      ));
    }
    return list;
  }
}

class StopEta {
  final BusStop stop;
  final double? distanceMeters;
  final int? etaMinutes;
  final bool passed;
  final bool isNext;
  final bool isCurrent;

  StopEta({
    required this.stop,
    required this.distanceMeters,
    required this.etaMinutes,
    required this.passed,
    required this.isNext,
    required this.isCurrent,
  });
}