import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radii.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/job_model.dart';
import '../services/saved_jobs_service.dart';

class CandidateFeaturedJobCarousel extends StatefulWidget {
  final List<JobModel> jobs;
  final ValueChanged<JobModel> onJobTap;

  const CandidateFeaturedJobCarousel({
    super.key,
    required this.jobs,
    required this.onJobTap,
  });

  @override
  State<CandidateFeaturedJobCarousel> createState() =>
      _CandidateFeaturedJobCarouselState();
}

class _CandidateFeaturedJobCarouselState
    extends State<CandidateFeaturedJobCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.88);
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.jobs.isEmpty) {
      return const _FeaturedEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 286,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.jobs.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final job = widget.jobs[index];
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  var scale = 1.0;
                  if (_controller.position.haveDimensions) {
                    final page = _controller.page ?? _currentPage.toDouble();
                    scale = (1 - (page - index).abs() * 0.04).clamp(0.96, 1.0);
                  }
                  return Transform.scale(scale: scale, child: child);
                },
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == widget.jobs.length - 1 ? 0 : 12,
                  ),
                  child: FeaturedJobCard(
                    job: job,
                    onTap: () => widget.onJobTap(job),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.jobs.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == index ? 24 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? AppColors.primaryBlue
                    : const Color(0xFFD3DCFF),
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class FeaturedJobCard extends StatefulWidget {
  final JobModel job;
  final VoidCallback onTap;

  const FeaturedJobCard({super.key, required this.job, required this.onTap});

  @override
  State<FeaturedJobCard> createState() => _FeaturedJobCardState();
}

class _FeaturedJobCardState extends State<FeaturedJobCard> {
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  @override
  void didUpdateWidget(covariant FeaturedJobCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.job.id != widget.job.id) {
      _loadSavedState();
    }
  }

  Future<void> _loadSavedState() async {
    final saved = await SavedJobsService.isJobSaved(widget.job.id);
    if (!mounted) return;
    setState(() => isSaved = saved);
  }

  Future<void> _toggleSaved() async {
    final savedNow = await SavedJobsService.toggleSaved(widget.job);
    if (!mounted) return;
    setState(() => isSaved = savedNow);
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final company = _nonEmpty(job.companyName, 'Confidential Company');
    final location = _nonEmpty(job.location, 'Remote / Flexible');
    final salary = _formatSalary(job);
    final type = _nonEmpty(job.type, 'Full-time');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: widget.onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B1B73), Color(0xFF1D4ED8)],
            ),
            boxShadow: AppShadows.medium(color: AppColors.primaryBlue),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -56,
                top: -58,
                child: _DecorCircle(size: 150, opacity: 0.08),
              ),
              Positioned(
                left: -54,
                bottom: -68,
                child: _DecorCircle(size: 130, opacity: 0.06),
              ),
              Positioned(
                right: 22,
                bottom: 26,
                child: _DecorCircle(size: 58, opacity: 0.045),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CompanyAvatar(
                          logoUrl: job.companyLogo,
                          companyName: company,
                        ),
                        const Spacer(),
                        const _FeaturedBadge(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      job.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      company,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        MetaChip(
                          icon: Icons.location_on_outlined,
                          text: location,
                        ),
                        MetaChip(icon: Icons.work_outline_rounded, text: type),
                        MetaChip(icon: Icons.payments_outlined, text: salary),
                        if (job.applicantsCount > 0)
                          MetaChip(
                            icon: Icons.groups_outlined,
                            text:
                                '${job.applicantsCount} ${job.applicantsCount == 1 ? 'Applicant' : 'Applicants'}',
                          ),
                        MetaChip(
                          icon: Icons.schedule_rounded,
                          text: _relativeTime(job.createdAt),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: widget.onTap,
                          iconAlignment: IconAlignment.end,
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 17,
                          ),
                          label: const Text('Apply Now'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primaryBlue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            minimumSize: const Size(0, 42),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadii.pill,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        _SaveButton(isSaved: isSaved, onPressed: _toggleSaved),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompanyAvatar extends StatelessWidget {
  final String? logoUrl;
  final String companyName;

  const CompanyAvatar({
    super.key,
    required this.logoUrl,
    required this.companyName,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initials(companyName);

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: _avatarColors(companyName),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: (logoUrl ?? '').trim().isNotEmpty
            ? Image.network(
                logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(child: _Initials(initials)),
              )
            : Center(child: _Initials(initials)),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String initials;

  const _Initials(this.initials);

  @override
  Widget build(BuildContext context) {
    return Text(
      initials,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 14,
      ),
    );
  }
}

class _FeaturedBadge extends StatelessWidget {
  const _FeaturedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: Color(0xFFFDE68A)),
          SizedBox(width: 4),
          Text(
            'Featured',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const MetaChip({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 154),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.92)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isSaved;
  final VoidCallback onPressed;

  const _SaveButton({required this.isSaved, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: IconButton(
        key: ValueKey(isSaved),
        tooltip: isSaved ? 'Unsave job' : 'Save job',
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.14),
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
          fixedSize: const Size(42, 42),
        ),
        icon: Icon(
          isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          size: 21,
        ),
      ),
    );
  }
}

class _FeaturedEmptyState extends StatelessWidget {
  const _FeaturedEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.soft(),
      ),
      child: const Center(
        child: Text(
          'No featured jobs available',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _DecorCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

String _nonEmpty(String? value, String fallback) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _initials(String value) {
  final parts = value
      .split(RegExp(r'\s+'))
      .where((part) => part.trim().isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'C';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}

List<Color> _avatarColors(String value) {
  final palettes = [
    [const Color(0xFF2563EB), const Color(0xFF38BDF8)],
    [const Color(0xFF047857), const Color(0xFF34D399)],
    [const Color(0xFF4338CA), const Color(0xFF818CF8)],
    [const Color(0xFF0F766E), const Color(0xFF5EEAD4)],
    [const Color(0xFFBE123C), const Color(0xFFFB7185)],
  ];
  final index =
      value.codeUnits.fold<int>(0, (sum, unit) => sum + unit) % palettes.length;
  return palettes[index];
}

String _formatSalary(JobModel job) {
  if (job.salaryMin != null && job.salaryMax != null) {
    return 'NPR ${_compactCurrency(job.salaryMin!)} – ${_compactCurrency(job.salaryMax!)}';
  }
  if (job.salaryMin != null) {
    return 'From NPR ${_compactCurrency(job.salaryMin!)}';
  }
  if (job.salaryMax != null) {
    return 'Up to NPR ${_compactCurrency(job.salaryMax!)}';
  }

  final salary = job.salary?.trim() ?? '';
  return salary.isEmpty ? 'Negotiable' : salary;
}

String _compactCurrency(int amount) {
  if (amount >= 1000 && amount % 1000 == 0) {
    return '${amount ~/ 1000}k';
  }
  if (amount >= 1000) {
    final value = amount / 1000;
    final text = value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
    return '${text}k';
  }
  return amount.toString();
}

String _relativeTime(String? rawDate) {
  if (rawDate == null || rawDate.trim().isEmpty) return 'Recently';
  final date = DateTime.tryParse(rawDate)?.toLocal();
  if (date == null) return 'Recently';

  final difference = DateTime.now().difference(date);
  if (difference.inDays <= 0) return 'Today';
  if (difference.inDays == 1) return 'Yesterday';
  if (difference.inDays < 7) return '${difference.inDays} days ago';
  if (difference.inDays < 14) return '1 week ago';
  if (difference.inDays < 30) {
    return '${(difference.inDays / 7).floor()} weeks ago';
  }
  return '${(difference.inDays / 30).floor()} months ago';
}
