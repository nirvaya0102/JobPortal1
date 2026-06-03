import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/storage/user_storage.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../models/job_model.dart';
import '../providers/candidate_dashboard_provider.dart';
import '../screens/job_detail_screen.dart';
import '../services/job_service.dart';
import '../widgets/candidate_category_chips.dart';
import '../widgets/candidate_featured_job_carousel.dart';
import '../widgets/candidate_recent_job_card.dart';

class CandidateDashboardScreen extends StatefulWidget {
  final VoidCallback? onOpenApplications;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenJobs;

  const CandidateDashboardScreen({
    super.key,
    this.onOpenApplications,
    this.onOpenProfile,
    this.onOpenJobs,
  });

  @override
  State<CandidateDashboardScreen> createState() =>
      _CandidateDashboardScreenState();
}

class _CandidateDashboardScreenState extends State<CandidateDashboardScreen> {
  final _jobService = JobService();
  final _authService = AuthService();
  final _searchController = TextEditingController();
  final _provider = CandidateDashboardProvider();

  bool loading = false;
  String? errorMessage;
  List<JobModel> jobs = [];
  String? name;
  String? location;

  @override
  void initState() {
    super.initState();
    // PERF-001: Load header and jobs in parallel for faster perceived load time
    _loadHeader();
    _loadJobs();
  }

  Future<void> _loadHeader() async {
    final storedName = await UserStorage.getName();
    final storedLocation = await UserStorage.getLocation();

    if (!mounted) {
      return;
    }

    setState(() {
      name = storedName;
      location = storedLocation;
    });
  }

  Future<void> _loadJobs() async {
    try {
      setState(() {
        loading = true;
        errorMessage = null;
      });

      // PERF-001: Fetch only featured count initially, rest on demand
      final result = await _jobService.getJobs(page: 1, limit: 10);

      if (!mounted) return;
      setState(() {
        jobs = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString().contains('Exception:')
            ? e.toString().replaceAll('Exception: ', '')
            : 'Failed to load jobs. Please try again.';
      });
    }
    
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  String _greetingForNow() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _logout() async {
    await _authService.logout();
    await UserStorage.clear();

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openJobDetail(JobModel job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailScreen(jobId: job.id, currentIndex: 0),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedName = (name ?? '').trim().isEmpty ? null : name!.trim();
    final resolvedLocation =
        (location ?? '').trim().isEmpty ? null : location!.trim();

    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      appBar: AppBar(
        title: const Text(
          'Khojgar Kendra',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF102A72),
          ),
        ),
        leadingWidth: 58,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: widget.onOpenProfile,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE3ECFF),
              child: Text(
                ((resolvedName ?? 'U').isNotEmpty
                        ? (resolvedName ?? 'U')[0]
                        : 'U')
                    .toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF163A9A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(currentIndex: 0),
                ),
              );
            },
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF163A9A),
            ),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF163A9A)),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _provider,
        builder: (context, _) {
          final filteredJobs = _provider.filterJobs(jobs);
          final featuredJobs = filteredJobs.take(4).toList();

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF4F8FF), Color(0xFFFFFFFF)],
                stops: [0.0, 0.34],
              ),
            ),
            child: RefreshIndicator(
              onRefresh: _loadJobs,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                children: [
                  if (resolvedLocation != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          resolvedLocation,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.sm + 2),
                  Text(
                    resolvedName == null
                        ? _greetingForNow()
                        : '${_greetingForNow()}, $resolvedName',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F1728),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  const Text(
                    'Find the right opportunity and move your career forward.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _ModernSearchBar(
                    controller: _searchController,
                    onSearchTap: widget.onOpenJobs,
                  ),
                  const SizedBox(height: AppSpacing.lg + 2),
                  const _SectionTitle(title: 'Featured Jobs', action: 'See all'),
                  const SizedBox(height: AppSpacing.sm + 2),
                  if (loading)
                    const SizedBox(
                      height: 182,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    CandidateFeaturedJobCarousel(
                      jobs: featuredJobs,
                      onJobTap: _openJobDetail,
                    ),
                  const SizedBox(height: AppSpacing.lg + 2),
                  CandidateCategoryChips(
                    categories: CandidateDashboardProvider.categories,
                    selected: _provider.selectedCategory,
                    onSelected: _provider.selectCategory,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SectionTitle(
                    title: 'Recent Jobs',
                    action: 'Browse',
                    onTapAction: widget.onOpenJobs,
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),
                  if (loading)
                    ...List.generate(
                      3,
                      (index) => Container(
                        height: 88,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF0FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    )
                  else if (errorMessage != null)
                    _ErrorCard(
                      message: errorMessage!,
                      onRetry: _loadJobs,
                    )
                  else if (filteredJobs.isEmpty)
                    const _EmptyCard(
                      message:
                          'No jobs found for this category. Try another one or browse all jobs.',
                    )
                  else
                    ...filteredJobs.take(6).map(
                          (job) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: CandidateRecentJobCard(
                              job: job,
                              onTap: () => _openJobDetail(job),
                            ),
                          ),
                        ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  OutlinedButton.icon(
                    onPressed: widget.onOpenApplications,
                    icon: const Icon(Icons.assignment_turned_in_outlined),
                    label: const Text('View My Applications'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
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

class _ModernSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSearchTap;

  const _ModernSearchBar({required this.controller, this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search_rounded, color: AppColors.textHint),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSearchTap?.call(),
              decoration: const InputDecoration(
                hintText: 'Search jobs, skills, or company',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: AppColors.textHint,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          TextButton(
            onPressed: onSearchTap,
            child: const Text('Find'),
          ),
          const SizedBox(width: 2),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback? onTapAction;

  const _SectionTitle({required this.title, required this.action, this.onTapAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: onTapAction,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              action,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          const Text(
            'Something went wrong. Please try again.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.danger,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
    );
  }
}
