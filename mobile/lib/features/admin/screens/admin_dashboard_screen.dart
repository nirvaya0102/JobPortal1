import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radii.dart';
import '../../../core/constants/app_spacing.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../jobs/models/job_model.dart';
import '../services/admin_job_service.dart';
import 'admin_job_detail_screen.dart';
import 'pending_jobs_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String name;

  const AdminDashboardScreen({
    super.key,
    required this.name,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminJobService _adminJobService = AdminJobService();
  final AuthService _authService = AuthService();
  late Future<AdminJobsPageResult> _jobsFuture;

  @override
  void initState() {
    super.initState();
    _jobsFuture = _adminJobService.getJobs(limit: 50);
  }

  Future<void> _refresh() async {
    setState(() {
      _jobsFuture = _adminJobService.getJobs(limit: 50);
    });
    await _jobsFuture;
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openPendingJobs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PendingJobsScreen()),
    ).then((_) => _refresh());
  }

  void _openJob(JobModel job) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminJobDetailScreen(job: job)),
    ).then((_) => _refresh());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFFF6F8FC),
        foregroundColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _logout,
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<AdminJobsPageResult>(
          future: _jobsFuture,
          builder: (context, snapshot) {
            final jobs = snapshot.data?.jobs ?? <JobModel>[];
            final pending = jobs.where((job) => job.status == 'PENDING').length;
            final approved =
                jobs.where((job) => job.status == 'APPROVED').length;
            final rejected =
                jobs.where((job) => job.status == 'REJECTED').length;
            final closed = jobs.where((job) => job.status == 'CLOSED').length;

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _StateCard(
                    title: 'Could not load admin jobs',
                    message: snapshot.error.toString().replaceAll('Exception: ', ''),
                    onRetry: _refresh,
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  'Welcome, ${widget.name}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Review employer job posts before candidates can see them.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.55,
                  children: [
                    _MetricCard(label: 'Pending', value: '$pending'),
                    _MetricCard(label: 'Approved', value: '$approved'),
                    _MetricCard(label: 'Rejected', value: '$rejected'),
                    _MetricCard(label: 'Closed', value: '$closed'),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: _openPendingJobs,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Review Pending Jobs'),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Recent Jobs',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (jobs.isEmpty)
                  const _EmptyListCard()
                else
                  ...jobs.take(10).map(
                        (job) => _AdminJobTile(
                          job: job,
                          onTap: () => _openJob(job),
                        ),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _AdminJobTile extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;

  const _AdminJobTile({
    required this.job,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(job.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${job.companyName ?? 'Company'} - ${job.location ?? 'Location'}'),
        trailing: _StatusChip(status: job.status),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'APPROVED' => AppColors.success,
      'REJECTED' => AppColors.danger,
      'CLOSED' => AppColors.textSecondary,
      _ => Colors.orange,
    };

    return Chip(
      label: Text(status),
      backgroundColor: color.withValues(alpha: 0.10),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
      side: BorderSide.none,
    );
  }
}

class _StateCard extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _StateCard({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.xs),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyListCard extends StatelessWidget {
  const _EmptyListCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Text('No jobs found.'),
    );
  }
}
