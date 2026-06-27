import 'package:flutter/material.dart';

import '../../../core/constants/app_radii.dart';
import '../../../core/constants/app_spacing.dart';
import '../../jobs/models/job_model.dart';
import '../../jobs/services/job_service.dart';
import '../widgets/employer_dashboard_theme.dart';
import 'applicants_screen.dart';

class EmployerApplicantJobsScreen extends StatefulWidget {
  final String token;

  const EmployerApplicantJobsScreen({super.key, required this.token});

  @override
  State<EmployerApplicantJobsScreen> createState() =>
      _EmployerApplicantJobsScreenState();
}

class _EmployerApplicantJobsScreenState
    extends State<EmployerApplicantJobsScreen> {
  final JobService _jobService = JobService();

  late Future<List<JobModel>> _jobsFuture;

  @override
  void initState() {
    super.initState();
    _jobsFuture = _jobService.getMyJobs(widget.token);
  }

  Future<void> _refreshJobs() async {
    setState(() {
      _jobsFuture = _jobService.getMyJobs(widget.token);
    });
    await _jobsFuture;
  }

  void _openApplicants(JobModel job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApplicantsScreen(jobId: job.id, jobTitle: job.title),
      ),
    );
  }

  String _friendlyError(Object? error) {
    final message = error.toString().toLowerCase();
    if (message.contains('socket') || message.contains('network')) {
      return 'No internet connection.';
    }
    if (message.contains('401') || message.contains('unauthorized')) {
      return 'Your session has expired. Please log in again.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmployerDashboardPalette.canvas,
      appBar: AppBar(
        title: const Text('Applicants by Job'),
        backgroundColor: EmployerDashboardPalette.canvas,
        foregroundColor: EmployerDashboardPalette.primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: EmployerGradientBackground(
        child: FutureBuilder<List<JobModel>>(
          future: _jobsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _friendlyError(snapshot.error),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: EmployerDashboardPalette.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton(
                        onPressed: _refreshJobs,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final jobs = snapshot.data ?? const <JobModel>[];
            if (jobs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    'No jobs posted yet. Post a job to start receiving applicants.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: EmployerDashboardPalette.textMuted),
                  ),
                ),
              );
            }

            final totalApplicants = jobs.fold<int>(
              0,
              (sum, job) => sum + job.applicantsCount,
            );

            return RefreshIndicator(
              onRefresh: _refreshJobs,
              color: EmployerDashboardPalette.primary,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                itemCount: jobs.length + 1,
                separatorBuilder: (_, index) => SizedBox(
                  height: index == 0 ? AppSpacing.lg : AppSpacing.md,
                ),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _ApplicantOverview(
                      jobsCount: jobs.length,
                      applicantsCount: totalApplicants,
                    );
                  }

                  final job = jobs[index - 1];
                  return _ApplicantJobCard(
                    job: job,
                    onTap: () => _openApplicants(job),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ApplicantOverview extends StatelessWidget {
  final int jobsCount;
  final int applicantsCount;

  const _ApplicantOverview({
    required this.jobsCount,
    required this.applicantsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: EmployerDashboardPalette.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: EmployerDashboardPalette.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.groups_2_outlined,
            color: EmployerDashboardPalette.primary,
            size: 32,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$applicantsCount total applicants',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: EmployerDashboardPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Across $jobsCount posted ${jobsCount == 1 ? 'job' : 'jobs'}',
                  style: const TextStyle(
                    color: EmployerDashboardPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicantJobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;

  const _ApplicantJobCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasApplicants = job.applicantsCount > 0;

    return Material(
      color: EmployerDashboardPalette.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: EmployerDashboardPalette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                      (hasApplicants
                              ? EmployerDashboardPalette.success
                              : EmployerDashboardPalette.primary)
                          .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(
                  hasApplicants
                      ? Icons.groups_2_outlined
                      : Icons.person_search_outlined,
                  color: hasApplicants
                      ? EmployerDashboardPalette.success
                      : EmployerDashboardPalette.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: EmployerDashboardPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${job.applicantsCount} ${job.applicantsCount == 1 ? 'applicant' : 'applicants'}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: hasApplicants
                            ? EmployerDashboardPalette.success
                            : EmployerDashboardPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: EmployerDashboardPalette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
