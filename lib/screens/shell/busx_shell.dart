import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_background.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../complaints/complaints_screen.dart';
import '../announcements/announcements_screen.dart';
import '../fees/fees_screen.dart';
import '../stops/stops_screen.dart';
import '../login/login_screen.dart';

class BusXShell extends StatefulWidget {
  const BusXShell({super.key});

  @override
  State<BusXShell> createState() => _BusXShellState();
}

class _BusXShellState extends State<BusXShell> {
  int _currentIndex = 0;
  Student? _student;

  final List<Widget> _screens = const [
    HomeScreen(),        // 0
    StopsScreen(),       // 1
    FeesScreen(),        // 2
    ProfileScreen(),     // 3
  ];

  final List<String> _titles = const [
    'Live Tracking',
    'Bus Stops',
    'Fees',
    'My Profile',
  ];

  @override
  void initState() {
    super.initState();
    _loadStudent();
  }

  Future<void> _loadStudent() async {
    final s = await SessionService.getStudent();
    if (!mounted) return;
    setState(() => _student = s);
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        extendBodyBehindAppBar: true,

        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 12),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: _topBar(context),
            ),
          ),
        ),

        drawer: _buildDrawer(),

        body: SafeArea(
          top: false,
          bottom: false,
          child: _screens[_currentIndex],
        ),

        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _bottomNav(),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // FLAT WHITE TOP BAR
  // ------------------------------------------------------------
  Widget _topBar(BuildContext context) {
    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded,
                  color: AppColors.textPrimary),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          Expanded(
            child: Text(
              _titles[_currentIndex],
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: AppColors.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AnnouncementsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // FLAT WHITE BOTTOM NAV
  // ------------------------------------------------------------
  Widget _bottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_rounded),
              label: 'Tracking',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.route_rounded),
              label: 'Stops',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Fees',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // DRAWER
  // ------------------------------------------------------------
  Widget _buildDrawer() {
    final displayName = _student?.fullName ?? 'Student';
    final displayUsn = _student?.usn ?? '—';

    final initials = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Drawer(
      backgroundColor: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          _drawerHeader(displayName, displayUsn, initials),
          const SizedBox(height: 8),

          _drawerItem(Icons.location_on_outlined, 'Tracking', () {
            Navigator.pop(context);
            setState(() => _currentIndex = 0);
          }),
          _drawerItem(Icons.route_outlined, 'Bus Stops', () {
            Navigator.pop(context);
            setState(() => _currentIndex = 1);
          }),
          _drawerItem(Icons.receipt_long_outlined, 'Fees', () {
            Navigator.pop(context);
            setState(() => _currentIndex = 2);
          }),
          _drawerItem(Icons.person_outline, 'Profile', () {
            Navigator.pop(context);
            setState(() => _currentIndex = 3);
          }),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Divider(color: Color(0xFFE2E8F0)),
          ),

          _drawerItem(Icons.report_problem_outlined, 'Complaints', () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ComplaintsScreen()));
          }),
          _drawerItem(Icons.campaign_outlined, 'Announcements', () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AnnouncementsScreen()));
          }),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Divider(color: Color(0xFFE2E8F0)),
          ),

          _drawerItem(Icons.logout_rounded, 'Logout', () async {
            Navigator.pop(context);
            await SessionService.logout();
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // DRAWER HEADER — now sits below the status bar on every device
  // ------------------------------------------------------------
  Widget _drawerHeader(
      String displayName, String displayUsn, String initials) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        12,
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.20),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              child: initials.isEmpty
                  ? const Icon(Icons.person, color: Colors.white, size: 32)
                  : Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'USN: $displayUsn',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}