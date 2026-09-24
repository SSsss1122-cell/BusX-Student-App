import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/student.dart';
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import '../login/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Student? student;

  const ProfileScreen({super.key, this.student});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Student? _student;
  String? _institutionName;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    // 1. Get student from session (or from widget)
    Student? s = widget.student;
    s ??= await SessionService.getStudent();

    // 2. Get institution name (cached at login)
    String? instName = await SessionService.getInstitutionName();

    // 3. If not cached, fetch from Supabase
    if (instName == null && s != null) {
      try {
        final row = await Supabase.instance.client
            .from('institutions')
            .select('name')      // ⚠️ change to 'institution_name' if that's the column
            .eq('id', s.institutionId)
            .maybeSingle();

        if (row != null && row['name'] != null) {
          instName = row['name'] as String;
          await SessionService.saveInstitutionName(instName);
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _student = s;
      _institutionName = instName;
      _loading = false;
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await SessionService.logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _student == null
              ? _buildNoStudent()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 18),
                        _buildInfoCard(),
                        const SizedBox(height: 18),
                        _buildLogoutButton(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  // -----------------------------------------------------------------
  // HEADER (avatar + name + usn)
  // -----------------------------------------------------------------
  Widget _buildHeader() {
    final name = _student!.fullName;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: Colors.white24,
            child: initials.isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 44)
                : Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _student!.usn ?? '—',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // INFO CARD
  // -----------------------------------------------------------------
  Widget _buildInfoCard() {
    final s = _student!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Student Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 8),

          _infoRow(
            Icons.badge_rounded,
            'USN',
            _orNA(s.usn),
          ),
          _infoRow(
            Icons.person_rounded,
            'Full Name',
            s.fullName,
          ),
          _infoRow(
            Icons.school_rounded,
            'Branch',
            _orNA(s.branch),
          ),
          _infoRow(
            Icons.calendar_today_rounded,
            'Semester',
            _formatSemester(s.semester),
          ),
          _infoRow(
            Icons.account_balance_rounded,
            'Institution',
            _institutionName ?? 'Not available',
          ),
          _infoRow(
            Icons.directions_bus_rounded,
            'Route',
            _orNA(s.routes),
          ),
          _infoRow(
            Icons.phone_rounded,
            'Phone',
            _orNA(s.phone),
          ),
          _infoRow(
            Icons.email_rounded,
            'Email',
            _orNA(s.email),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // HELPERS
  // -----------------------------------------------------------------
  String _orNA(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Not available' : v;

  String _formatSemester(String? sem) {
    if (sem == null || sem.trim().isEmpty) return 'Not available';
    // If it's just a number like "5", prefix with "Semester "
    final trimmed = sem.trim();
    if (RegExp(r'^\d+$').hasMatch(trimmed)) {
      return 'Semester $trimmed';
    }
    return trimmed;
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout_rounded),
        label: const Text(
          'LOGOUT',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildNoStudent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_rounded,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No student data found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please log in again.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }
}