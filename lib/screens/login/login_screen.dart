import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/student.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../services/version_checker.dart';
import '../../theme/app_colors.dart';
import '../../widgets/update_dialog.dart';
import '../shell/busx_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usnController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  // ---- storage keys ----
  static const _kRememberMe = 'remember_me';
  static const _kSavedUsn = 'saved_usn';
  static const _kSavedPwd = 'saved_password';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();

    // Run version check silently after login screen renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  @override
  void dispose() {
    _usnController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // VERSION CHECK (silent, non-blocking)
  // ------------------------------------------------------------
  Future<void> _checkForUpdates() async {
    if (!mounted) return;
    try {
      final update = await VersionChecker.check()
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;

      if (update != null) {
        final (info, force) = update;
        await showUpdateDialog(context, info, force: force);
      }
    } catch (_) {
      // Silently ignore version check failures
    }
  }

  // ------------------------------------------------------------
  // LOAD SAVED CREDENTIALS
  // ------------------------------------------------------------
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_kRememberMe) ?? false;
    final usn = prefs.getString(_kSavedUsn);
    final pwd = prefs.getString(_kSavedPwd);

    debugPrint('🔍🔍🔍 LOAD ===== remember=$remember  USN=$usn  PWD=$pwd');

    if (!remember) return;
    if (!mounted) return;

    setState(() {
      _rememberMe = true;
      _usnController.text = usn ?? '';
      _passwordController.text = pwd ?? '';
    });
  }

  // ------------------------------------------------------------
  // SAVE / CLEAR CREDENTIALS
  // ------------------------------------------------------------
  Future<void> _saveCredentials(String usn, String password) async {
    final prefs = await SharedPreferences.getInstance();

    debugPrint(
        '💾💾💾 SAVE ===== rememberMe=$_rememberMe  USN=$usn  PWD=$password');

    if (_rememberMe) {
      await prefs.setBool(_kRememberMe, true);
      await prefs.setString(_kSavedUsn, usn);
      await prefs.setString(_kSavedPwd, password);
      debugPrint('✅ saved to prefs');
    } else {
      await prefs.remove(_kRememberMe);
      await prefs.remove(_kSavedUsn);
      await prefs.remove(_kSavedPwd);
      debugPrint('❌ cleared from prefs');
    }
  }

  // ------------------------------------------------------------
  // LOGIN
  // ------------------------------------------------------------
  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final usn = _usnController.text.trim().toUpperCase();
    final password = _passwordController.text;

    setState(() => _isLoading = true);

    try {
      final Student? student =
          await AuthService().login(usn: usn, password: password);

      if (!mounted) return;

      if (student == null) {
        setState(() => _isLoading = false);
        _showMessage('Invalid USN or password', isError: true);
        return;
      }

      // Save or clear credentials based on checkbox
      debugPrint('📞 calling _saveCredentials');
      await _saveCredentials(usn, password);
      debugPrint('📞 _saveCredentials done');

      await SessionService.saveStudent(student);
      if (!mounted) return;

      setState(() => _isLoading = false);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BusXShell()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  // ------------------------------------------------------------
  // SNACKBAR
  // ------------------------------------------------------------
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor:
              isError ? Colors.red.shade700 : Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth > 600 ? 460.0 : double.infinity;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth < 360 ? 20 : 24,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      _buildLogo(),

                      const SizedBox(height: 22),

                      const Text(
                        'Welcome Back',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13.5,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ---- Card ----
                      Container(
                        padding: EdgeInsets.all(
                          screenWidth < 360 ? 18 : 22,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ---- USN ----
                            const Text(
                              'Student USN',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _usnController,
                              textCapitalization:
                                  TextCapitalization.characters,
                              textInputAction: TextInputAction.next,
                              enabled: !_isLoading,
                              autocorrect: false,
                              decoration: _inputDecoration(
                                hint: 'Enter your USN',
                                icon: Icons.badge_outlined,
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Please enter your USN';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 18),

                            // ---- Password ----
                            const Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              enabled: !_isLoading,
                              autocorrect: false,
                              onFieldSubmitted: (_) {
                                if (!_isLoading) _login();
                              },
                              decoration: _inputDecoration(
                                hint: 'Enter your password',
                                icon: Icons.lock_outline_rounded,
                                suffix: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  onPressed: _isLoading
                                      ? null
                                      : () => setState(() =>
                                          _obscurePassword =
                                              !_obscurePassword),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 12),

                            // ---- Remember me ----
                            Row(
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: _isLoading
                                        ? null
                                        : (v) => setState(() =>
                                            _rememberMe = v ?? false),
                                    activeColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFFCBD5E1),
                                      width: 1.5,
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: _isLoading
                                      ? null
                                      : () => setState(() =>
                                          _rememberMe = !_rememberMe),
                                  child: const Text(
                                    'Remember my USN and password',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 22),

                            // ---- Login button ----
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      AppColors.primary
                                          .withValues(alpha: 0.65),
                                  disabledForegroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<
                                                  Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'BusX Tracking System',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '© ${DateTime.now().year} BusX',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // INPUT DECORATION
  // ------------------------------------------------------------
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFDC2626),
          width: 1.6,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // LOGO
  // ------------------------------------------------------------
  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primaryLight,
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.directions_bus_rounded,
          color: Colors.white,
          size: 42,
        ),
      ),
    );
  }
}