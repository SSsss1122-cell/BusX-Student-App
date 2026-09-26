import 'dart:async';
import 'package:flutter/material.dart';

import '../../models/bus_stop.dart';
import '../../services/tracking_service.dart';
import '../../theme/app_colors.dart';
import 'bus_info.dart';
import 'geo_utils.dart';

class BusLiveTrackingScreen extends StatefulWidget {
  final BusInfo bus;
  final String? direction; // null → auto-detect

  const BusLiveTrackingScreen({
    super.key,
    required this.bus,
    this.direction,
  });

  @override
  State<BusLiveTrackingScreen> createState() => _BusLiveTrackingScreenState();
}

class _BusLiveTrackingScreenState extends State<BusLiveTrackingScreen> {
  final _service = TrackingService();

  StreamSubscription<BusInfo>? _busSub;
  late BusInfo _bus;
  List<BusStop> _stops = [];
  List<StopEta> _stopEtas = [];

  String _direction = 'morning';
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  /// Live status: bus location updated within last 60 seconds.
  bool _isLive = false;

  @override
  void initState() {
    super.initState();
    _bus = widget.bus;
    _direction =
        widget.direction ?? TrackingService.autoDirection(DateTime.now());
    _load();
  }

  @override
  void dispose() {
    _busSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final stops = await _service.getStops(
        widget.bus.id,
        direction: _direction,
      );

      if (!mounted) return;
      setState(() {
        _stops = stops;
        _loading = false;
      });
      _recompute();

      _busSub?.cancel();
      _busSub = _service.watchBus(widget.bus.id).listen((bus) {
        if (!mounted) return;
        setState(() => _bus = bus);
        _recompute();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _recompute() {
    // Live = last update within 60s
    final live = _bus.locationUpdatedAt != null &&
        DateTime.now().difference(_bus.locationUpdatedAt!).inSeconds < 60;

    final etas = TrackingService.computeStopEtas(
      stops: _stops,
      busLat: _bus.latitude,
      busLng: _bus.longitude,
      speedKmh: _bus.speed,
      busIsLive: live,
    );

    if (!mounted) return;

    setState(() {
      _isLive = live;
      _stopEtas = etas;
    });

    // Refresh the "live" flag every 10s even without new data
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) _recompute();
    });
  }

  Future<void> _manualRefresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);

    try {
      // Force re-fetch the bus + latest location from Supabase
      final fresh = await _service.getBusById(widget.bus.id);
      if (fresh != null && mounted) {
        setState(() => _bus = fresh);
        _recompute();
      }
    } catch (_) {
      // ignore
    }

    if (!mounted) return;
    setState(() => _refreshing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Location updated'),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : Column(
                    children: [
                      _buildTopBar(),
                      Expanded(
                        child: RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _manualRefresh,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeroCard(),
                                const SizedBox(height: 20),
                                _buildDirectionChips(),
                                const SizedBox(height: 22),
                                _buildTimelineLabel(),
                                const SizedBox(height: 14),
                                _buildTimeline(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  // ────────── TOP BAR ──────────
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Bus ${_bus.busNumber}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _bus.routeName ?? 'Live Tracking',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Live / Stale dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _isLive ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
              boxShadow: _isLive
                  ? [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),

          const SizedBox(width: 4),

          // Refresh button
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _refreshing ? null : _manualRefresh,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _refreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        size: 22,
                        color: AppColors.primary,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────── HERO CARD ──────────
  Widget _buildHeroCard() {
    StopEta? current;
    StopEta? next;
    for (final e in _stopEtas) {
      if (e.isCurrent) current = e;
      if (e.isNext) next = e;
    }

    final updatedAgo = _bus.locationUpdatedAt != null
        ? _timeAgo(_bus.locationUpdatedAt!)
        : '—';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isLive
              ? const [Color(0xFF2563EB), Color(0xFF1E40AF)]
              : const [Color(0xFF6B7280), Color(0xFF4B5563)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (_isLive ? const Color(0xFF2563EB) : Colors.grey)
                .withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bus ${_bus.busNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _bus.routeName ?? '—',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _livePill(),
            ],
          ),
          const SizedBox(height: 18),

          // Big number: ETA to next stop
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      next?.etaMinutes != null
                          ? '${next!.etaMinutes} min'
                          : (current?.isCurrent == true
                              ? 'Arrived'
                              : '-- min'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      next != null
                          ? 'To ${next.stop.stopName}'
                          : 'At final stop',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    next?.distanceMeters != null
                        ? GeoUtils.formatDistance(next!.distanceMeters!)
                        : '—',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Updated $updatedAgo',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Bottom chips row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _heroChip(
                Icons.speed_rounded,
                _bus.speed != null && _bus.speed! > 0
                    ? '${_bus.speed!.toStringAsFixed(0)} km/h'
                    : 'Parked',
              ),
              if (current != null)
                _heroChip(
                  Icons.location_on_rounded,
                  current.stop.stopName,
                ),
              _heroChip(
                _direction == 'morning'
                    ? Icons.wb_sunny_rounded
                    : Icons.nightlight_round,
                _direction == 'morning' ? 'Morning trip' : 'Evening trip',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _livePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _isLive ? Colors.greenAccent : Colors.white70,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _isLive ? 'LIVE' : 'STALE',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ────────── DIRECTION CHIPS ──────────
  Widget _buildDirectionChips() {
    return Row(
      children: [
        Expanded(
          child: _directionChip(
            label: 'Morning',
            sublabel: 'Home → College',
            icon: Icons.wb_sunny_rounded,
            selected: _direction == 'morning',
            onTap: () {
              if (_direction == 'morning') return;
              setState(() {
                _direction = 'morning';
                _loading = true;
              });
              _load();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _directionChip(
            label: 'Evening',
            sublabel: 'College → Home',
            icon: Icons.nightlight_round,
            selected: _direction == 'evening',
            onTap: () {
              if (_direction == 'evening') return;
              setState(() {
                _direction = 'evening';
                _loading = true;
              });
              _load();
            },
          ),
        ),
      ],
    );
  }

  Widget _directionChip({
    required String label,
    required String sublabel,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      sublabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: selected
                            ? Colors.white.withValues(alpha: 0.85)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────── TIMELINE LABEL ──────────
  Widget _buildTimelineLabel() {
    final passed = _stopEtas.where((e) => e.passed).length;
    final total = _stopEtas.length;
    return Row(
      children: [
        const Icon(
          Icons.directions_bus_filled_rounded,
          size: 18,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        const Text(
          'ROUTE TIMELINE',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: Color(0xFF374151),
          ),
        ),
        const Spacer(),
        Text(
          '$passed / $total completed',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ────────── TIMELINE ──────────
  Widget _buildTimeline() {
    if (_stopEtas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text('No stops available for this direction'),
        ),
      );
    }

    return Column(
      children: List.generate(_stopEtas.length, (i) {
        final e = _stopEtas[i];
        final isLast = i == _stopEtas.length - 1;
        final nextE = !isLast ? _stopEtas[i + 1] : null;
        return _buildStopRow(e, nextE, isLast);
      }),
    );
  }

  Widget _buildStopRow(StopEta e, StopEta? nextE, bool isLast) {
    final stop = e.stop;
    final lineColor = (e.passed || e.isCurrent)
        ? AppColors.primary
        : const Color(0xFFD1D5DB);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: e.isCurrent
                        ? AppColors.primary
                        : e.passed
                            ? AppColors.primary.withValues(alpha: 0.85)
                            : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: e.isNext
                          ? AppColors.primary
                          : (e.passed || e.isCurrent)
                              ? Colors.transparent
                              : const Color(0xFFD1D5DB),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: e.isCurrent
                        ? const Icon(
                            Icons.directions_bus_rounded,
                            color: Colors.white,
                            size: 17,
                          )
                        : e.passed
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 16,
                              )
                            : Text(
                                '${stop.sequence}',
                                style: TextStyle(
                                  color: e.isNext
                                      ? AppColors.primary
                                      : const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2.5,
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: e.isCurrent
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: e.isCurrent
                        ? AppColors.primary.withValues(alpha: 0.30)
                        : const Color(0xFFE5E7EB),
                    width: e.isCurrent ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            stop.stopName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: e.isCurrent
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: e.passed
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF111827),
                            ),
                          ),
                        ),
                        if (e.isCurrent) _badge('Current', AppColors.primary),
                        if (e.isNext) _badge('Next', const Color(0xFF6B7280)),
                        if (e.passed) _badge('Passed', const Color(0xFF9CA3AF)),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Detail rows: distance + ETA + scheduled time
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: [
                        if (e.distanceMeters != null)
                          _infoRow(
                            Icons.straighten_rounded,
                            GeoUtils.formatDistance(e.distanceMeters!),
                          ),
                        if (e.etaMinutes != null && !e.passed)
                          _infoRow(
                            Icons.schedule_rounded,
                            e.isCurrent
                                ? 'Arrived'
                                : '${e.etaMinutes} min',
                          ),
                        if (stop.estimatedTime != null)
                          _infoRow(
                            Icons.access_time_rounded,
                            'Scheduled ${stop.estimatedTime} min',
                          ),
                      ],
                    ),

                    // Distance from current stop to next stop
                    if (e.isCurrent && nextE != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.navigation_rounded,
                              size: 13,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '${GeoUtils.formatDistance(
                                  GeoUtils.distanceInMeters(
                                    _bus.latitude ?? stop.latitude,
                                    _bus.longitude ?? stop.longitude,
                                    nextE.stop.latitude,
                                    nextE.stop.longitude,
                                  ),
                                )} to ${nextE.stop.stopName}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (stop.landmark != null &&
                        stop.landmark!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              stop.landmark!,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF6B7280)),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B5563),
          ),
        ),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

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
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 10) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}