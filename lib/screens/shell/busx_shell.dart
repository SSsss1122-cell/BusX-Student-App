import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../complaints/complaints_screen.dart';
import '../announcements/announcements_screen.dart';
import '../notices/notices_screen.dart';
import '../login/login_screen.dart';

class BusXShell extends StatefulWidget {
  const BusXShell({super.key});

  @override
  State<BusXShell> createState() => _BusXShellState();
}

class _BusXShellState extends State<BusXShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ProfileScreen(),
  ];

  final List<String> _titles = const [
    'Live Tracking',
    'My Profile',
  ];

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
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white, size: 35),
                ),
                SizedBox(height: 10),
                Text('Student Name',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    )),
                Text('student@sgi.edu',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          _drawerItem(Icons.person_outline, 'Profile', () {
            Navigator.pop(context);
            setState(() => _currentIndex = 1);
          }),
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
          _drawerItem(
              Icons.payment_outlined, 'Fees', () => Navigator.pop(context)),
          _drawerItem(Icons.settings_outlined, 'Settings',
              () => Navigator.pop(context)),
          _drawerItem(Icons.logout_rounded, 'Logout', () async {
  Navigator.pop(context); // close drawer
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('logged_in_usn');
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
