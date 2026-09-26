class BusStop {
  final int id;
  final String stopName;
  final int sequence;
  final String direction;
  final String? busId;
  final String? routeId;
  final String? landmark;
  final int? estimatedTime;

  // ✅ NEW: needed by the map
  final double latitude;
  final double longitude;
  final bool isMajor;

  BusStop({
    required this.id,
    required this.stopName,
    required this.sequence,
    required this.direction,
    required this.latitude,
    required this.longitude,
    this.busId,
    this.routeId,
    this.landmark,
    this.estimatedTime,
    this.isMajor = false,
  });

  factory BusStop.fromMap(Map<String, dynamic> map) {
    return BusStop(
      id: (map['id'] as num).toInt(),
      stopName: map['stop_name'] as String? ?? '',
      sequence: (map['sequence'] as num?)?.toInt() ?? 0,
      direction: map['direction'] as String? ?? 'morning',
      busId: map['bus_id'] as String?,
      routeId: map['route_id'] as String?,
      landmark: map['landmark'] as String?,
      estimatedTime: (map['estimated_time'] as num?)?.toInt(),

      // ✅ safe parsing — Supabase returns them as double
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      isMajor: map['is_major'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stop_name': stopName,
      'sequence': sequence,
      'direction': direction,
      'bus_id': busId,
      'route_id': routeId,
      'landmark': landmark,
      'estimated_time': estimatedTime,
      'latitude': latitude,
      'longitude': longitude,
      'is_major': isMajor,
    };
  }
}