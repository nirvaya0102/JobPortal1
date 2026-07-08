import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radii.dart';
import '../../../core/constants/app_spacing.dart';
import '../../jobs/models/job_model.dart';
import '../services/admin_job_service.dart';
import 'admin_job_detail_screen.dart';

class PendingJobsScreen extends StatefulWidget {
  const PendingJobsScreen({super.key});

  @override
  State<PendingJobsScreen> createState() => _PendingJobsScreenState();
}

class _PendingJobsScreenState extends State<PendingJobsScreen> {
  final AdminJobService _adminJobService = AdminJobService();
  late Future<AdminJobsPageResult> _jobsFuture;

  @override
  void initState() {
    super.initState();
    _jobsFuture = _adminJobService.getJobs(status: 'PENDING', limit: 50);
  }

  Future<void> _refresh() async {
    setState(() {
      _jobsFuture = _adminJobService.getJobs(status: 'PENDING', limit: 50);
    });
    await _jobsFuture;
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
        title: const Text('Pending Jobs'),
        backgroundColor: const Color(0xFFF6F8FC),
        foregroundColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<AdminJobsPageResult>(
          future: _jobsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(snapshot.error.toString().replaceAll('Exception: ', '')),
                ],
              );
            }

            final jobs = snapshot.data?.jobs ?? <JobModel>[];

            if (jobs.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: const Text('No pending jobs need review.'),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: jobs.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final job = jobs[index];
                return Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    side: const BorderSide(color: AppColors.borderLight),
                  ),
                  child: ListTile(
                    onTap: () => _openJob(job),
                    leading: const Icon(Icons.pending_actions_rounded),
                    title: Text(job.title),
                    subtitle: Text(
                      '${job.companyName ?? 'Company'} - ${job.location ?? 'Location'}',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
