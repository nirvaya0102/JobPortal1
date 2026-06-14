import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radii.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/candidate_footer.dart';
import '../../applications/screens/apply_job_screen.dart';
import '../models/job_model.dart';
import '../services/job_service.dart';
import '../services/saved_jobs_service.dart';
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


List<String> _extractSkills(String description) {
  final text = description.toLowerCase();

  final skills = <String>[];

  final knownSkills = {
    'figma': 'Figma',
    'ui': 'UI Design',
    'ux': 'UX Research',
    'flutter': 'Flutter',
    'dart': 'Dart',
    'react': 'React',
    'next': 'Next.js',
    'node': 'Node.js',
    'javascript': 'JavaScript',
    'typescript': 'TypeScript',
    'python': 'Python',
    'java': 'Java',
    'sql': 'SQL',
    'photoshop': 'Photoshop',
    'illustrator': 'Illustrator',
    'communication': 'Communication',
  };

  knownSkills.forEach((key, value) {
    if (text.contains(key)) {
      skills.add(value);
    }
  });

  if (skills.isEmpty) {
    return ['Communication', 'Teamwork'];
  }

  return skills.take(6).toList();
}
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
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = 'Something went wrong. Please try again.';
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
        'Strong communication and teamwork skills.',
        'Experience with modern tools and workflows.',
        'Ability to solve problems with user-focused thinking.',
        'Ownership and accountability for quality delivery.',
      ];
    }

    return lines.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFF),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFF),
        appBar: AppBar(
          title: const Text('Job Details'),
          backgroundColor: const Color(0xFFF8FAFF),
          surfaceTintColor: Colors.transparent,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.danger,
              ),
            ),
          ),
        ),
      );
    }

    if (job == null) {
      return const Scaffold(
        body: Center(child: Text('Job not found')),
      );
    }

    final title = job!.title.trim();
    final company = (job!.companyName ?? 'Unknown Company').trim();
    final location = (job!.location ?? 'Location not available').trim();
    final salary = (job!.salary ?? 'Negotiable').trim();
    final jobType = (job!.type ?? 'Full-time').trim();
    final description = (job!.description ?? '').trim();
    final requirements = _requirementsFromDescription(description);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primary,
        title: const Text(
          'Job Details',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF111442),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 175),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroJobCard(
              title: title,
              company: company,
              location: location,
              salary: salary,
              jobType: jobType,
            ),

            const SizedBox(height: 16),

            Row(
              children:  [
                Expanded(
                  child: _SmallInfoCard(
                    title: 'Applicants',
                            value: '${job!.applicantsCount ?? 0}',
                            icon: Icons.people_alt_outlined,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _SmallInfoCard(
                      title: 'Status',
                            value: job!.status,
                            icon: Icons.work_outline,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            Text(
              'Required Skills',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF111442),
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _extractSkills(description)
                  .map((skill) => _SkillChip(skill))
                  .toList(),
            ),

            const SizedBox(height: 18),

            _DetailCard(
              title: 'Job Description',
              icon: Icons.description_outlined,
              child: Text(
                description.isNotEmpty
                    ? description
                    : 'No job description available.',
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
                                color: Color(0xFF22C55E),
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



            const SizedBox(height: AppSpacing.md),

            _DetailCard(
              title: 'About Company',
              icon: Icons.apartment_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EEFF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.business_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          company,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF262A4A),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

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
                      const Icon(
                        Icons.group_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '50-200 Employees',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  Row(
                    children: [
                      const Icon(
                        Icons.public,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'www.${company.toLowerCase().replaceAll(' ', '')}.com',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
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
              boxShadow: AppShadows.soft(),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isSaved
                          ? const Color(0xFFE8EEFF)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSaved
                            ? AppColors.primary
                            : AppColors.borderLight,
                      ),
                    ),
                    child: IconButton(
                      onPressed: _toggleSaveJob,
                      icon: Icon(
                        isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 22,
                        color: isSaved
                            ? AppColors.primary
                            : const Color(0xFF4B5563),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  Expanded(
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: AppButton(
                        label: 'Apply Now',
                        leadingIcon: Icons.arrow_forward_rounded,
                        onPressed: _openApply,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          CandidateFooter(
            currentIndex: widget.currentIndex,
            onTap: _goToTab,
          ),
        ],
      ),
    );
  }
}

class _HeroJobCard extends StatelessWidget {
  final String title;
  final String company;
  final String location;
  final String salary;
  final String jobType;

  const _HeroJobCard({
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.jobType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF070B66),
            Color(0xFF172BA8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF070B66).withOpacity(.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -35,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.08),
              ),
            ),
          ),
          Positioned(
            right: 35,
            bottom: -45,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.business_center_rounded,
                      color: Color(0xFF070B66),
                      size: 32,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.15),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: Colors.white.withOpacity(.25),
                      ),
                    ),
                    child: const Text(
                      'HIRING NOW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .4,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                company,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 18),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroChip(
                    icon: Icons.location_on_outlined,
                    text: location,
                  ),
                  _HeroChip(
                    icon: Icons.schedule_rounded,
                    text: jobType,
                  ),
                  _HeroChip(
                    icon: Icons.account_balance_wallet_outlined,
                    text: salary,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.15),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: Colors.white.withOpacity(.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SmallInfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111442),
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF747891),
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

class _SkillChip extends StatelessWidget {
  final String text;

  const _SkillChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEFF),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFD8E1FF)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF172BA8),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String text;

  const _BenefitRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(
            Icons.done_rounded,
            size: 17,
            color: Color(0xFF22C55E),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF4A4D68),
                    height: 1.4,
                  ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EAF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF111442),
                      fontWeight: FontWeight.w900,
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