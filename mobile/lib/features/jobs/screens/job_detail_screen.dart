import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radii.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/candidate_footer.dart';
import '../../applications/screens/apply_job_screen.dart';
import '../models/job_model.dart';
import '../services/saved_jobs_service.dart';
import '../services/job_service.dart';
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
  bool isSaved = false;
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
      final saved = await SavedJobsService.isJobSaved(widget.jobId);

      if (!mounted) return;
      setState(() {
        job = result;
        isSaved = saved;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Something went wrong. Please try again.';
      });
    }
    
    if (mounted) {
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

  void _openApply() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApplyJobScreen(
          jobId: widget.jobId,
          currentIndex: widget.currentIndex,
        ),
      ),
    );
  }

  Future<void> _toggleSaveJob() async {
    if (job == null) return;
    final savedNow = await SavedJobsService.toggleSaved(job!);
    if (!mounted) return;
    setState(() {
      isSaved = savedNow;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          savedNow ? 'Job saved successfully.' : 'Job removed from saved list.',
        ),
      ),
    );
  }

  List<String> _requirementsFromDescription(String description) {
    final lines = description
        .split(RegExp(r'[\n\.]'))
        .map((e) => e.trim())
        .where((e) => e.length > 18)
        .toList();

    if (lines.isEmpty) {
      return [
        'Strong communication skills and collaboration mindset.',
        'Experience with relevant tools and modern workflows.',
        'Ability to solve problems with user-focused thinking.',
        'Ownership and accountability for high-quality delivery.',
      ];
    }

    return lines.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.danger),
            ),
          ),
        ),
      );
    }

    if (job == null) {
      return const Scaffold(body: Center(child: Text('Job not found')));
    }

    final title = job!.title.trim();
    final company = (job!.companyName ?? 'Unknown Company').trim();
    final location = (job!.location ?? 'Location not available').trim();
    final salary = (job!.salary ?? 'Negotiable').trim();
    final jobType = (job!.type ?? 'Full-time').trim();
    final description = (job!.description ?? '').trim();
    final requirements = _requirementsFromDescription(description);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F4F8),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: IconButton(
                      onPressed: _toggleSaveJob,
                      icon: Icon(
                        isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 20,
                        color: isSaved ? AppColors.primary : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: 'Apply Now',
                      leadingIcon: Icons.arrow_forward_rounded,
                      onPressed: _openApply,
                    ),
                  ),
                ],
              ),
            ),
          ),
          CandidateFooter(currentIndex: widget.currentIndex, onTap: _goToTab),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 170),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: AppShadows.soft(),
                    ),
                    child: const Icon(Icons.work_outline_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E2140),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    company,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _MetaPill(icon: Icons.schedule_rounded, text: jobType),
                      _MetaPill(icon: Icons.account_balance_wallet_outlined, text: salary),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _DetailCard(
              title: 'Job Description',
              icon: Icons.description_outlined,
              child: Text(
                description.isNotEmpty ? description : 'No description available.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF4A4D68),
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _DetailCard(
              title: 'Requirements',
              icon: Icons.check_circle_outline_rounded,
              child: Column(
                children: requirements
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Color(0xFF41A86C),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                item,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF4A4D68),
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _DetailCard(
              title: 'About Company',
              icon: Icons.apartment_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF262A4A),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'This company is focused on delivering high-quality work with modern systems and a strong team culture.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF4A4D68),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Icon(Icons.group_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '50-200 Employees',
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(Icons.public, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'www.$company.com'.toLowerCase().replaceAll(' ', ''),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFECEBFA),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF2F2E84)),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF2F2E84),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DetailCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEDF2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF23265C)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF23265C),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
