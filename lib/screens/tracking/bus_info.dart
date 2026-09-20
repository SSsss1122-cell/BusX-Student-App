
class BusInfo {
  final String id;
  final String busNumber;
  final String routeName;
  final String institutionId;
  final bool isActive;
  final String? driverId;
  final String? capacity;
  final String? fuelType;

  const BusInfo({
    required this.id,
    required this.busNumber,
    required this.routeName,
    required this.institutionId,
    required this.isActive,
    this.driverId,
    this.capacity,
    this.fuelType,
  });

  factory BusInfo.fromMap(Map<String, dynamic> map) {
    return BusInfo(
      id: map['id']?.toString() ?? '',
      busNumber: map['bus_number']?.toString() ?? '',
      routeName: map['route_name']?.toString() ?? '',
      institutionId: map['institution_id']?.toString() ?? '',
      isActive: map['is_active'] == true,
      driverId: map['driver_id']?.toString(),
      capacity: map['capacity']?.toString(),
      fuelType: map['fuel_type']?.toString(),
    );
  }
}
