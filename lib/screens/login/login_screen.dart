
import 'package:flutter/material.dart';

import '../../models/student.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
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

  @override
  void dispose() {
    _usnController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // LOGIN
  // ------------------------------------------------------------

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final usn = _usnController.text.trim().toUpperCase();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
    });

    try {
      final Student? student = await AuthService().login(
        usn: usn,
        password: password,
      );

      if (!mounted) return;

      if (student == null) {
        setState(() {
          _isLoading = false;
        });

        _showMessage(
          'Invalid USN or password',
          isError: true,
        );

        return;
      }

      // Save logged-in student locally.
      await SessionService.saveStudent(student);

if (!mounted) return;

setState(() {
  _isLoading = false;
});

Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (_) => const BusXShell(),
  ),
);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  // ------------------------------------------------------------
  // MESSAGE
  // ------------------------------------------------------------

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
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
              Expanded(
                child: Text(message),
              ),
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

    // Keeps the content comfortable on tablets/web while
    // remaining fully responsive on phones.
    final contentWidth = screenWidth > 600 ? 480.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppTheme.background,

      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },

          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),

              padding: EdgeInsets.symmetric(
                horizontal: screenWidth < 360 ? 18 : 24,
                vertical: 24,
              ),

              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: contentWidth,
                ),

                child: Form(
                  key: _formKey,

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                      // ------------------------------------------------
                      // LOGO
                      // ------------------------------------------------

                      _buildLogo(),

                      const SizedBox(height: 24),

                      // ------------------------------------------------
                      // TITLE
                      // ------------------------------------------------

                      const Text(
                        'Welcome Back!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Sign in to access your SGI bus tracking account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 34),

                      // ------------------------------------------------
                      // LOGIN CARD
                      // ------------------------------------------------

                      Container(
                        padding: EdgeInsets.all(
                          screenWidth < 360 ? 18 : 22,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: 0.06,
                              ),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [

                            // ------------------------------------------
                            // USN
                            // ------------------------------------------

                            const Text(
                              'Student USN',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 8),

                            TextFormField(
                              controller: _usnController,

                              textCapitalization:
                                  TextCapitalization.characters,

                              textInputAction:
                                  TextInputAction.next,

                              keyboardType:
                                  TextInputType.text,

                              enabled: !_isLoading,

                              autocorrect: false,

                              decoration: InputDecoration(
                                hintText: 'Enter your USN',

                                prefixIcon: const Icon(
                                  Icons.badge_outlined,
                                ),

                                prefixIconColor:
                                    AppTheme.primaryBlue,

                                filled: true,
                                fillColor:
                                    const Color(0xFFF8FAFC),

                                contentPadding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),

                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),

                                enabledBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                  ),
                                ),

                                focusedBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryBlue,
                                    width: 1.5,
                                  ),
                                ),
                              ),

                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Please enter your USN';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            // ------------------------------------------
                            // PASSWORD
                            // ------------------------------------------

                            const Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 8),

                            TextFormField(
                              controller: _passwordController,

                              obscureText: _obscurePassword,

                              textInputAction:
                                  TextInputAction.done,

                              enabled: !_isLoading,

                              autocorrect: false,

                              onFieldSubmitted: (_) {
                                if (!_isLoading) {
                                  _login();
                                }
                              },

                              decoration: InputDecoration(
                                hintText: 'Enter your password',

                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),

                                prefixIconColor:
                                    AppTheme.primaryBlue,

                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',

                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },

                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons
                                            .visibility_outlined
                                        : Icons
                                            .visibility_off_outlined,
                                  ),
                                ),

                                filled: true,
                                fillColor:
                                    const Color(0xFFF8FAFC),

                                contentPadding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),

                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),

                                enabledBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                  ),
                                ),

                                focusedBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryBlue,
                                    width: 1.5,
                                  ),
                                ),
                              ),

                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please enter your password';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 26),

                            // ------------------------------------------
                            // LOGIN BUTTON
                            // ------------------------------------------

                            SizedBox(
                              width: double.infinity,
                              height: 54,

                              child: ElevatedButton(
                                onPressed:
                                    _isLoading ? null : _login,

                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppTheme.primaryBlue,

                                  foregroundColor:
                                      Colors.white,

                                  disabledBackgroundColor:
                                      AppTheme.primaryBlue
                                          .withValues(alpha: 0.65),

                                  disabledForegroundColor:
                                      Colors.white,

                                  elevation: 0,

                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                ),

                                child: _isLoading
                                    ? const SizedBox(
                                        width: 23,
                                        height: 23,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<
                                                  Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'LOGIN',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight:
                                                  FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(
                                            Icons
                                                .arrow_forward_rounded,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ------------------------------------------------
                      // SECURITY / INFO
                      // ------------------------------------------------

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons
                                .verified_user_outlined,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Student access only',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'SGI Bus Tracking System',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '© ${DateTime.now().year} SGI',
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
  // LOGO WIDGET
  // ------------------------------------------------------------

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 88,
        height: 88,

        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryBlue,
              AppTheme.blue,
            ],
          ),

          borderRadius: BorderRadius.circular(26),

          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(
                alpha: 0.22,
              ),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),

        child: const Icon(
          Icons.directions_bus_rounded,
          color: Colors.white,
          size: 50,
        ),
      ),
    );
  }
}

