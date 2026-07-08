import 'package:flutter/material.dart';

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
import 'resume_preview_screen.dart';

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
  final Set<String> openingResumeIds = {};
  final Set<String> openingChatIds = {};
  final Set<String> updatingStatusIds = {};

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
            resumeUrl: oldApp.resumeUrl,
            resumeFileName: oldApp.resumeFileName,
            resumeFileType: oldApp.resumeFileType,
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
      _showSnack('Candidate chat is not available.');
      return;
    }

    try {
      setState(() => openingChatIds.add(application.id));
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
      _showSnack(_chatError(e));
    } finally {
      if (mounted) {
        setState(() => openingChatIds.remove(application.id));
      }
    }
  }

  Future<void> viewResume(ApplicationModel application) async {
    try {
      setState(() => openingResumeIds.add(application.id));
      var url = application.resumeUrl?.trim() ?? application.candidate.resumeUrl?.trim() ?? '';

      if (url.isEmpty) {
        url = await jobService.getApplicationResume(widget.jobId, application.id);
      }

      if (url.trim().isEmpty) {
        _showSnack('No CV uploaded by this candidate.');
        return;
      }

      final uri = Uri.tryParse(url);
      if (uri == null ||
          !uri.hasScheme ||
          !(uri.scheme == 'http' || uri.scheme == 'https')) {
        _showSnack('Invalid CV URL.');
        return;
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResumePreviewScreen(
            resumeUrl: url,
            candidateName: application.candidate.name.trim().isEmpty
                ? 'Candidate'
                : application.candidate.name.trim(),
            fileName: application.resumeFileName ??
                application.candidate.resumeFileName,
            fileType: application.resumeFileType ??
                application.candidate.resumeFileType,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString().toLowerCase();
      if (raw.contains('resume not found') || raw.contains('not found')) {
        _showSnack('No CV uploaded by this candidate.');
      } else if (raw.contains('401') || raw.contains('unauthorized')) {
        _showSnack('Your session has expired. Please log in again.');
      } else if (raw.contains('socket') || raw.contains('network')) {
        _showSnack('No internet connection.');
      } else {
        _showSnack('Unable to open CV right now.');
      }
    } finally {
      if (mounted) setState(() => openingResumeIds.remove(application.id));
    }
  }

  Future<void> _updateStatusWithLoading(
    String applicationId,
    String newStatus,
  ) async {
    setState(() => updatingStatusIds.add(applicationId));
    try {
      await updateStatus(applicationId, newStatus);
    } finally {
      if (mounted) setState(() => updatingStatusIds.remove(applicationId));
    }
  }

  String _chatError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    final lower = message.toLowerCase();
    if (lower.contains('token')) return 'Chat token missing.';
    if (lower.contains('401') || lower.contains('unauthorized')) {
      return 'Your session has expired. Please log in again.';
    }
    if (lower.contains('socket') || lower.contains('network')) {
      return 'No internet connection.';
    }
    if (lower.contains('stream') || lower.contains('chat')) {
      return message;
    }
    return 'Channel creation failed.';
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                            onUpdateStatus: _updateStatusWithLoading,
                            formatDate: _formatAppliedDate,
                            openingResumeIds: openingResumeIds,
                            openingChatIds: openingChatIds,
                            updatingStatusIds: updatingStatusIds,
                          ),
                          _ApplicantSection(
                            title: 'Reviewed',
                            count: reviewed.length,
                            items: reviewed,
                            statusBg: _statusBg,
                            statusText: _statusText,
                            onViewResume: viewResume,
                            onMessageCandidate: openCandidateChat,
                            onUpdateStatus: _updateStatusWithLoading,
                            formatDate: _formatAppliedDate,
                            openingResumeIds: openingResumeIds,
                            openingChatIds: openingChatIds,
                            updatingStatusIds: updatingStatusIds,
                          ),
                          _ApplicantSection(
                            title: 'Shortlisted',
                            count: shortlisted.length,
                            items: shortlisted,
                            statusBg: _statusBg,
                            statusText: _statusText,
                            onViewResume: viewResume,
                            onMessageCandidate: openCandidateChat,
                            onUpdateStatus: _updateStatusWithLoading,
                            formatDate: _formatAppliedDate,
                            openingResumeIds: openingResumeIds,
                            openingChatIds: openingChatIds,
                            updatingStatusIds: updatingStatusIds,
                          ),
                          _ApplicantSection(
                            title: 'Rejected',
                            count: rejected.length,
                            items: rejected,
                            statusBg: _statusBg,
                            statusText: _statusText,
                            onViewResume: viewResume,
                            onMessageCandidate: openCandidateChat,
                            onUpdateStatus: _updateStatusWithLoading,
                            formatDate: _formatAppliedDate,
                            openingResumeIds: openingResumeIds,
                            openingChatIds: openingChatIds,
                            updatingStatusIds: updatingStatusIds,
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
  final Future<void> Function(ApplicationModel) onViewResume;
  final Future<void> Function(ApplicationModel) onMessageCandidate;
  final Future<void> Function(String, String) onUpdateStatus;
  final String Function(String) formatDate;
  final Set<String> openingResumeIds;
  final Set<String> openingChatIds;
  final Set<String> updatingStatusIds;

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
    required this.openingResumeIds,
    required this.openingChatIds,
    required this.updatingStatusIds,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: '$title ($count)'),
          const SizedBox(height: AppSpacing.md),
          ...items.map(
            (app) => _ApplicantCard(
              application: app,
              statusBg: statusBg,
              statusText: statusText,
              onViewResume: onViewResume,
              onMessageCandidate: onMessageCandidate,
              onUpdateStatus: onUpdateStatus,
              formatDate: formatDate,
              openingResume: openingResumeIds.contains(app.id),
              openingChat: openingChatIds.contains(app.id),
              updatingStatus: updatingStatusIds.contains(app.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  final ApplicationModel application;
  final Color Function(String) statusBg;
  final Color Function(String) statusText;
  final Future<void> Function(ApplicationModel) onViewResume;
  final Future<void> Function(ApplicationModel) onMessageCandidate;
  final Future<void> Function(String, String) onUpdateStatus;
  final String Function(String) formatDate;
  final bool openingResume;
  final bool openingChat;
  final bool updatingStatus;

  const _ApplicantCard({
    required this.application,
    required this.statusBg,
    required this.statusText,
    required this.onViewResume,
    required this.onMessageCandidate,
    required this.onUpdateStatus,
    required this.formatDate,
    required this.openingResume,
    required this.openingChat,
    required this.updatingStatus,
  });

  String get _name {
    final value = application.candidate.name.trim();
    return value.isEmpty ? 'Candidate' : value;
  }

  String get _email {
    final applicantEmail = application.applicantEmail?.trim();
    if (applicantEmail != null && applicantEmail.isNotEmpty) {
      return applicantEmail;
    }
    return application.candidate.email.trim().isEmpty
        ? 'Email not provided'
        : application.candidate.email.trim();
  }

  String get _phone {
    final applicantPhone = application.applicantPhone?.trim();
    if (applicantPhone != null && applicantPhone.isNotEmpty) {
      return applicantPhone;
    }
    return application.candidate.phone.trim().isEmpty
        ? 'Phone not provided'
        : application.candidate.phone.trim();
  }

  bool get _hasResume {
    final applicationResume = application.resumeUrl?.trim();
    final profileResume = application.candidate.resumeUrl?.trim();
    return (applicationResume != null && applicationResume.isNotEmpty) ||
        (profileResume != null && profileResume.isNotEmpty) ||
        (application.resumeFileName?.trim().isNotEmpty ?? false) ||
        (application.candidate.resumeFileName?.trim().isNotEmpty ?? false);
  }

  String get _resumeLabel {
    final fileName = application.resumeFileName?.trim();
    if (fileName != null && fileName.isNotEmpty) return fileName;
    final profileFileName = application.candidate.resumeFileName?.trim();
    if (profileFileName != null && profileFileName.isNotEmpty) {
      return profileFileName;
    }
    return _hasResume ? 'CV available' : 'No CV uploaded';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverLetter = application.coverLetter?.trim() ?? '';

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
                _InitialsAvatar(name: _name),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _MetaChip(
                            icon: Icons.email_outlined,
                            label: _email,
                          ),
                          _MetaChip(
                            icon: Icons.phone_outlined,
                            label: _phone,
                          ),
                          _MetaChip(
                            icon: Icons.calendar_today_outlined,
                            label: 'Applied ${formatDate(application.appliedAt)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatusChip(
                  status: application.status,
                  bg: statusBg(application.status),
                  textColor: statusText(application.status),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Text(
                coverLetter.isEmpty
                    ? 'No cover letter provided.'
                    : coverLetter,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: coverLetter.isEmpty
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  _hasResume
                      ? Icons.description_outlined
                      : Icons.description_outlined,
                  size: 18,
                  color: _hasResume ? AppColors.primary : AppColors.textHint,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    _resumeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _hasResume
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 390;
                final viewCvButton = _ActionButton(
                  label: openingResume ? 'Opening...' : 'View CV',
                  icon: Icons.description_outlined,
                  loading: openingResume,
                  onPressed: openingResume
                      ? null
                      : () => onViewResume(application),
                );
                final messageButton = _ActionButton(
                  label: openingChat ? 'Opening...' : 'Message',
                  icon: Icons.chat_bubble_outline_rounded,
                  loading: openingChat,
                  outlined: true,
                  onPressed: openingChat
                      ? null
                      : () => onMessageCandidate(application),
                );
                final statusPicker = _StatusPicker(
                  status: application.status,
                  disabled: updatingStatus,
                  onChanged: (newStatus) {
                    if (newStatus != application.status) {
                      onUpdateStatus(application.id, newStatus);
                    }
                  },
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      viewCvButton,
                      const SizedBox(height: AppSpacing.sm),
                      messageButton,
                      const SizedBox(height: AppSpacing.sm),
                      statusPicker,
                    ],
                  );
                }

                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(width: 126, child: viewCvButton),
                    SizedBox(width: 132, child: messageButton),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 150,
                        maxWidth: 190,
                      ),
                      child: statusPicker,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String name;

  const _InitialsAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryBlue],
        ),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Text(
        _initials(name),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FF),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Color bg;
  final Color textColor;

  const _StatusChip({
    required this.status,
    required this.bg,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool loading;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.outlined = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(icon, size: 18),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        ),
        child: child,
      );
    }

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      ),
      child: child,
    );
  }
}

class _StatusPicker extends StatelessWidget {
  final String status;
  final bool disabled;
  final ValueChanged<String> onChanged;

  const _StatusPicker({
    required this.status,
    required this.disabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: status,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
        DropdownMenuItem(value: 'REVIEWED', child: Text('Reviewed')),
        DropdownMenuItem(value: 'SHORTLISTED', child: Text('Shortlisted')),
        DropdownMenuItem(value: 'REJECTED', child: Text('Rejected')),
      ],
      onChanged: disabled
          ? null
          : (newStatus) {
              if (newStatus != null) onChanged(newStatus);
            },
    );
  }
}

String _initials(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return 'C';
  if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
  return '${words[0][0]}${words[1][0]}'.toUpperCase();
}
