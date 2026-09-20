
import 'package:flutter/material.dart';

import '../../models/student.dart';
import '../../services/bus_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import 'bus_detail_screen.dart';
import 'bus_info.dart';

class TrackingScreen extends StatefulWidget {
  final Student student;

  const TrackingScreen({
    super.key,
    required this.student,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final BusService _busService = BusService();

  List<BusInfo> _buses = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBuses();
  }

  Future<void> _loadBuses() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final buses = await _busService.getInstitutionBuses(
        widget.student.institutionId,
      );

      if (!mounted) return;

      setState(() {
        _buses = buses;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadBuses,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.pagePadding,
                  20,
                  AppDimensions.pagePadding,
                  30,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildTitle(),
                    const SizedBox(height: 20),
                    _buildContent(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primaryLight,
                ],
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BusX',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Live Bus Tracking',
                  style: AppTextStyles.small,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.student.branch ?? 'Student',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Institution Buses',
          style: AppTextStyles.heading,
        ),
        const SizedBox(height: 5),
        Text(
          'Live buses available for your institution',
          style: AppTextStyles.subtitle,
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return _buildLoading();
    }

    if (_error != null) {
      return _buildError();
    }

    if (_buses.isEmpty) {
      return _buildEmpty();
    }

    return Column(
      children: _buses
          .map(
            (bus) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildBusCard(bus),
            ),
          )
          .toList(),
    );
  }

  Widget _buildLoading() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          CircularProgressIndicator(
            strokeWidth: 2.5,
          ),
          SizedBox(height: 14),
          Text(
            'Loading buses...',
            style: AppTextStyles.subtitle,
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(
          AppDimensions.cardRadius,
        ),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: AppColors.error,
            size: 34,
          ),
          const SizedBox(height: 10),
          const Text(
            'Unable to load buses',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: AppTextStyles.small,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _loadBuses,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          Icon(
            Icons.directions_bus_outlined,
            color: AppColors.primary,
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            'No buses available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'No active buses are currently registered for your institution.',
            textAlign: TextAlign.center,
            style: AppTextStyles.small,
          ),
        ],
      ),
    );
  }

  Widget _buildBusCard(BusInfo bus) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(
        AppDimensions.cardRadius,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          AppDimensions.cardRadius,
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BusDetailScreen(
                bus: bus,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryLight,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: Colors.white,
                  size: 29,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            bus.busNumber.isEmpty
                                ? 'Bus'
                                : bus.busNumber,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _statusBadge(bus.isActive),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Text(
                      bus.routeName.isEmpty
                          ? 'Route not available'
                          : bus.routeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle,
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Icon(
                          bus.isActive
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          size: 14,
                          color: bus.isActive
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          bus.isActive
                              ? 'Bus available'
                              : 'Bus inactive',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: bus.isActive
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: active
            ? AppColors.success.withValues(alpha: 0.10)
            : AppColors.textSecondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'ACTIVE' : 'OFFLINE',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: active
              ? AppColors.success
              : AppColors.textSecondary,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(
        AppDimensions.cardRadius,
      ),
      border: Border.all(
        color: AppColors.border,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.035),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

