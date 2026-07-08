import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radii.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_spacing.dart';
import '../../jobs/models/job_model.dart';
import '../services/admin_job_service.dart';

class AdminJobDetailScreen extends StatefulWidget {
  final JobModel job;

  const AdminJobDetailScreen({
    super.key,
    required this.job,
  });

  @override
  State<AdminJobDetailScreen> createState() => _AdminJobDetailScreenState();
}

class _AdminJobDetailScreenState extends State<AdminJobDetailScreen>
    with SingleTickerProviderStateMixin {
  final AdminJobService _adminJobService = AdminJobService();
  final TextEditingController _adminNotesController = TextEditingController();
  final TextEditingController _rejectionReasonController =
      TextEditingController();

  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  late JobModel job;

  bool saving = false;
  bool showRejectionReason = false;

  @override
  void initState() {
    super.initState();
    job = widget.job;
    _rejectionReasonController.text = job.rejectionReason ?? '';
    final animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _animationController = animationController;
    _fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _adminNotesController.dispose();
    _rejectionReasonController.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    final confirmed = await _showDecisionDialog(
      title: 'Approve this job?',
      message: 'Employer job will immediately become visible to candidates.',
      actionLabel: 'Approve',
      icon: Icons.verified_rounded,
      color: AppColors.success,
    );

    if (confirmed != true) return;
    await _runAction(() => _adminJobService.approveJob(job.id));
  }

  Future<void> _close() async {
    final confirmed = await _showDecisionDialog(
      title: 'Close this job?',
      message: 'This will stop future applications for this job.',
      actionLabel: 'Close Job',
      icon: Icons.lock_outline_rounded,
      color: AppColors.textSecondary,
    );

    if (confirmed != true) return;
    await _runAction(() => _adminJobService.closeJob(job.id));
  }

  Future<void> _reject() async {
    setState(() => showRejectionReason = true);

    final reason = await _showRejectDialog();
    if (reason == null) return;

    _rejectionReasonController.text = reason;
    await _runAction(
      () => _adminJobService.rejectJob(job.id, rejectionReason: reason),
    );
  }

  Future<bool?> _showDecisionDialog({
    required String title,
    required String message,
    required String actionLabel,
    required IconData icon,
    required Color color,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: color),
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showRejectDialog() {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          title: const Text('Reject this job?'),
          content: TextField(
            controller: _rejectionReasonController,
            maxLength: 500,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Rejection reason',
              hintText: 'Tell the employer what needs to be fixed...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.pop(context, _rejectionReasonController.text),
              icon: const Icon(Icons.close_rounded),
              label: const Text('Reject'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            ),
          ],
        );
      },
    );
  }

  Future<void> _runAction(Future<JobModel> Function() action) async {
    try {
      setState(() => saving = true);
      final updatedJob = await action();
      if (!mounted) return;
      setState(() => job = updatedJob);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job updated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _launchEmail(String? email) async {
    final cleanEmail = email?.trim();
    if (cleanEmail == null || cleanEmail.isEmpty) return;
    final uri = Uri(scheme: 'mailto', path: cleanEmail);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWebsite(String? website) async {
    final cleanWebsite = website?.trim();
    if (cleanWebsite == null || cleanWebsite.isEmpty) return;
    final uri = Uri.parse(
      cleanWebsite.startsWith('http') ? cleanWebsite : 'https://$cleanWebsite',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation ?? const AlwaysStoppedAnimation<double>(1),
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    0,
                  ),
                  child: _ReviewHeader(job: job),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  130,
                ),
                sliver: SliverList.list(
                  children: [
                    StatusBanner(job: job),
                    const SizedBox(height: AppSpacing.md),
                    JobHeroCard(job: job),
                    const SizedBox(height: AppSpacing.md),
                    EmployerCard(
                      job: job,
                      onTapEmail: () => _launchEmail(job.employerEmail),
                      onTapWebsite: () => _launchWebsite(job.companyWebsite),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    JobDescriptionCard(job: job),
                    const SizedBox(height: AppSpacing.md),
                    ModerationCard(
                      notesController: _adminNotesController,
                      rejectionReasonController: _rejectionReasonController,
                      showRejectionReason: showRejectionReason,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DecisionSummary(job: job),
                    const SizedBox(height: AppSpacing.md),
                    StatisticsRow(job: job),
                    const SizedBox(height: AppSpacing.md),
                    TimelineCard(job: job),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ActionBar(
        saving: saving,
        onReject: _reject,
        onClose: _close,
        onApprove: _approve,
      ),
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  final JobModel job;

  const _ReviewHeader({required this.job});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review Job',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '${statusLabel(job.status)} - Review and moderate employer job posting.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StatusBanner extends StatelessWidget {
  final JobModel job;

  const StatusBanner({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(job.status);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.95),
              color.withValues(alpha: 0.72),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          boxShadow: AppShadows.soft(),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(statusIcon(job.status), color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusLabel(job.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Submitted ${relativeDate(job.createdAt)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JobHeroCard extends StatelessWidget {
  final JobModel job;

  const JobHeroCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final company = nonEmpty(job.companyName, 'Company unavailable');
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CompanyAvatar(name: company, size: 58),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF172033),
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      company,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusPill(status: job.status),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              InfoChip(
                icon: Icons.account_balance_wallet_outlined,
                label: formatSalary(job),
              ),
              InfoChip(
                icon: Icons.location_on_outlined,
                label: nonEmpty(job.location, 'Location missing'),
              ),
              InfoChip(
                icon: Icons.work_outline_rounded,
                label: nonEmpty(job.type, 'Job type missing'),
              ),
              InfoChip(
                icon: Icons.groups_2_outlined,
                label: '${job.applicantsCount} applicants',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Posted ${relativeDate(job.createdAt)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EmployerCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTapEmail;
  final VoidCallback onTapWebsite;

  const EmployerCard({
    super.key,
    required this.job,
    required this.onTapEmail,
    required this.onTapWebsite,
  });

  @override
  Widget build(BuildContext context) {
    final employerName = nonEmpty(job.employerName, 'Employer unavailable');
    return _DashboardCard(
      title: 'Employer Information',
      icon: Icons.badge_outlined,
      child: Column(
        children: [
          Row(
            children: [
              CompanyAvatar(name: employerName, size: 48),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      nonEmpty(job.companyName, 'Company unavailable'),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DetailActionRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: nonEmpty(job.employerEmail, 'Not available'),
            onTap: job.employerEmail == null ? null : onTapEmail,
          ),
          DetailActionRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: 'Not available',
          ),
          DetailActionRow(
            icon: Icons.public_rounded,
            label: 'Website',
            value: nonEmpty(job.companyWebsite, 'Missing'),
            onTap: job.companyWebsite == null ? null : onTapWebsite,
          ),
          DetailActionRow(
            icon: Icons.location_city_outlined,
            label: 'Location',
            value: nonEmpty(job.companyLocation ?? job.location, 'Not set'),
          ),
        ],
      ),
    );
  }
}

class JobDescriptionCard extends StatelessWidget {
  final JobModel job;

  const JobDescriptionCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final description = job.description?.trim() ?? '';
    return _DashboardCard(
      title: 'Job Details',
      icon: Icons.description_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailSection(
            title: 'Job Description',
            content: description,
            emptyText: 'The employer has not added a full description yet.',
          ),
          DetailSection(
            title: 'Responsibilities',
            content: extractSentences(description, ['responsib', 'manage']),
            emptyText: 'Responsibilities are not clearly listed.',
          ),
          DetailSection(
            title: 'Requirements',
            content: extractSentences(description, ['require', 'skill', 'experience']),
            emptyText: 'Requirements are not clearly listed.',
          ),
          DetailSection(
            title: 'Benefits',
            content: extractSentences(description, ['benefit', 'allowance', 'bonus']),
            emptyText: 'Benefits are not mentioned.',
            bottomPadding: false,
          ),
        ],
      ),
    );
  }
}

class ModerationCard extends StatelessWidget {
  final TextEditingController notesController;
  final TextEditingController rejectionReasonController;
  final bool showRejectionReason;

  const ModerationCard({
    super.key,
    required this.notesController,
    required this.rejectionReasonController,
    required this.showRejectionReason,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Admin Review',
      icon: Icons.fact_check_outlined,
      child: Column(
        children: [
          TextField(
            controller: notesController,
            minLines: 4,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Write review notes...',
              filled: true,
              fillColor: const Color(0xFFF8FAFF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 240),
            crossFadeState: showRejectionReason
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: TextField(
                controller: rejectionReasonController,
                minLines: 3,
                maxLines: 5,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: 'Rejection Reason',
                  hintText: 'Optional reason for the employer...',
                  filled: true,
                  fillColor: const Color(0xFFFFFBFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DecisionSummary extends StatelessWidget {
  final JobModel job;

  const DecisionSummary({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final checks = [
      DecisionItem(
        ok: job.salaryMin != null || job.salaryMax != null,
        text: job.salaryMin != null || job.salaryMax != null
            ? 'Salary entered'
            : 'Salary missing',
      ),
      DecisionItem(
        ok: (job.location ?? '').trim().isNotEmpty,
        text: (job.location ?? '').trim().isNotEmpty
            ? 'Location provided'
            : 'Location missing',
      ),
      DecisionItem(
        ok: (job.description ?? '').trim().length >= 80,
        text: (job.description ?? '').trim().length >= 80
            ? 'Description looks detailed'
            : 'Description is too short',
      ),
      DecisionItem(
        ok: (job.companyWebsite ?? '').trim().isNotEmpty,
        text: (job.companyWebsite ?? '').trim().isNotEmpty
            ? 'Company website provided'
            : 'Company website missing',
      ),
      DecisionItem(
        ok: (job.employerEmail ?? '').trim().isNotEmpty,
        text: (job.employerEmail ?? '').trim().isNotEmpty
            ? 'Employer contact available'
            : 'Employer contact missing',
      ),
    ];

    return _DashboardCard(
      title: 'Decision Summary',
      icon: Icons.rule_folder_outlined,
      child: Column(
        children: checks.map((item) => _DecisionRow(item: item)).toList(),
      ),
    );
  }
}

class StatisticsRow extends StatelessWidget {
  final JobModel job;

  const StatisticsRow({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final cards = [
      StatCard(label: 'Applicants', value: '${job.applicantsCount}'),
      const StatCard(label: 'Views', value: '-'),
      const StatCard(label: 'Bookmarks', value: '-'),
      StatCard(label: 'Created', value: compactDate(job.createdAt)),
      const StatCard(label: 'Updated', value: '-'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final card in cards) ...[
            SizedBox(width: 132, child: card),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class TimelineCard extends StatelessWidget {
  final JobModel job;

  const TimelineCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final items = [
      TimelineItem(title: 'Created', subtitle: compactDate(job.createdAt), done: true),
      TimelineItem(
        title: 'Reviewed',
        subtitle: job.status == 'PENDING' ? 'Awaiting review' : 'Decision recorded',
        done: job.status != 'PENDING',
      ),
      TimelineItem(
        title: 'Approved',
        subtitle: job.status == 'APPROVED' ? 'Visible to candidates' : 'Not approved',
        done: job.status == 'APPROVED',
      ),
      TimelineItem(
        title: 'Rejected',
        subtitle: job.status == 'REJECTED' ? 'Sent back to employer' : 'Not rejected',
        done: job.status == 'REJECTED',
      ),
      TimelineItem(
        title: 'Closed',
        subtitle: job.status == 'CLOSED' ? 'Applications stopped' : 'Not closed',
        done: job.status == 'CLOSED',
      ),
    ];

    return _DashboardCard(
      title: 'Submission Timeline',
      icon: Icons.timeline_rounded,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            _TimelineRow(item: items[i], isLast: i == items.length - 1),
        ],
      ),
    );
  }
}

class ActionBar extends StatelessWidget {
  final bool saving;
  final VoidCallback onReject;
  final VoidCallback onClose;
  final VoidCallback onApprove;

  const ActionBar({
    super.key,
    required this.saving,
    required this.onReject,
    required this.onClose,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: AppShadows.medium(),
          border: const Border(top: BorderSide(color: AppColors.borderLight)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: saving ? null : onReject,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: saving ? null : onClose,
                icon: const Icon(Icons.lock_outline_rounded),
                label: const Text('Close'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: saving ? null : onApprove,
                icon: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: const Text('Approve'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final IconData? icon;

  const _DashboardCard({
    required this.child,
    this.title,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.soft(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(
                  title!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF172033),
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          child,
        ],
      ),
    );
  }
}

class CompanyAvatar extends StatelessWidget {
  final String name;
  final double size;

  const CompanyAvatar({
    super.key,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Text(
        initials(name),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FF),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: const Color(0xFFE2E8F6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF24324B),
            ),
          ),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String status;

  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class DetailActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const DetailActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Icon(icon, size: 19, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 78,
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: onTap == null ? const Color(0xFF172033) : AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailSection extends StatelessWidget {
  final String title;
  final String content;
  final String emptyText;
  final bool bottomPadding;

  const DetailSection({
    super.key,
    required this.title,
    required this.content,
    required this.emptyText,
    this.bottomPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasContent = content.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding ? AppSpacing.md : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: hasContent
                  ? const Color(0xFFF8FAFF)
                  : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: hasContent
                    ? AppColors.borderLight
                    : Colors.orange.withValues(alpha: 0.28),
              ),
            ),
            child: Text(
              hasContent ? content : emptyText,
              style: TextStyle(
                height: 1.5,
                color: hasContent
                    ? const Color(0xFF344054)
                    : Colors.orange.shade800,
                fontWeight: hasContent ? FontWeight.w500 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DecisionItem {
  final bool ok;
  final String text;

  const DecisionItem({
    required this.ok,
    required this.text,
  });
}

class _DecisionRow extends StatelessWidget {
  final DecisionItem item;

  const _DecisionRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.ok ? AppColors.success : Colors.orange;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            item.ok ? Icons.check_circle_rounded : Icons.warning_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              item.text,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class TimelineItem {
  final String title;
  final String subtitle;
  final bool done;

  const TimelineItem({
    required this.title,
    required this.subtitle,
    required this.done,
  });
}

class _TimelineRow extends StatelessWidget {
  final TimelineItem item;
  final bool isLast;

  const _TimelineRow({
    required this.item,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = item.done ? AppColors.primary : AppColors.borderLight;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: item.done ? AppColors.primary : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: item.done
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(width: 2, height: 42, color: AppColors.borderLight),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String nonEmpty(String? value, String fallback) {
  final clean = value?.trim();
  return clean == null || clean.isEmpty ? fallback : clean;
}

String initials(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return 'K';
  if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
  return '${words[0][0]}${words[1][0]}'.toUpperCase();
}

Color statusColor(String status) {
  return switch (status.toUpperCase()) {
    'APPROVED' => AppColors.success,
    'REJECTED' => AppColors.danger,
    'CLOSED' => const Color(0xFF475467),
    _ => const Color(0xFFD97706),
  };
}

IconData statusIcon(String status) {
  return switch (status.toUpperCase()) {
    'APPROVED' => Icons.check_circle_rounded,
    'REJECTED' => Icons.cancel_rounded,
    'CLOSED' => Icons.lock_rounded,
    _ => Icons.pending_actions_rounded,
  };
}

String statusLabel(String status) {
  return switch (status.toUpperCase()) {
    'APPROVED' => 'Approved',
    'REJECTED' => 'Rejected',
    'CLOSED' => 'Closed',
    _ => 'Pending Review',
  };
}

String formatSalary(JobModel job) {
  if (job.salaryMin != null && job.salaryMax != null) {
    return 'Rs ${formatNumber(job.salaryMin!)} - Rs ${formatNumber(job.salaryMax!)}';
  }
  if (job.salaryMin != null) return 'From Rs ${formatNumber(job.salaryMin!)}';
  if (job.salaryMax != null) return 'Up to Rs ${formatNumber(job.salaryMax!)}';
  return nonEmpty(job.salary, 'Negotiable');
}

String formatNumber(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return buffer.toString();
}

DateTime? parseDate(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

String relativeDate(String? value) {
  final date = parseDate(value);
  if (date == null) return 'recently';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hours ago';
  if (diff.inDays < 30) return '${diff.inDays} days ago';
  return compactDate(value);
}

String compactDate(String? value) {
  final date = parseDate(value);
  if (date == null) return '-';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String extractSentences(String description, List<String> keywords) {
  final parts = description
      .split(RegExp(r'[\n\.]'))
      .map((part) => part.trim())
      .where((part) => part.length > 16)
      .toList();
  final matches = parts
      .where(
        (part) => keywords.any((keyword) => part.toLowerCase().contains(keyword)),
      )
      .take(4)
      .toList();

  if (matches.isEmpty) return '';
  return matches.map((line) => '- $line').join('\n');
}
