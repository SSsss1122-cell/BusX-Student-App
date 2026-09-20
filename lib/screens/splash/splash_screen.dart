import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../login/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),

              child: const Icon(
                Icons.directions_bus_rounded,
                size: 65,
                color: AppTheme.primaryBlue,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'SGI BUS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),

            const Text(
              'TRACKING',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 4,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Student App',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}