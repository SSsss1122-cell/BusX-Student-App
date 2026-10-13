import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/session_service.dart';
import '../../services/auth_service.dart';
import '../../services/bus_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
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
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _silentRefresh();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Same top padding as the other tab screens.
  double _topPad(BuildContext context) =>
      MediaQuery.of(context).padding.top + kToolbarHeight - 56;

  Future<void> _silentRefresh() async {
    try {
      final student = await SessionService.getStudent();
      if (student == null) return;
      final buses =
          await _busService.getInstitutionBuses(student.institutionId);
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
      final student = await SessionService.getStudent();
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
      child: Column(
        children: [
          // ---- Header (clears the floating top bar) ----
          Padding(
            padding: EdgeInsets.fromLTRB(16, _topPad(context), 16, 4),
            child: GlassCard(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              radius: 18,
              blur: 18,
              tint: Colors.white.withValues(alpha: 0.55),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: AppColors.textOnYellow,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Your Institution Buses',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh_rounded,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: _isLoadingBuses
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _busError != null
                    ? _buildErrorState()
                    : _buses.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                            itemCount: _buses.length,
                            itemBuilder: (context, index) =>
                                _buildBusCard(_buses[index]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusCard(BusInfo bus) {
    final bool isLive = bus.locationUpdatedAt != null &&
        DateTime.now().difference(bus.locationUpdatedAt!).inSeconds < 40;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GlassCard(
        padding: EdgeInsets.zero,
        radius: 22,
        blur: 22,
        tint: Colors.white.withValues(alpha: 0.7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----- Image + badges -----
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                  child: SizedBox(
                    height: 175,
                    width: double.infinity,
                    child: (bus.imageUrl != null && bus.imageUrl!.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: bus.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppColors.primarySoft,
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.primarySoft,
                              child: const Icon(Icons.directions_bus_rounded,
                                  size: 80, color: AppColors.primary),
                            ),
                          )
                        : Container(
                            color: AppColors.primarySoft,
                            child: const Icon(Icons.directions_bus_rounded,
                                size: 80, color: AppColors.primary),
                          ),
                  ),
                ),

                Positioned(
                  top: 12,
                  left: 12,
                  child: GlassCard(
                    padding: const EdgeInsets.all(10),
                    radius: 14,
                    blur: 12,
                    tint: Colors.white.withValues(alpha: 0.35),
                    shadows: const [],
                    child: const Icon(
                      Icons.directions_bus_filled_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),

                Positioned(top: 12, right: 12, child: _statusPill(isLive)),
              ],
            ),

            // ----- Number plate -----
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.confirmation_number_rounded,
                        color: AppColors.primary, size: 18),
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
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (bus.routeName == null || bus.routeName!.isEmpty)
                              ? 'Route not available'
                              : bus.routeName!,
                          style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ----- Status -----
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500),
                  ),
                  Row(
                    children: [
                      Icon(
                        isLive
                            ? Icons.check_circle_rounded
                            : Icons.pause_circle_filled_rounded,
                        size: 16,
                        color:
                            isLive ? AppColors.success : AppColors.accentDark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isLive ? 'Bus Active' : 'Bus Not Active',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color:
                              isLive ? AppColors.success : AppColors.accentDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ----- Track button -----
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isLive
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => BusDetailScreen(bus: bus)),
                          );
                        }
                      : null,
                  icon: Icon(
                    isLive
                        ? Icons.near_me_rounded
                        : Icons.location_off_rounded,
                    size: 20,
                  ),
                  label: Text(isLive ? 'Track Live' : 'Bus Not Active'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(bool isLive) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      radius: 30,
      blur: 10,
      tint: (isLive ? AppColors.live : Colors.grey.shade700)
          .withValues(alpha: 0.85),
      shadows: const [],
      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            isLive ? 'LIVE' : 'Offline',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
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
            const Icon(Icons.cloud_off_rounded,
                size: 60, color: AppColors.textSecondary),
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
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 40, 40, 120),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_bus_outlined,
                  size: 60, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'No buses available for your institution.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}