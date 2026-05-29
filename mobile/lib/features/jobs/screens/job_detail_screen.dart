import 'package:flutter/material.dart';
import '../models/job_model.dart';
import '../../applications/screens/apply_job_screen.dart';
import '../services/job_service.dart';
import '../../../shared/widgets/candidate_footer.dart';
import 'candidate_main_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;
  final int currentIndex;

  const JobDetailScreen({
    super.key,
    required this.jobId,
    this.currentIndex = 0,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final JobService jobService = JobService();

  JobModel? job;
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchJobDetail();
  }

  Future<void> fetchJobDetail() async {
    try {
      setState(() {
        loading = true;
        errorMessage = null;
      });

      final result = await jobService.getJobById(widget.jobId);

      setState(() {
        job = result;
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

  void _goToTab(int index) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => CandidateMainScreen(initialIndex: index),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Detail')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Detail')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }

    if (job == null) {
      return const Scaffold(body: Center(child: Text('Job not found')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Job Detail')),

      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ApplyJobScreen(
                          jobId: widget.jobId,
                          currentIndex: widget.currentIndex,
                        ),
                      ),
                    );
                  },
                  child: const Text('Apply Now'),
                ),
              ),
            ),
          ),
          CandidateFooter(currentIndex: widget.currentIndex, onTap: _goToTab),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job!.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              job!.companyName ?? 'Unknown Company',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (job!.location != null) Chip(label: Text(job!.location!)),

                if (job!.salary != null) Chip(label: Text(job!.salary!)),

                if (job!.type != null) Chip(label: Text(job!.type!)),
              ],
            ),

            const SizedBox(height: 20),

            ExpansionTile(
              initiallyExpanded: true,
              title: const Text('Job Description'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(job!.description ?? 'No description available.'),
                ),
              ],
            ),

            ExpansionTile(
              title: const Text('Company Details'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    job!.companyName ?? 'Company details not available.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
