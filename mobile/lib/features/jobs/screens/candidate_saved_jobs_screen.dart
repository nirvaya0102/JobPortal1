import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radii.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/job_model.dart';
import '../services/saved_jobs_service.dart';
import '../widgets/candidate_recent_job_card.dart';
import 'job_detail_screen.dart';

class CandidateSavedJobsScreen extends StatefulWidget {
  const CandidateSavedJobsScreen({super.key});

  @override
  State<CandidateSavedJobsScreen> createState() => _CandidateSavedJobsScreenState();
}

class _CandidateSavedJobsScreenState extends State<CandidateSavedJobsScreen> {
  Future<void> _reload() async {
    await SavedJobsService.getSavedJobs();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      appBar: AppBar(title: const Text('Saved Jobs')),
      body: ValueListenableBuilder<int>(
        valueListenable: SavedJobsService.revision,
        builder: (context, _, __) {
          return FutureBuilder<List<JobModel>>(
            future: SavedJobsService.getSavedJobs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _SavedJobsLoadingState();
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: _StateCard(
                      icon: Icons.error_outline_rounded,
                      title: 'Could not load saved jobs',
                      message: 'Something went wrong. Please try again.',
                      actionLabel: 'Retry',
                      onAction: _reload,
                    ),
                  ),
                );
              }

              final jobs = snapshot.data ?? <JobModel>[];
              if (jobs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: _StateCard(
                      icon: Icons.bookmark_border_rounded,
                      title: 'No saved jobs yet',
                      message:
                          'Tap the bookmark icon on any job detail page to save it for later.',
                      actionLabel: 'Refresh',
                      onAction: _reload,
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: jobs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return CandidateRecentJobCard(
                      job: job,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JobDetailScreen(
                              jobId: job.id,
                              currentIndex: 1,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.soft(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: AppColors.primaryBlue),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _SavedJobsLoadingState extends StatelessWidget {
  const _SavedJobsLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemBuilder: (_, __) => Container(
        height: 92,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.borderLight),
        ),
      ),
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemCount: 4,
    );
  }
}
