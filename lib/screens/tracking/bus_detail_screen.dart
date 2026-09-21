
import 'dart:async';
import 'package:flutter/material.dart';

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

class _BusDetailScreenState extends State<BusDetailScreen> {
  final BusService _busService = BusService();
  Timer? _timer;

  double? _lat;
  double? _lng;
  DateTime? _updatedAt;
  double? _speed;

  List<Map<String, dynamic>> _stops = [];
  int _currentStopIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _lat = widget.bus.latitude;
    _lng = widget.bus.longitude;
    _updatedAt = widget.bus.locationUpdatedAt;
    _speed = widget.bus.speed;

    _loadStops();
    _refreshLocation();

    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refreshLocation();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Signal staleness
  // ─────────────────────────────────────────────
  bool get _isSignalStale {
    if (_updatedAt == null) return true;
    return DateTime.now().difference(_updatedAt!).inSeconds > 120;
  }

  // ─────────────────────────────────────────────
  // Data loading
  // ─────────────────────────────────────────────
  Future<void> _loadStops() async {
    final stops = await _busService.getBusStops(widget.bus.id);
    if (!mounted) return;
    setState(() {
      _stops = stops;
      _loading = false;
      _recomputeCurrentStop();
    });
  }

  Future<void> _refreshLocation() async {
    final loc = await _busService.getLatestLocation(widget.bus.id);
    if (!mounted) return;
    if (loc != null) {
      setState(() {
        _lat = (loc['latitude'] as num?)?.toDouble();
        _lng = (loc['longitude'] as num?)?.toDouble();
        _speed = (loc['speed'] as num?)?.toDouble();
        _updatedAt = DateTime.tryParse(loc['updated_at']?.toString() ?? '');
        _recomputeCurrentStop();
      });
    }
  }

  /// Find which stop is closest to the driver's current location.
  /// Only considers stops that haven't been passed yet.
  void _recomputeCurrentStop() {
    if (_stops.isEmpty || _lat == null || _lng == null) return;

    double bestDist = double.infinity;
    int bestIndex = _currentStopIndex;

    // Only search from current index onward so we don't un-pass stops
    for (int i = _currentStopIndex; i < _stops.length; i++) {
      final stopLat = (_stops[i]['latitude'] as num?)?.toDouble();
      final stopLng = (_stops[i]['longitude'] as num?)?.toDouble();
      if (stopLat == null || stopLng == null) continue;

      final d = GeoUtils.distanceInMeters(_lat!, _lng!, stopLat, stopLng);
      if (d < bestDist) {
        bestDist = d;
        bestIndex = i;
      }
    }

    // Advance to the next stop only if we're within 100m of it
    if (bestIndex == _currentStopIndex && bestDist < 100) {
      _currentStopIndex = (bestIndex + 1).clamp(0, _stops.length - 1);
    } else {
      _currentStopIndex = bestIndex;
    }
  }

  // ─────────────────────────────────────────────
  // Formatting helpers
  // ─────────────────────────────────────────────
  String _formatUpdated() {
    if (_updatedAt == null) return '—';
    final diff = DateTime.now().difference(_updatedAt!);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    return '${diff.inHours} hr ago';
  }

  double? _distanceToStop(Map<String, dynamic> stop) {
    if (_lat == null || _lng == null) return null;
    final stopLat = (stop['latitude'] as num?)?.toDouble();
    final stopLng = (stop['longitude'] as num?)?.toDouble();
    if (stopLat == null || stopLng == null) return null;
    return GeoUtils.distanceInMeters(_lat!, _lng!, stopLat, stopLng);
  }

  int? _etaToStop(Map<String, dynamic> stop) {
    final meters = _distanceToStop(stop);
    if (meters == null) return null;
    final speedKmh = (_speed != null && _speed! > 5) ? _speed! : 25.0;
    final minutes = (meters / 1000) / speedKmh * 60;
    return minutes.ceil();
  }

  /// Total remaining distance to the last stop.
  double? get _totalRemainingDistance {
    if (_stops.isEmpty || _lat == null || _lng == null) return null;
    // Sum the straight-line segments from driver → current → next → ... → last
    double total = 0;
    double prevLat = _lat!;
    double prevLng = _lng!;

    for (int i = _currentStopIndex; i < _stops.length; i++) {
      final stopLat = (_stops[i]['latitude'] as num?)?.toDouble();
      final stopLng = (_stops[i]['longitude'] as num?)?.toDouble();
      if (stopLat == null || stopLng == null) continue;
      total += GeoUtils.distanceInMeters(prevLat, prevLng, stopLat, stopLng);
      prevLat = stopLat;
      prevLng = stopLng;
    }

    return total == 0 ? null : total;
  }

  int? get _totalEtaMinutes {
    final meters = _totalRemainingDistance;
    if (meters == null) return null;
    final speedKmh = (_speed != null && _speed! > 5) ? _speed! : 25.0;
    final minutes = (meters / 1000) / speedKmh * 60;
    return minutes.ceil();
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bus ${widget.bus.busNumber}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              widget.bus.routeName,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _isSignalStale ? Colors.orange : Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshLocation,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildLiveBanner(),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ROUTE TIMELINE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        '${_stops.length} stops',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_stops.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No route stops configured for this bus.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ..._stops.asMap().entries.map((entry) {
                      final index = entry.key;
                      final stop = entry.value;
                      final isLast = index == _stops.length - 1;
                      return _buildStopTile(stop, index, isLast);
                    }),
                ],
              ),
            ),
    );
  }

  Widget _buildLiveBanner() {
    final stale = _isSignalStale;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: stale
              ? [Colors.grey.shade700, Colors.grey.shade500]
              : [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_bus, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bus ${widget.bus.busNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          const SizedBox(height: 4),
          Text(
            widget.bus.routeName,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
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
                              : '—'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Updated ${_formatUpdated()}',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  if (!stale &&
                      _totalRemainingDistance != null &&
                      _totalEtaMinutes != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${GeoUtils.formatDistance(_totalRemainingDistance!)} • $_totalEtaMinutes min to end',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStopTile(Map<String, dynamic> stop, int index, bool isLast) {
    final stopName = stop['stop_name']?.toString() ?? 'Stop ${index + 1}';

    final isCurrent = index == _currentStopIndex;
    final isPassed = index < _currentStopIndex;
    final isUpcoming = index > _currentStopIndex;

    final distance = _distanceToStop(stop);
    final eta = isUpcoming ? _etaToStop(stop) : null;

    Color circleColor;
    Color circleBorder;
    Color? iconColor;
    String statusLabel;
    Color statusBg;
    Color statusText;

    if (isCurrent) {
      circleColor = AppColors.primary;
      circleBorder = AppColors.primary;
      statusLabel = 'Current';
      statusBg = AppColors.primary.withValues(alpha: 0.1);
      statusText = AppColors.primary;
    } else if (isPassed) {
      circleColor = Colors.green;
      circleBorder = Colors.green;
      iconColor = Colors.white;
      statusLabel = 'Passed';
      statusBg = Colors.green.withValues(alpha: 0.1);
      statusText = Colors.green;
    } else {
      circleColor = Colors.white;
      circleBorder = Colors.grey.shade300;
      statusLabel = 'Next';
      statusBg = Colors.grey.shade100;
      statusText = Colors.grey.shade700;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: circleBorder, width: 2),
                ),
                child: Center(
                  child: isCurrent
                      ? const Icon(Icons.directions_bus,
                          color: Colors.white, size: 18)
                      : isPassed
                          ? Icon(Icons.check, color: iconColor, size: 18)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color:
                        isPassed ? Colors.green : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stopName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isPassed ? Colors.grey : Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusText,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (isCurrent && distance != null)
                    Text(
                      'You are here • ${GeoUtils.formatDistance(distance)} to this stop',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else if (isUpcoming && distance != null)
                    Row(
                      children: [
                        Icon(Icons.route,
                            size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${GeoUtils.formatDistance(distance)} away',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (eta != null) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.schedule,
                              size: 12, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'ETA $eta min',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    )
                  else if (isPassed)
                    Text(
                      'Visited',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
