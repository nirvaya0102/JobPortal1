import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../jobs/services/job_service.dart';
import '../../jobs/models/application_model.dart';

class ApplicantsScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const ApplicantsScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  final JobService jobService = JobService();
  
  List<ApplicationModel> applicants = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchApplicants();
  }

  Future<void> fetchApplicants() async {
    try {
      setState(() {
        loading = true;
        errorMessage = null;
      });

      final result = await jobService.getJobApplicants(widget.jobId);
      setState(() {
        applicants = result;
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

  Future<void> updateStatus(String applicationId, String newStatus) async {
    try {
      await jobService.updateApplicationStatus(widget.jobId, applicationId, newStatus);
      // Update local state
      setState(() {
        final index = applicants.indexWhere((app) => app.id == applicationId);
        if (index != -1) {
          final oldApp = applicants[index];
          applicants[index] = ApplicationModel(
            id: oldApp.id,
            jobId: oldApp.jobId,
            candidateId: oldApp.candidateId,
            coverLetter: oldApp.coverLetter,
            status: newStatus,
            appliedAt: oldApp.appliedAt,
            candidate: oldApp.candidate,
            resumeFileName: oldApp.resumeFileName,
          );
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  Future<void> viewResume(String applicationId) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fetching resume link...')),
      );
      final url = await jobService.getApplicationResume(widget.jobId, applicationId);
      if (url.isNotEmpty) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not launch $url');
        }
      } else {
        throw Exception('Resume URL is empty');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to view resume: $e')),
        );
      }
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'REVIEWED':
        return Colors.blue;
      case 'SHORTLISTED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Applicants: ${widget.jobTitle}'),
        backgroundColor: const Color(0xFF1A1F8F),
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchApplicants,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : applicants.isEmpty
                  ? const Center(
                      child: Text('No applicants found for this job.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: applicants.length,
                      itemBuilder: (context, index) {
                        final app = applicants[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        app.candidate.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Chip(
                                      label: Text(
                                        app.status,
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                      backgroundColor: getStatusColor(app.status),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      app.candidate.email,
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (app.coverLetter != null && app.coverLetter!.isNotEmpty) ...[
                                  const Text(
                                    'Cover Letter:',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    app.coverLetter!,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => viewResume(app.id),
                                      icon: const Icon(Icons.file_download, size: 18),
                                      label: const Text('View Resume'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFF3F0FF),
                                        foregroundColor: const Color(0xFF1A1F8F),
                                      ),
                                    ),
                                    DropdownButton<String>(
                                      value: app.status,
                                      underline: const SizedBox(),
                                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1A1F8F)),
                                      items: const [
                                        DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                                        DropdownMenuItem(value: 'REVIEWED', child: Text('Reviewed')),
                                        DropdownMenuItem(value: 'SHORTLISTED', child: Text('Shortlisted')),
                                        DropdownMenuItem(value: 'REJECTED', child: Text('Rejected')),
                                      ],
                                      onChanged: (newStatus) {
                                        if (newStatus != null && newStatus != app.status) {
                                          updateStatus(app.id, newStatus);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
