import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radii.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/candidate_footer.dart';
import 'jobs_screen.dart';

class CandidateJobsListScreen extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const CandidateJobsListScreen({
    super.key,
    this.currentIndex = 0,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.canvasLight,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Namaste', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            Text('Explore Jobs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        titleSpacing: AppSpacing.lg,
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.primary,
      ),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryBlue.withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -45,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.success.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          const JobsScreen(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            boxShadow: AppShadows.medium(),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            child: CandidateFooter(
              currentIndex: currentIndex,
              onTap: onTabSelected,
            ),
          ),
        ),
      ),
    );
  }
}
