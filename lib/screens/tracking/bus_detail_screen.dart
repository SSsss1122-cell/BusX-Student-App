import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/bus_stop.dart';
import '../../services/bus_service.dart';
import '../../theme/app_colors.dart';
import 'bus_info.dart';

class BusDetailScreen extends StatefulWidget {
  final BusInfo bus;

  const BusDetailScreen({super.key, required this.bus});

  @override
  State<BusDetailScreen> createState() => _BusDetailScreenState();
}

class _BusDetailScreenState extends State<BusDetailScreen>
    with SingleTickerProviderStateMixin {
  final _busService = BusService();
  late TabController _tab;

  List<BusStop> _morningStops = [];
  List<BusStop> _eveningStops = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadStops();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadStops() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final routeId = widget.bus.routeId;

      List<BusStop> allStops;

      if (routeId != null && routeId.isNotEmpty) {
        // Preferred: fetch by route_id
        final res = await Supabase.instance.client
            .from('bus_stops')
            .select()
            .eq('route_id', routeId)
            .order('sequence', ascending: true);

        allStops = (res as List)
            .map((e) => BusStop.fromMap(e as Map<String, dynamic>))
            .toList();
      } else {
        // Fallback: fetch by bus_id
        allStops = await _busService.getAllStops(widget.bus.id);
      }

      final morning = allStops
          .where((s) => s.direction.trim().toLowerCase() == 'morning')
          .toList();

      final evening = allStops
          .where((s) => s.direction.trim().toLowerCase() == 'evening')
          .toList();

      if (!mounted) return;
      setState(() {
        _morningStops = morning;
        _eveningStops = evening;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text('Bus ${widget.bus.busNumber}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Morning'),
            Tab(text: 'Evening'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildBusHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : TabBarView(
                        controller: _tab,
                        children: [
                          _stopsList(_morningStops, 'morning'),
                          _stopsList(_eveningStops, 'evening'),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // BUS HEADER
  // -----------------------------------------------------------------
  Widget _buildBusHeader() {
    final bus = widget.bus;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.directions_bus_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bus ${bus.busNumber}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (bus.routeName == null || bus.routeName!.isEmpty)
                      ? 'No route'
                      : bus.routeName!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (bus.isActive ? Colors.green : Colors.grey)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              bus.isActive ? 'ACTIVE' : 'INACTIVE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: bus.isActive
                    ? Colors.green.shade700
                    : Colors.grey.shade700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // ERROR
  // -----------------------------------------------------------------
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadStops,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // STOPS LIST
  // -----------------------------------------------------------------
  Widget _stopsList(List<BusStop> stops, String direction) {
    if (stops.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadStops,
        color: AppColors.primary,
        child: ListView(
          children: [
            const SizedBox(height: 100),
            Center(
              child: Column(
                children: [
                  Icon(
                    direction == 'morning'
                        ? Icons.wb_sunny_rounded
                        : Icons.nights_stay_rounded,
                    size: 44,
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No ${direction == 'morning' ? 'morning' : 'evening'} stops',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStops,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: stops.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (_, i) {
          final s = stops[i];
          return Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  '${s.sequence}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                s.stopName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: (s.landmark != null && s.landmark!.isNotEmpty)
                  ? Text(s.landmark!)
                  : null,
            ),
          );
        },
      ),
    );
  }
}