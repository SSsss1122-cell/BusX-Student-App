import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../complaints/complaints_screen.dart';
import '../announcements/announcements_screen.dart';
import '../notices/notices_screen.dart';
import '../fees/fees_screen.dart';
import '../stops/stops_screen.dart';       // ← NEW
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
    StopsScreen(),       // 1  ← NEW
    FeesScreen(),        // 2
    ProfileScreen(),     // 3
  ];

  final List<String> _titles = const [
    'Live Tracking',
    'Bus Stops',         // ← NEW
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnnouncementsScreen()),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_rounded),
            label: 'Tracking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route_rounded),      // ← NEW
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
    );
  }

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
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: initials.isEmpty
                      ? const Icon(Icons.person,
                          color: Colors.white, size: 35)
                      : Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'USN: $displayUsn',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // ---- Bottom-nav tabs (switch index, don't push) ----
          _drawerItem(Icons.location_on_outlined, 'Tracking', () {
            Navigator.pop(context);
            setState(() => _currentIndex = 0);
          }),
          _drawerItem(Icons.route_outlined, 'Bus Stops', () {     // ← NEW
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

          const Divider(),

          // ---- Pushed screens ----
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
          _drawerItem(Icons.notifications_outlined, 'Notices', () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NoticesScreen()));
          }),

          const Divider(),

          _drawerItem(Icons.settings_outlined, 'Settings',
              () => Navigator.pop(context)),
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

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}