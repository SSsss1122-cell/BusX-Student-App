class BusStop {
  final int id;
  final String stopName;
  final int sequence;
  final String direction;
  final String? busId;
  final String? landmark;
  final int? estimatedTime;

  BusStop({
    required this.id,
    required this.stopName,
    required this.sequence,
    required this.direction,
    this.busId,
    this.landmark,
    this.estimatedTime,
  });

  factory BusStop.fromMap(Map<String, dynamic> map) {
    return BusStop(
      id: (map['id'] as num).toInt(),
      stopName: map['stop_name'] as String? ?? '',
      sequence: (map['sequence'] as num?)?.toInt() ?? 0,
      direction: map['direction'] as String? ?? 'morning',
      busId: map['bus_id'] as String?,
      landmark: map['landmark'] as String?,
      estimatedTime: (map['estimated_time'] as num?)?.toInt(),
    );
  }
}