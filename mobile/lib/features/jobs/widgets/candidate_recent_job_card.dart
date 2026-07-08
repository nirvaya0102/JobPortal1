import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radii.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/job_model.dart';
import '../services/saved_jobs_service.dart';

class CandidateRecentJobCard extends StatefulWidget {
  final JobModel job;
  final VoidCallback onTap;

  const CandidateRecentJobCard({
    super.key,
    required this.job,
    required this.onTap,
  });

  @override
  State<CandidateRecentJobCard> createState() => _CandidateRecentJobCardState();
}

class _CandidateRecentJobCardState extends State<CandidateRecentJobCard> {
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  @override
  void didUpdateWidget(covariant CandidateRecentJobCard oldWidget) {
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
    final type = _nonEmpty(job.type, 'Full-time');
    final salary = _nonEmpty(job.salary, 'Negotiable');
    final status = _nonEmpty(job.status, 'APPROVED');

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.98, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          onTap: widget.onTap,
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: AppShadows.medium(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CompanyAvatar(
                      logoUrl: job.companyLogo,
                      companyName: company,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag: 'job-title-${job.id}',
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                job.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  height: 1.18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            company,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: IconButton(
                        key: ValueKey(isSaved),
                        tooltip: isSaved ? 'Unsave job' : 'Save job',
                        onPressed: _toggleSaved,
                        icon: Icon(
                          isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: isSaved
                              ? AppColors.primaryBlue
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _InfoPill(icon: Icons.location_on_outlined, text: location),
                    _InfoPill(icon: Icons.work_outline_rounded, text: type),
                    _InfoPill(icon: Icons.payments_outlined, text: salary),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _MetaPill(
                            icon: Icons.groups_outlined,
                            text: '${job.applicantsCount} applicants',
                          ),
                          _MetaPill(
                            icon: Icons.schedule_rounded,
                            text: _relativeTime(job.createdAt),
                          ),
                          _StatusChip(label: status),
                          _StatusChip(label: type),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: widget.onTap,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('View Details'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanyAvatar extends StatelessWidget {
  final String? logoUrl;
  final String companyName;

  const _CompanyAvatar({required this.logoUrl, required this.companyName});

  @override
  Widget build(BuildContext context) {
    final initials = _initials(companyName);

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _avatarColors(companyName),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft(color: AppColors.primaryBlue),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
        fontSize: 15,
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FF),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryBlue),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;

  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: colors.$2,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
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
    [const Color(0xFF1D3FAF), const Color(0xFF4F7CFF)],
    [const Color(0xFF047857), const Color(0xFF34D399)],
    [const Color(0xFF9333EA), const Color(0xFFC084FC)],
    [const Color(0xFFB45309), const Color(0xFFF59E0B)],
    [const Color(0xFFBE123C), const Color(0xFFFB7185)],
  ];
  final index = value.codeUnits.fold<int>(0, (sum, unit) => sum + unit) %
      palettes.length;
  return palettes[index];
}

(Color, Color) _statusColors(String value) {
  final normalized = value.toLowerCase().replaceAll('-', ' ');
  if (normalized.contains('open')) {
    return (const Color(0xFFEAF7EE), AppColors.success);
  }
  if (normalized.contains('remote')) {
    return (const Color(0xFFEFF4FF), AppColors.primaryBlue);
  }
  if (normalized.contains('part')) {
    return (const Color(0xFFFFF7ED), const Color(0xFFC2410C));
  }
  if (normalized.contains('intern')) {
    return (const Color(0xFFF3E8FF), const Color(0xFF7E22CE));
  }
  return (const Color(0xFFF4F7FF), AppColors.textSecondary);
}

String _relativeTime(String? rawDate) {
  if (rawDate == null || rawDate.trim().isEmpty) return 'Recently';
  final date = DateTime.tryParse(rawDate)?.toLocal();
  if (date == null) return 'Recently';

  final now = DateTime.now();
  final difference = now.difference(date);
  if (difference.inDays <= 0) return 'Today';
  if (difference.inDays == 1) return 'Yesterday';
  if (difference.inDays < 7) return '${difference.inDays} days ago';
  if (difference.inDays < 14) return '1 week ago';
  if (difference.inDays < 30) {
    return '${(difference.inDays / 7).floor()} weeks ago';
  }
  return '${(difference.inDays / 30).floor()} months ago';
}
