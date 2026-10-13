import 'package:flutter/material.dart';

/// Clean, professional background.
/// Just a soft off-white gradient — no blobs, no blur, no noise.
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF7F9FC),
            Color(0xFFF1F5F9),
          ],
        ),
      ),
      child: child,
    );
  }
}