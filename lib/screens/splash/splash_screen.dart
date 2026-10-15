import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import '../shell/busx_shell.dart';
import '../login/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _blueReveal;
  late Animation<double> _contentFade;
  late Animation<double> _contentScale;
  late Animation<double> _spinnerFade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _blueReveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeInOutCubic),
    );

    _contentFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
    );

    _contentScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _spinnerFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();
    _goNext();
  }

  Future<void> _goNext() async {
    // Let the animation play
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    // Session check (with 3s timeout)
    Student? student;
    try {
      student = await SessionService.getStudent()
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      student = null;
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            student != null ? const BusXShell() : const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Use diagonal so circle covers corners
    final diagonal =
        (size.width * size.width + size.height * size.height);
    // Newton's method for sqrt
    double diag = diagonal;
    double x = diagonal;
    for (int i = 0; i < 20; i++) {
      x = (x + diag / x) / 2;
    }
    final maxRadius = x / 2 + 60;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // 0 → 1
          final t = _blueReveal.value;
          // Scale goes 0 → 1 (from nothing to full size)
          final scale = t;

          return Stack(
            // Make sure nothing is clipped
            clipBehavior: Clip.none,
            children: [
              // ---- Blue circle (fixed size, scaled) ----
              Positioned(
                left: size.width / 2 - maxRadius,
                top: size.height / 2 - maxRadius,
                width: maxRadius * 2,
                height: maxRadius * 2,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2563EB),
                          Color(0xFF1D4ED8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ---- Content on top ----
              Positioned.fill(
                child: SafeArea(
                  child: Column(
                    children: [
                      const Spacer(flex: 3),

                      FadeTransition(
                        opacity: _contentFade,
                        child: ScaleTransition(
                          scale: _contentScale,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ---- White circle with bus icon ----
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.18),
                                      blurRadius: 30,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.directions_bus_filled_rounded,
                                  size: 60,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // ---- "BusX" text ----
                              const Text(
                                'BusX',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(flex: 4),

                      FadeTransition(
                        opacity: _spinnerFade,
                        child: const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}