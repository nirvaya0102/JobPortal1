import 'package:flutter/material.dart';

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
      appBar: AppBar(title: const Text('Saved Jobs')),
      body: ValueListenableBuilder<int>(
        valueListenable: SavedJobsService.revision,
        builder: (context, _, _) {
          return FutureBuilder<List<JobModel>>(
            future: SavedJobsService.getSavedJobs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Something went wrong. Please try again.'),
                  ),
                );
              }

              final jobs = snapshot.data ?? <JobModel>[];
              if (jobs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('You have not saved any jobs yet.'),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: jobs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
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
