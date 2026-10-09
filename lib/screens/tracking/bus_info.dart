class BusInfo {
  final String id;
  final String busNumber;
  final String? routeName;
  final String? routeId;
  final String? driverName;
  final String? capacity;
  final String? fuelType;
  final bool isActive;

  final double? latitude;
  final double? longitude;
  final double? speed;
  final DateTime? locationUpdatedAt;
  final String? imageUrl;

  BusInfo({
    required this.id,
    required this.busNumber,
    this.routeName,
    this.routeId,
    this.driverName,
    this.capacity,
    this.fuelType,
    this.isActive = true,
    this.latitude,
    this.longitude,
    this.speed,
    this.locationUpdatedAt,
    this.imageUrl,
  });

  factory BusInfo.fromMap(
    Map<String, dynamic> map, {
    Map<String, dynamic>? location,
  }) {
    return BusInfo(
      id: map['id'] as String,
      busNumber: (map['bus_number'] as String?) ?? '—',
      routeName: map['route_name'] as String?,
      routeId: map['route_id'] as String?,
      driverName: null,
      capacity: map['capacity']?.toString(),
      fuelType: map['fuel_type'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      latitude: location != null
          ? (location['latitude'] as num?)?.toDouble()
          : null,
      longitude: location != null
          ? (location['longitude'] as num?)?.toDouble()
          : null,
      speed: location != null ? (location['speed'] as num?)?.toDouble() : null,
      locationUpdatedAt:
          location != null &&
              (location['received_at'] != null ||
                  location['device_time'] != null)
          ? DateTime.tryParse(
              (location['received_at'] ?? location['device_time']).toString(),
            )
          : null,
      imageUrl: map['image_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bus_number': busNumber,
      'route_name': routeName,
      'route_id': routeId,
      'driver_name': driverName,
      'capacity': capacity,
      'fuel_type': fuelType,
      'is_active': isActive,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'received_at': locationUpdatedAt?.toIso8601String(),
      'image_url': imageUrl,
    };
  }
}
