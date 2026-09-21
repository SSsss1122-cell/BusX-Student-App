class BusInfo {
  final String id;
  final String busNumber;
  final String routeName;
  final String institutionId;
  final bool isActive;
  final bool isLive;             // ?? NEW: true only if bus sent GPS ping recently
  final String? imageUrl;
  final String? driverId;
  final String? capacity;
  final String? fuelType;

  // Latest live location (if any)
  final double? latitude;
  final double? longitude;
  final double? speed;
  final DateTime? locationUpdatedAt;
  final String? driverName;
  final String? driverContact;

  const BusInfo({
    required this.id,
    required this.busNumber,
    required this.routeName,
    required this.institutionId,
    required this.isActive,
    required this.isLive,
    this.imageUrl,
    this.driverId,
    this.capacity,
    this.fuelType,
    this.latitude,
    this.longitude,
    this.speed,
    this.locationUpdatedAt,
    this.driverName,
    this.driverContact,
  });

  factory BusInfo.fromMap(
    Map<String, dynamic> map, {
    Map<String, dynamic>? location,
  }) {
    DateTime? updatedAt;
    if (location != null && location['updated_at'] != null) {
      updatedAt = DateTime.tryParse(location['updated_at'].toString());
    }

    // Consider live only if a GPS ping arrived in the last 5 minutes
    final isLive = updatedAt != null &&
        DateTime.now().difference(updatedAt).inSeconds < 120;

    return BusInfo(
      id: map['id']?.toString() ?? '',
      busNumber: map['bus_number']?.toString() ?? '',
      routeName: map['route_name']?.toString() ?? '',
      institutionId: map['institution_id']?.toString() ?? '',
      isActive: map['is_active'] == true,
      isLive: isLive,
      imageUrl: map['image_url']?.toString(),
      driverId: map['driver_id']?.toString(),
      capacity: map['capacity']?.toString(),
      fuelType: map['fuel_type']?.toString(),
      latitude: (location?['latitude'] as num?)?.toDouble(),
      longitude: (location?['longitude'] as num?)?.toDouble(),
      speed: (location?['speed'] as num?)?.toDouble(),
      locationUpdatedAt: updatedAt,
      driverName: location?['driver_name']?.toString(),
      driverContact: location?['driver_contact']?.toString(),
    );
  }
}
