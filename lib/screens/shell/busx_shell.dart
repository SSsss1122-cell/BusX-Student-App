import 'package:flutter/material.dart';

import '../../models/student.dart';
import '../../theme/app_colors.dart';
import '../announcements/announcements_screen.dart';
import '../complaints/complaints_screen.dart';
import '../home/home_screen.dart';
import '../notices/notices_screen.dart';
import '../profile/profile_screen.dart';
import '../tracking/tracking_screen.dart';

class BusXShell extends StatefulWidget {
  final Student student;

  const BusXShell({
    super.key,
    required this.student,
  });

  @override
  State<BusXShell> createState() => _BusXShellState();
}

class _BusXShellState extends State<BusXShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      HomeScreen(student: widget.student),
      TrackingScreen(student: widget.student),
      AnnouncementsScreen(student: widget.student),
      NoticesScreen(student: widget.student),
      ComplaintsScreen(student: widget.student),
      ProfileScreen(student: widget.student),
    ];
  }

  void _changePage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // ----------------------------------------------------------
      // TOP APP BAR
      // ----------------------------------------------------------

      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,

        titleSpacing: 18,

        title: Row(
          children: [
            // BusX logo
            Container(
              width: 38,
              height: 38,

              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primaryLight,
                  ],
                ),
                borderRadius: BorderRadius.circular(11),
              ),

              child: const Icon(
                Icons.directions_bus_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),

            const SizedBox(width: 10),

            const Text(
              'BusX',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),

        actions: [
          // Notification button
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              // Notifications will be connected later.
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  size: 27,
                ),

                // Notification indicator
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 4),
        ],
      ),

      // ----------------------------------------------------------
      // MAIN CONTENT
      // ----------------------------------------------------------

      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // ----------------------------------------------------------
      // BOTTOM NAVIGATION
      // ----------------------------------------------------------

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,

        onDestinationSelected: _changePage,

        backgroundColor: Colors.white,

        indicatorColor:
            AppColors.primary.withValues(alpha: 0.12),

        elevation: 8,

        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon: Icon(
              Icons.home_rounded,
            ),
            label: 'Home',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.location_on_outlined,
            ),
            selectedIcon: Icon(
              Icons.location_on_rounded,
            ),
            label: 'Track',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.campaign_outlined,
            ),
            selectedIcon: Icon(
              Icons.campaign_rounded,
            ),
            label: 'Updates',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.person_outline_rounded,
            ),
            selectedIcon: Icon(
              Icons.person_rounded,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}