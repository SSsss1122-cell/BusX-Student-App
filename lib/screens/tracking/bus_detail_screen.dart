import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/bus_stop.dart';
import '../../services/bus_service.dart';
import '../../theme/app_colors.dart';
import 'bus_info.dart';
import 'geo_utils.dart';

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

  // ---- LIVE TRACKING STATE ----
  Timer? _pollTimer;
  Timer? _uiTicker;
  double? _lat;
  double? _lng;
  double? _speed;
  DateTime? _updatedAt;
  int _morningCurrentIndex = 0;
  int _eveningCurrentIndex = 0;

  // ---- SIGNAL STALENESS (40s) ----
  bool get _isSignalStale {
    if (_updatedAt == null) return true;
    return DateTime.now().difference(_updatedAt!).inSeconds > 40;
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);

    // Seed with whatever we already have from the bus list screen
    _lat = widget.bus.latitude;
    _lng = widget.bus.longitude;
    _speed = widget.bus.speed;
    _updatedAt = widget.bus.locationUpdatedAt;

    _loadStops();
    _refreshLocation();

    // Poll live location every 10 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refreshLocation();
    });

    // 1-second UI tick so the SIGNAL LOST banner flips at the 40s mark
    _uiTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _uiTicker?.cancel();
    _tab.dispose();
    super.dispose();
  }

  // ---------------------------------------------
  // DATA LOADING
  // ---------------------------------------------
  Future<void> _loadStops() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final routeId = widget.bus.routeId;

      List<BusStop> allStops;

      if (routeId != null && routeId.isNotEmpty) {
        final res = await Supabase.instance.client
            .from('bus_stops')
            .select()
            .eq('route_id', routeId)
            .order('sequence', ascending: true);

        allStops = (res as List)
            .map((e) => BusStop.fromMap(e as Map<String, dynamic>))
            .toList();
      } else {
        allStops = await _busService.getAllStops(widget.bus.id);
      }

      final morning =
          allStops
              .where((s) => s.direction.trim().toLowerCase() == 'morning')
              .toList()
            ..sort((a, b) => a.sequence.compareTo(b.sequence));

      final evening =
          allStops
              .where((s) => s.direction.trim().toLowerCase() == 'evening')
              .toList()
            ..sort((a, b) => a.sequence.compareTo(b.sequence));

      if (!mounted) return;
      setState(() {
        _morningStops = morning;
        _eveningStops = evening;
        _loading = false;
      });
      _recomputeCurrentStops();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _refreshLocation() async {
    final loc = await _busService.getLatestLocation(widget.bus.id);
    if (!mounted || loc == null) return;
    setState(() {
      _lat = (loc['latitude'] as num?)?.toDouble();
      _lng = (loc['longitude'] as num?)?.toDouble();
      _speed = (loc['speed'] as num?)?.toDouble();
      _updatedAt = DateTime.tryParse(
        (loc['received_at'] ?? loc['device_time'])?.toString() ?? '',
      );
    });
    _recomputeCurrentStops();
  }

  void _recomputeCurrentStops() {
    if (_lat == null || _lng == null) return;

    _morningCurrentIndex = _findClosestStopIndex(
      _morningStops,
      _morningCurrentIndex,
    );
    _eveningCurrentIndex = _findClosestStopIndex(
      _eveningStops,
      _eveningCurrentIndex,
    );
  }

  int _findClosestStopIndex(List<BusStop> stops, int startIndex) {
    if (stops.isEmpty) return 0;

    double bestDist = double.infinity;
    int bestIndex = startIndex;

    for (int i = startIndex; i < stops.length; i++) {
      final s = stops[i];
      if (s.latitude == null || s.longitude == null) continue;

      final d = GeoUtils.distanceInMeters(
        _lat!,
        _lng!,
        s.latitude!,
        s.longitude!,
      );
      if (d < bestDist) {
        bestDist = d;
        bestIndex = i;
      }
    }

    // Auto-advance if very close to current stop
    if (bestIndex == startIndex && bestDist < 100) {
      return (bestIndex + 1).clamp(0, stops.length - 1);
    }
    return bestIndex;
  }

  // ---------------------------------------------
  // DISTANCE / ETA HELPERS
  // ---------------------------------------------
  double? _distanceToStop(BusStop s) {
    if (_lat == null || _lng == null) return null;
    if (s.latitude == null || s.longitude == null) return null;
    return GeoUtils.distanceInMeters(_lat!, _lng!, s.latitude!, s.longitude!);
  }

  int? _etaToStop(BusStop s) {
    final meters = _distanceToStop(s);
    if (meters == null) return null;
    final speedKmh = (_speed != null && _speed! > 5) ? _speed! : 25.0;
    final minutes = (meters / 1000) / speedKmh * 60;
    return minutes.ceil();
  }

  String _formatUpdated() {
    if (_updatedAt == null) return '—';
    final diff = DateTime.now().difference(_updatedAt!);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    return '${diff.inHours} hr ago';
  }

  // ---------------------------------------------
  // BUILD
  // ---------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text('Bus ${widget.bus.busNumber}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await _refreshLocation();
              await _loadStops();
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Updated'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 20, bottom: 20),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _isSignalStale ? Colors.orange : Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
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
          _buildLiveBanner(),
          _buildBusHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _buildError()
                : TabBarView(
                    controller: _tab,
                    children: [
                      _stopsList(
                        _morningStops,
                        'morning',
                        _morningCurrentIndex,
                      ),
                      _stopsList(
                        _eveningStops,
                        'evening',
                        _eveningCurrentIndex,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------
  // LIVE BANNER
  // ---------------------------------------------
  Widget _buildLiveBanner() {
    final stale = _isSignalStale;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: stale
              ? [Colors.grey.shade700, Colors.grey.shade500]
              : [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.my_location_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stale ? 'Driver Offline' : 'Live Tracking',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: stale ? Colors.orange : Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      stale ? 'SIGNAL LOST' : 'LIVE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stale
                          ? 'Last known location'
                          : (_lat != null && _lng != null
                                ? '${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}'
                                : 'Waiting for GPS…'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stale
                          ? 'Driver stopped sharing location'
                          : (_speed != null
                                ? 'Speed: ${_speed!.toStringAsFixed(1)} km/h'
                                : 'Speed: —'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Updated ${_formatUpdated()}',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------
  // BUS HEADER
  // ---------------------------------------------
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
            child: const Icon(
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
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (bus.isActive ? Colors.green : Colors.grey).withValues(
                alpha: 0.15,
              ),
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

  // ---------------------------------------------
  // ERROR
  // ---------------------------------------------
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Colors.red.shade400,
            ),
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

  // ---------------------------------------------
  // STOPS LIST (with live tracking decorations)
  // ---------------------------------------------
  Widget _stopsList(List<BusStop> stops, String direction, int currentIndex) {
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
          final isCurrent = i == currentIndex;
          final isPassed = i < currentIndex;
          final isUpcoming = i > currentIndex;

          final distance = _distanceToStop(s);
          final eta = isUpcoming ? _etaToStop(s) : null;

          // Decide colors
          Color leadingColor;
          Color leadingTextColor;
          Widget? leadingChild;

          if (isCurrent) {
            leadingColor = AppColors.primary;
            leadingTextColor = Colors.white;
            leadingChild = const Icon(
              Icons.directions_bus_rounded,
              color: Colors.white,
              size: 20,
            );
          } else if (isPassed) {
            leadingColor = Colors.green;
            leadingTextColor = Colors.white;
            leadingChild = const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 20,
            );
          } else {
            leadingColor = AppColors.primary.withValues(alpha: 0.12);
            leadingTextColor = AppColors.primary;
            leadingChild = null;
          }

          // Status badge
          String badgeLabel;
          Color badgeBg;
          Color badgeTextColor;

          if (isCurrent) {
            badgeLabel = 'Current';
            badgeBg = AppColors.primary.withValues(alpha: 0.12);
            badgeTextColor = AppColors.primary;
          } else if (isPassed) {
            badgeLabel = 'Passed';
            badgeBg = Colors.green.withValues(alpha: 0.12);
            badgeTextColor = Colors.green.shade700;
          } else {
            badgeLabel = 'Next';
            badgeBg = Colors.grey.shade200;
            badgeTextColor = Colors.grey.shade700;
          }

          return Card(
            elevation: 0,
            color: isCurrent ? const Color(0xFFF0F4FF) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isCurrent
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : Colors.grey.shade200,
                width: isCurrent ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: leadingColor,
                    child:
                        leadingChild ??
                        Text(
                          '${s.sequence}',
                          style: TextStyle(
                            color: leadingTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.stopName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isPassed
                                      ? Colors.grey.shade500
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                badgeLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: badgeTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (s.landmark != null && s.landmark!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            s.landmark!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        if (isCurrent && distance != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'You are here • ${GeoUtils.formatDistance(distance)} to this stop',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ] else if (isUpcoming && distance != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.route,
                                size: 12,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${GeoUtils.formatDistance(distance)} away',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              if (eta != null) ...[
                                const SizedBox(width: 10),
                                Icon(
                                  Icons.schedule,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'ETA $eta min',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ] else if (isPassed) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Visited',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
