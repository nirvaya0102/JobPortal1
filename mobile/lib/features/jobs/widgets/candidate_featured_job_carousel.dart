import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radii.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/job_model.dart';

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
          height: 214,
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
                  child: _FeaturedCard(
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
              width: _currentPage == index ? 18 : 7,
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

class _FeaturedCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;

  const _FeaturedCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = job.title;
    final company = _nonEmpty(job.companyName, 'Confidential Company');
    final salary = _nonEmpty(job.salary, 'Negotiable');
    final type = _nonEmpty(job.type, 'Full-time');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
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
                right: -36,
                top: -42,
                child: _DecorCircle(size: 132, opacity: 0.12),
              ),
              Positioned(
                right: 46,
                bottom: -72,
                child: _DecorCircle(size: 150, opacity: 0.08),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _FeaturedAvatar(
                          logoUrl: job.companyLogo,
                          companyName: company,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: const Text(
                            'Featured',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      title,
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
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _FeaturedPill(
                            icon: Icons.payments_outlined,
                            text: salary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _FeaturedPill(
                          icon: Icons.work_outline_rounded,
                          text: type,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 38,
                      child: FilledButton(
                        onPressed: onTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                        ),
                        child: const Text('Apply'),
                      ),
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

class _FeaturedAvatar extends StatelessWidget {
  final String? logoUrl;
  final String companyName;

  const _FeaturedAvatar({required this.logoUrl, required this.companyName});

  @override
  Widget build(BuildContext context) {
    final initials = _initials(companyName);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
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
      ),
    );
  }
}

class _FeaturedPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeaturedPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
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
