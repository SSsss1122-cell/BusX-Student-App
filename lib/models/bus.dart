class Bus {
  final String id;
  final String busNumber;
  final String? routeName;
  final String institutionId;
  final bool isActive;
  final String? driverId;
  final String? capacity;
  final String? fuelType;

  Bus({
    required this.id,
    required this.busNumber,
    this.routeName,
    required this.institutionId,
    required this.isActive,
    this.driverId,
    this.capacity,
    this.fuelType,
  });

  factory Bus.fromMap(Map<String, dynamic> map) {
    return Bus(
      id: map['id']?.toString() ?? '',
      busNumber: map['bus_number']?.toString() ?? '',
      routeName: map['route_name']?.toString(),
      institutionId: map['institution_id']?.toString() ?? '',
      isActive: map['is_active'] == true,
      driverId: map['driver_id']?.toString(),
      capacity: map['capacity']?.toString(),
      fuelType: map['fuel_type']?.toString(),
    );
  }
}