import 'package:flutter/material.dart';

import '../../models/student.dart';
import '../../theme/app_colors.dart';

class ComplaintsScreen extends StatelessWidget {
  final Student? student;

  const ComplaintsScreen({
    super.key,
    this.student,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Complaints',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Report and track your bus-related issues',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,

                child: ElevatedButton.icon(
                  onPressed: () {
                    // Complaint form will be connected next.
                  },

                  icon: const Icon(
                    Icons.add_rounded,
                  ),

                  label: const Text(
                    'Report a Complaint',
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'My Complaints',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.report_problem_outlined,
                        size: 60,
                        color: AppColors.primary
                            .withValues(alpha: 0.6),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'No complaints yet',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
