class BusStop {
  final int id;
  final String stopName;
  final int sequence;
  final String direction;
  final String? busId;
  final String? routeId;
  final String? landmark;
  final int? estimatedTime;
  final double? latitude;
  final double? longitude;

  BusStop({
    required this.id,
    required this.stopName,
    required this.sequence,
    required this.direction,
    this.busId,
    this.routeId,
    this.landmark,
    this.estimatedTime,
    this.latitude,
    this.longitude,
  });

  factory BusStop.fromMap(Map<String, dynamic> map) {
    return BusStop(
      id: (map['id'] as num?)?.toInt() ?? 0,
      stopName: map['stop_name'] as String? ?? '',
      sequence: (map['sequence'] as num?)?.toInt() ?? 0,
      direction: map['direction'] as String? ?? 'morning',
      busId: map['bus_id'] as String?,
      routeId: map['route_id'] as String?,
      landmark: map['landmark'] as String?,
      estimatedTime: (map['estimated_time'] as num?)?.toInt(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}
