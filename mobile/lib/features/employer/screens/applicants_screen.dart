import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radii.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/section_title.dart';
import '../../chat/screens/chat_room_screen.dart';
import '../../chat/services/stream_chat_service.dart';
import '../../jobs/models/application_model.dart';
import '../../jobs/services/job_service.dart';

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
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> updateStatus(String applicationId, String newStatus) async {
    try {
      await jobService.updateApplicationStatus(widget.jobId, applicationId, newStatus);
      setState(() {
        final index = applicants.indexWhere((app) => app.id == applicationId);
        if (index != -1) {
          final oldApp = applicants[index];
          applicants[index] = ApplicationModel(
            id: oldApp.id,
            jobId: oldApp.jobId,
            candidateId: oldApp.candidateId,
            applicantEmail: oldApp.applicantEmail,
            applicantPhone: oldApp.applicantPhone,
            coverLetter: oldApp.coverLetter,
            status: newStatus,
            appliedAt: oldApp.appliedAt,
            candidate: oldApp.candidate,
            resumeFileName: oldApp.resumeFileName,
            job: oldApp.job,
          );
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated successfully.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    }
  }

  Future<void> openCandidateChat(ApplicationModel application) async {
    if (application.candidateId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Candidate chat is not available.')),
      );
      return;
    }

    try {
      await JobPortalStreamChatService.instance.connect();
      final channel = await JobPortalStreamChatService.instance
          .createOneToOneChannel(
        targetUserId: application.candidateId,
        jobId: widget.jobId,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            channelId: channel.channelId,
            channelType: channel.channelType,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> viewResume(String applicationId) async {
    try {
      final url = await jobService.getApplicationResume(widget.jobId, applicationId);
      if (url.isEmpty) {
        throw Exception('empty');
      }
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('launch failed');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open resume right now.')),
        );
      }
    }
  }

  String _friendlyError(String raw) {
    final message = raw.toLowerCase();
    if (message.contains('socket') || message.contains('network')) {
      return 'No internet connection.';
    }
    if (message.contains('401') || message.contains('unauthorized')) {
      return 'Your session has expired. Please log in again.';
    }
    return 'Something went wrong. Please try again.';
  }

  String _formatAppliedDate(String rawDate) {
    try {
      final date = DateTime.parse(rawDate).toLocal();
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'Date unavailable';
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange.withValues(alpha: 0.15);
      case 'REVIEWED':
        return Colors.blue.withValues(alpha: 0.15);
      case 'SHORTLISTED':
        return Colors.green.withValues(alpha: 0.15);
      case 'REJECTED':
        return Colors.red.withValues(alpha: 0.12);
      default:
        return AppColors.borderLight;
    }
  }

  Color _statusText(String status) {
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
        return AppColors.textSecondary;
    }
  }

  List<ApplicationModel> _byStatus(String status) {
    return applicants.where((app) => app.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = _byStatus('PENDING');
    final reviewed = _byStatus('REVIEWED');
    final shortlisted = _byStatus('SHORTLISTED');
    final rejected = _byStatus('REJECTED');

    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      appBar: AppBar(
        title: Text(widget.jobTitle),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _friendlyError(errorMessage!),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppButton(
                          label: 'Retry',
                          onPressed: fetchApplicants,
                          expanded: false,
                        ),
                      ],
                    ),
                  ),
                )
              : applicants.isEmpty
                  ? Center(
                      child: Text(
                        'No applicants found yet.',
                        style: theme.textTheme.bodyLarge,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: fetchApplicants,
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        children: [
                          _ApplicantSection(
                            title: 'New Applicants',
                            count: pending.length,
                            items: pending,
                            statusBg: _statusBg,
                            statusText: _statusText,
                            onViewResume: viewResume,
                            onMessageCandidate: openCandidateChat,
                            onUpdateStatus: updateStatus,
                            formatDate: _formatAppliedDate,
                          ),
                          _ApplicantSection(
                            title: 'Reviewed',
                            count: reviewed.length,
                            items: reviewed,
                            statusBg: _statusBg,
                            statusText: _statusText,
                            onViewResume: viewResume,
                            onMessageCandidate: openCandidateChat,
                            onUpdateStatus: updateStatus,
                            formatDate: _formatAppliedDate,
                          ),
                          _ApplicantSection(
                            title: 'Shortlisted',
                            count: shortlisted.length,
                            items: shortlisted,
                            statusBg: _statusBg,
                            statusText: _statusText,
                            onViewResume: viewResume,
                            onMessageCandidate: openCandidateChat,
                            onUpdateStatus: updateStatus,
                            formatDate: _formatAppliedDate,
                          ),
                          _ApplicantSection(
                            title: 'Rejected',
                            count: rejected.length,
                            items: rejected,
                            statusBg: _statusBg,
                            statusText: _statusText,
                            onViewResume: viewResume,
                            onMessageCandidate: openCandidateChat,
                            onUpdateStatus: updateStatus,
                            formatDate: _formatAppliedDate,
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _ApplicantSection extends StatelessWidget {
  final String title;
  final int count;
  final List<ApplicationModel> items;
  final Color Function(String) statusBg;
  final Color Function(String) statusText;
  final Future<void> Function(String) onViewResume;
  final Future<void> Function(ApplicationModel) onMessageCandidate;
  final Future<void> Function(String, String) onUpdateStatus;
  final String Function(String) formatDate;

  const _ApplicantSection({
    required this.title,
    required this.count,
    required this.items,
    required this.statusBg,
    required this.statusText,
    required this.onViewResume,
    required this.onMessageCandidate,
    required this.onUpdateStatus,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: '$title ($count)'),
          const SizedBox(height: AppSpacing.md),
          ...items.map((app) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: AppShadows.soft(),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            app.candidate.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(
                            app.status,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: statusText(app.status),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          backgroundColor: statusBg(app.status),
                          side: BorderSide.none,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      app.applicantEmail?.trim().isNotEmpty == true
                          ? app.applicantEmail!
                          : app.candidate.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if ((app.applicantPhone ?? app.candidate.phone).trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        app.applicantPhone?.trim().isNotEmpty == true
                            ? app.applicantPhone!
                            : app.candidate.phone,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Applied on ${formatDate(app.appliedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if ((app.coverLetter ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        app.coverLetter!,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        AppButton(
                          label: 'View CV',
                          onPressed: () => onViewResume(app.id),
                          leadingIcon: Icons.description_outlined,
                          expanded: false,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: () => onMessageCandidate(app),
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          label: const Text('Message'),
                        ),
                        const Spacer(),
                        DropdownButton<String>(
                          value: app.status,
                          underline: const SizedBox.shrink(),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.primary,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                            DropdownMenuItem(value: 'REVIEWED', child: Text('Reviewed')),
                            DropdownMenuItem(value: 'SHORTLISTED', child: Text('Shortlisted')),
                            DropdownMenuItem(value: 'REJECTED', child: Text('Rejected')),
                          ],
                          onChanged: (newStatus) {
                            if (newStatus != null && newStatus != app.status) {
                              onUpdateStatus(app.id, newStatus);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
