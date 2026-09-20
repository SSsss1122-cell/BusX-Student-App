
import 'package:flutter/material.dart';


import '../../models/student.dart';
import '../../services/bus_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../tracking/bus_info.dart';

class HomeScreen extends StatefulWidget {
  final Student student;

  const HomeScreen({
    super.key,
    required this.student,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BusService _busService = BusService();

  List<BusInfo> _buses = [];
  bool _isLoadingBuses = true;
  String? _busError;

  @override
  void initState() {
    super.initState();
    _loadInstitutionBuses();
  }

  Future<void> _loadInstitutionBuses() async {
    setState(() {
      _isLoadingBuses = true;
      _busError = null;
    });

    try {
      final buses = await _busService.getInstitutionBuses(
        widget.student.institutionId,
      );

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

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning';
    }

    if (hour < 17) {
      return 'Good Afternoon';
    }

    return 'Good Evening';
  }

  String _getFirstName() {
    final name = widget.student.fullName.trim();

    if (name.isEmpty) {
      return 'Student';
    }

    return name.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadInstitutionBuses,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.pagePadding,
              8,
              AppDimensions.pagePadding,
              32,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStudentInfo(),
                const SizedBox(height: 22),
                _buildBusSection(),
                const SizedBox(height: 26),
                _buildQuickActions(),
                const SizedBox(height: 26),
                _buildServiceStatus(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              child: const Icon(
                Icons.directions_bus_rounded,
                color: Colors.white,
                size: 27,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BusX',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Smart College Bus Tracking',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: IconButton(
                tooltip: 'Notifications',
                onPressed: () {
                  // Notification screen can be connected later.
                },
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Student Information
  // ─────────────────────────────────────────────

  Widget _buildStudentInfo() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()},',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 3),
              Text(
                '${_getFirstName()} 👋',
                style: AppTextStyles.heading.copyWith(
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.school_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 5),
              Text(
                widget.student.branch ?? 'Student',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Institution Bus Section
  // ─────────────────────────────────────────────

  Widget _buildBusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Institution Buses',
                    style: AppTextStyles.title,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_buses.length} ${_buses.length == 1 ? 'bus' : 'buses'} available',
                    style: AppTextStyles.small,
                  ),
                ],
              ),
            ),

            IconButton(
              tooltip: 'Refresh buses',
              onPressed: _isLoadingBuses
                  ? null
                  : _loadInstitutionBuses,
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppColors.primary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        _buildBusContent(),
      ],
    );
  }

  Widget _buildBusContent() {
    if (_isLoadingBuses) {
      return _buildBusLoading();
    }

    if (_busError != null) {
      return _buildBusError();
    }

    if (_buses.isEmpty) {
      return _buildEmptyBusState();
    }

    return Column(
      children: _buses.map((bus) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildBusCard(bus),
        );
      }).toList(),
    );
  }

  Widget _buildBusLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Loading institution buses...',
            style: AppTextStyles.subtitle,
          ),
        ],
      ),
    );
  }

  Widget _buildBusError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: AppColors.error,
            size: 30,
          ),
          const SizedBox(height: 10),
          const Text(
            'Unable to load buses',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _busError!,
            textAlign: TextAlign.center,
            style: AppTextStyles.small,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loadInstitutionBuses,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBusState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.directions_bus_outlined,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No buses available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'There are currently no active buses registered for your institution.',
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
      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        onTap: () {
          _showBusDetails(bus);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
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
                        Flexible(
                          child: Text(
                            bus.busNumber.isEmpty
                                ? 'Bus'
                                : bus.busNumber,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        _buildStatusBadge(bus.isActive),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Text(
                        bus.routeName.isNotEmpty
                           ? bus.routeName
                           : 'Route not available',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.subtitle,
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 7,
                          color: AppColors.live,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          bus.isActive ? 'Available' : 'Inactive',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: bus.isActive
                                ? AppColors.success
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
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
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withValues(alpha: 0.10)
            : AppColors.textSecondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.live
                  : AppColors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'ACTIVE' : 'OFFLINE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: isActive
                  ? AppColors.success
                  : AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Quick Actions
  // ─────────────────────────────────────────────

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Access',
          style: AppTextStyles.title,
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: _buildQuickAction(
                icon: Icons.location_on_rounded,
                title: 'Live Tracking',
                subtitle: 'Track buses',
                color: AppColors.primary,
                onTap: () {
                  // Connected through the main navigation shell.
                  // This can be wired to the Track tab next.
                },
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _buildQuickAction(
                icon: Icons.campaign_rounded,
                title: 'Announcements',
                subtitle: 'Latest updates',
                color: AppColors.accent,
                onTap: () {
                  // Connected through the main navigation shell.
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildQuickAction(
                icon: Icons.notifications_rounded,
                title: 'Notices',
                subtitle: 'College notices',
                color: AppColors.warning,
                onTap: () {
                  // Connected through the main navigation shell.
                },
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _buildQuickAction(
                icon: Icons.report_problem_rounded,
                title: 'Complaints',
                subtitle: 'Report an issue',
                color: AppColors.error,
                onTap: () {
                  // Connected through the main navigation shell.
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.small,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Service Status
  // ─────────────────────────────────────────────

  Widget _buildServiceStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BusX Services',
          style: AppTextStyles.title,
        ),

        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(17),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              _buildServiceRow(
                icon: Icons.directions_bus_rounded,
                title: 'Institution Fleet',
                subtitle: _buses.isEmpty
                    ? 'No active buses'
                    : '${_buses.length} active buses available',
                color: AppColors.primary,
              ),

              const Divider(height: 24),

              _buildServiceRow(
                icon: Icons.location_on_rounded,
                title: 'Live Tracking',
                subtitle: 'Real-time bus locations',
                color: AppColors.success,
              ),

              const Divider(height: 24),

              _buildServiceRow(
                icon: Icons.support_agent_rounded,
                title: 'Student Support',
                subtitle: 'Report and track complaints',
                color: AppColors.accent,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 21,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: AppTextStyles.small,
              ),
            ],
          ),
        ),

        const Icon(
          Icons.check_circle_rounded,
          color: AppColors.success,
          size: 19,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Bus Details
  // ─────────────────────────────────────────────

  void _showBusDetails(BusInfo bus) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(26),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primaryLight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: Colors.white,
                      size: 27,
                    ),
                  ),

                  const SizedBox(width: 13),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bus.busNumber.isEmpty
                              ? 'Bus'
                              : bus.busNumber,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          bus.routeName.isEmpty
                              ? 'Route not available'
                              : bus.routeName,
                          style: AppTextStyles.subtitle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              _buildDetailItem(
                icon: Icons.route_rounded,
                title: 'Route',
                value: bus.routeName.isEmpty
                    ? 'Not available'
                    : bus.routeName,
              ),

              const SizedBox(height: 12),

              _buildDetailItem(
                icon: Icons.directions_bus_rounded,
                title: 'Bus Number',
                value: bus.busNumber.isEmpty
                    ? 'Not available'
                    : bus.busNumber,
              ),

              const SizedBox(height: 12),

              _buildDetailItem(
                icon: Icons.circle,
                title: 'Status',
                value: bus.isActive ? 'Active' : 'Offline',
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: bus.isActive
                      ? () {
                          Navigator.pop(context);
                          // TODO: Navigate to tracking detail for this bus.
                        }
                      : null,
                  icon: const Icon(Icons.location_on_rounded),
                  label: Text(
                    bus.isActive ? 'Track This Bus' : 'Bus Offline',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}


  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Text(
              title,
              style: AppTextStyles.small,
            ),
          ),

          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Common Card Decoration
  // ─────────────────────────────────────────────

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
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

