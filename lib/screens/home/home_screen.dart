import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';


import '../../services/auth_service.dart';
import '../../services/bus_service.dart';
import '../../theme/app_colors.dart';
import '../tracking/bus_info.dart';
import '../tracking/bus_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BusService _busService = BusService();
  final AuthService _authService = AuthService();
  Timer? _refreshTimer;

  List<BusInfo> _buses = [];
  bool _isLoadingBuses = true;
  String? _busError;

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _silentRefresh();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _silentRefresh() async {
    try {
      final student = await _authService.getCurrentStudent();
      if (student == null) return;
      final buses = await _busService.getInstitutionBuses(student.institutionId);
      if (!mounted) return;
      setState(() => _buses = buses);
    } catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingBuses = true;
      _busError = null;
    });

    try {
      final student = await _authService.getCurrentStudent();
      if (student == null) throw Exception('Student not found');

      final buses =
          await _busService.getInstitutionBuses(student.institutionId);

      if (!mounted) return;
      setState(() {
        _buses = buses;
        _isLoadingBuses = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingBuses = false;
        _busError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: _isLoadingBuses
          ? const Center(child: CircularProgressIndicator())
          : _busError != null
              ? _buildErrorState()
              : _buses.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _buses.length,
                      itemBuilder: (context, index) =>
                          _buildBusCard(_buses[index]),
                    ),
    );
  }

  Widget _buildBusCard(BusInfo bus) {
  final bool isLive = bus.isLive;

  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // -- Image --
        Stack(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: (bus.imageUrl != null && bus.imageUrl!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: bus.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.directions_bus,
                              size: 80, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.directions_bus,
                            size: 80, color: Colors.grey),
                      ),
              ),
            ),
            if (!isLive)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.white70),
                      SizedBox(width: 6),
                      Text('Offline',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              )
            else
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.white),
                      SizedBox(width: 6),
                      Text('LIVE',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
          ],
        ),

        // -- Number Plate --
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD0DEFF)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.directions_bus,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bus.busNumber.isEmpty ? 'Bus Number' : bus.busNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bus.routeName.isEmpty
                            ? 'Route not available'
                            : bus.routeName,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // -- Status --
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Status:',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500)),
              Text(
                isLive ? 'Bus Active' : 'Bus Not Active',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isLive ? AppColors.success : AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        // -- Track Live button --
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isLive
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BusDetailScreen(bus: bus),
                        ),
                      );
                    }
                  : null,
              icon: Icon(
                  isLive ? Icons.location_on : Icons.location_off,
                  size: 20),
              label: Text(
                isLive ? 'Track Live' : 'Bus Not Active',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isLive ? AppColors.primary : Colors.grey.shade400,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade400,
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Error: $_busError', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_bus_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No buses available for your institution.'),
        ],
      ),
    );
  }
}
