import 'package:flutter/material.dart';
import '../models/job_model.dart';
import '../services/job_service.dart';
import '../widgets/job_card.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final JobService jobService = JobService();
  final ScrollController scrollController = ScrollController();

  List<JobModel> jobs = [];

  int page = 1;
  final int limit = 10;

  bool loading = false;
  bool loadingMore = false;
  bool hasMore = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchJobs();

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200 &&
          !loadingMore &&
          hasMore &&
          !loading) {
        fetchMoreJobs();
      }
    });
  }

  Future<void> fetchJobs() async {
    try {
      setState(() {
        loading = true;
        errorMessage = null;
        page = 1;
        hasMore = true;
      });

      final result = await jobService.getJobs(page: page, limit: limit);

      setState(() {
        jobs = result;
        hasMore = result.length == limit;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> fetchMoreJobs() async {
    try {
      setState(() {
        loadingMore = true;
      });

      final nextPage = page + 1;
      final result = await jobService.getJobs(page: nextPage, limit: limit);

      setState(() {
        page = nextPage;
        jobs.addAll(result);
        hasMore = result.length == limit;
      });
    } finally {
      setState(() {
        loadingMore = false;
      });
    }
  }

  Widget buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          height: 120,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(14),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return buildSkeleton();
    }

    return RefreshIndicator(
      onRefresh: fetchJobs,
      child: errorMessage != null
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 120),
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: fetchJobs,
                  child: const Text('Retry'),
                ),
              ],
            )
          : jobs.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                SizedBox(height: 120),
                Icon(Icons.work_outline, size: 56),
                SizedBox(height: 12),
                Text(
                  'No jobs available right now.',
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length + (loadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == jobs.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return JobCard(job: jobs[index]);
              },
            ),
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
