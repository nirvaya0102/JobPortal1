import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radii.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/storage/user_storage.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../profile/services/candidate_profile_service.dart';
import '../models/job_model.dart';
import '../providers/candidate_dashboard_provider.dart';
import '../screens/job_detail_screen.dart';
import '../services/job_service.dart';
import '../services/saved_jobs_service.dart';
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

class _CandidateDashboardScreenState extends State<CandidateDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _jobService = JobService();
  final _authService = AuthService();
  final _profileService = CandidateProfileService();
  final _searchController = TextEditingController();
  final _provider = CandidateDashboardProvider();

  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  bool loading = false;
  bool loadingMetrics = false;
  String? errorMessage;
  List<JobModel> jobs = [];
  String? name;
  String? location;
  int applicationsCount = 0;
  int savedJobsCount = 0;
  int profileCompletion = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(_fadeAnimation!);
    _animationController!.forward();

    SavedJobsService.revision.addListener(_loadSavedCount);
    _loadHeader();
    _loadJobs();
    _loadMetrics();
  }

  Future<void> _loadHeader() async {
    final storedName = await UserStorage.getName();
    final storedLocation = await UserStorage.getLocation();

    if (!mounted) return;

    setState(() {
      name = storedName;
      location = storedLocation;
    });
  }

  Future<void> _loadMetrics() async {
    try {
      setState(() => loadingMetrics = true);

      final saved = await SavedJobsService.getSavedJobs();
      CandidateProfileData? profile;
      try {
        profile = await _profileService.fetchProfile();
      } catch (_) {
        profile = null;
      }

      if (!mounted) return;
      setState(() {
        savedJobsCount = saved.length;
        if (profile != null) {
          applicationsCount = profile.applicationsCount;
          profileCompletion = profile.profileCompletion;
          name = profile.name;
          location = profile.location;
        }
      });
    } finally {
      if (mounted) setState(() => loadingMetrics = false);
    }
  }

  Future<void> _loadSavedCount() async {
    final saved = await SavedJobsService.getSavedJobs();
    if (!mounted) return;
    setState(() => savedJobsCount = saved.length);
  }

  Future<void> _refreshDashboard() async {
    await Future.wait([
      _loadJobs(),
      _loadMetrics(),
      _loadHeader(),
    ]);
  }

  Future<void> _loadJobs() async {
    try {
      setState(() {
        loading = true;
        errorMessage = null;
      });

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
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> _logout() async {
    await _authService.logout();
    await UserStorage.clear();

    if (!mounted) return;

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
    SavedJobsService.revision.removeListener(_loadSavedCount);
    _animationController?.dispose();
    _searchController.dispose();
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedName = (name ?? '').trim().isEmpty ? 'Candidate' : name!.trim();
    final resolvedLocation =
        (location ?? '').trim().isEmpty ? null : location!.trim();

    return Scaffold(
      backgroundColor: AppColors.canvasLight,
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
                colors: [Color(0xFFEFF5FF), Color(0xFFF8FBFF), Colors.white],
                stops: [0.0, 0.34, 1.0],
              ),
            ),
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: _refreshDashboard,
                child: FadeTransition(
                  opacity:
                      _fadeAnimation ?? const AlwaysStoppedAnimation<double>(1),
                  child: SlideTransition(
                    position: _slideAnimation ??
                        const AlwaysStoppedAnimation<Offset>(Offset.zero),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      children: [
                        _DashboardHeader(
                          greeting: _greetingForNow(),
                          name: resolvedName,
                          location: resolvedLocation,
                          onOpenProfile: widget.onOpenProfile,
                          onOpenNotifications: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const NotificationsScreen(currentIndex: 0),
                              ),
                            );
                          },
                          onLogout: _logout,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _DashboardSearchBar(
                          controller: _searchController,
                          onSearchTap: widget.onOpenJobs,
                          onFilterTap: widget.onOpenJobs,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _StatsGrid(
                          loading: loadingMetrics,
                          applicationsCount: applicationsCount,
                          savedJobsCount: savedJobsCount,
                          profileCompletion: profileCompletion,
                          recommendedJobs: jobs.length,
                          onApplicationsTap: widget.onOpenApplications,
                          onSavedTap: widget.onOpenJobs,
                          onProfileTap: widget.onOpenProfile,
                          onRecommendedTap: widget.onOpenJobs,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _SectionTitle(
                          title: 'Featured Jobs',
                          action: 'View All',
                          onTapAction: widget.onOpenJobs,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (loading)
                          const _FeaturedSkeleton()
                        else
                          CandidateFeaturedJobCarousel(
                            jobs: featuredJobs,
                            onJobTap: _openJobDetail,
                          ),
                        const SizedBox(height: AppSpacing.xl),
                        CandidateCategoryChips(
                          categories: CandidateDashboardProvider.categories,
                          selected: _provider.selectedCategory,
                          onSelected: _provider.selectCategory,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _SectionTitle(
                          title: 'Recommended for You',
                          action: 'View All',
                          onTapAction: widget.onOpenJobs,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (loading)
                          const _JobListSkeleton()
                        else if (errorMessage != null)
                          _ErrorCard(message: errorMessage!, onRetry: _loadJobs)
                        else if (filteredJobs.isEmpty)
                          _EmptyJobsCard(onBrowse: widget.onOpenJobs)
                        else
                          ListView.builder(
                            itemCount: filteredJobs.take(6).length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final job = filteredJobs[index];
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: CandidateRecentJobCard(
                                  job: job,
                                  onTap: () => _openJobDetail(job),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: widget.onOpenApplications,
                          icon: const Icon(Icons.assignment_turned_in_outlined),
                          label: const Text('View My Applications'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            foregroundColor: AppColors.primaryBlue,
                            side: const BorderSide(color: AppColors.borderLight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.lg),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String greeting;
  final String name;
  final String? location;
  final VoidCallback? onOpenProfile;
  final VoidCallback onOpenNotifications;
  final VoidCallback onLogout;

  const _DashboardHeader({
    required this.greeting,
    required this.name,
    required this.location,
    required this.onOpenProfile,
    required this.onOpenNotifications,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'C' : name.characters.first;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          onTap: onOpenProfile,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1D3FAF), Color(0xFF5B7CFA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.soft(color: AppColors.primaryBlue),
            ),
            alignment: Alignment.center,
            child: Text(
              initial.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting,',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$name 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                "Let's find your next opportunity.",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (location != null) ...[
                const SizedBox(height: AppSpacing.xs),
//                 Row(
//                   children: [
//                     const Icon(
//                       Icons.location_on_outlined,
//                       size: 15,
//                       color: AppColors.textHint,
//                     ),
//                     const SizedBox(width: 4),
//                     Flexible(
//                       child: Text(
//                         location!,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(
//                           color: AppColors.textHint,
//                           fontSize: 12,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
              ],
            ],
          ),
        ),
        _HeaderIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: onOpenNotifications,
        ),
        const SizedBox(width: AppSpacing.xs),
        _HeaderIconButton(icon: Icons.logout_rounded, onTap: onLogout),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Icon(icon, color: AppColors.primaryBlue, size: 20),
        ),
      ),
    );
  }
}

class _DashboardSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSearchTap;
  final VoidCallback? onFilterTap;

  const _DashboardSearchBar({
    required this.controller,
    this.onSearchTap,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.medium(),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.md),
          const Icon(Icons.search_rounded, color: AppColors.primaryBlue),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSearchTap?.call(),
              onTap: onSearchTap,
              readOnly: true,
              decoration: const InputDecoration(
                hintText: 'Search jobs, companies, locations...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              tooltip: 'Filter jobs',
              onPressed: onFilterTap,
              icon: const Icon(
                Icons.tune_rounded,
                color: AppColors.primaryBlue,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final bool loading;
  final int applicationsCount;
  final int savedJobsCount;
  final int profileCompletion;
  final int recommendedJobs;
  final VoidCallback? onApplicationsTap;
  final VoidCallback? onSavedTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onRecommendedTap;

  const _StatsGrid({
    required this.loading,
    required this.applicationsCount,
    required this.savedJobsCount,
    required this.profileCompletion,
    required this.recommendedJobs,
    this.onApplicationsTap,
    this.onSavedTap,
    this.onProfileTap,
    this.onRecommendedTap,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData(
        label: 'Applications',
        value: applicationsCount.toString(),
        icon: Icons.assignment_turned_in_outlined,
        color: AppColors.primaryBlue,
        onTap: onApplicationsTap,
      ),
      _StatData(
        label: 'Saved Jobs',
        value: savedJobsCount.toString(),
        icon: Icons.bookmark_border_rounded,
        color: const Color(0xFF7C3AED),
        onTap: onSavedTap,
      ),
      _StatData(
        label: 'Profile',
        value: '$profileCompletion%',
        icon: Icons.person_outline_rounded,
        color: AppColors.success,
        onTap: onProfileTap,
      ),
      _StatData(
        label: 'Recommended',
        value: recommendedJobs.toString(),
        icon: Icons.auto_awesome_outlined,
        color: const Color(0xFFEA580C),
        onTap: onRecommendedTap,
      ),
    ];

    return GridView.builder(
      itemCount: stats.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.88,
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _StatCard(stat: stat, loading: loading);
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final _StatData stat;
  final bool loading;

  const _StatCard({required this.stat, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: stat.onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: AppShadows.soft(),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: stat.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(stat.icon, color: stat.color, size: 19),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: loading
                          ? const _TinySkeleton(key: ValueKey('loading'))
                          : Text(
                              stat.value,
                              key: ValueKey(stat.value),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                    Text(
                      stat.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
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

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback? onTapAction;

  const _SectionTitle({
    required this.title,
    required this.action,
    this.onTapAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: onTapAction,
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
          label: Text(action),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryBlue,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: const Color(0xFFFECACA)),
        boxShadow: AppShadows.soft(),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message.isEmpty ? 'Something went wrong. Please try again.' : message,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.danger,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyJobsCard extends StatelessWidget {
  final VoidCallback? onBrowse;

  const _EmptyJobsCard({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.soft(),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.work_outline_rounded,
              color: AppColors.primaryBlue,
              size: 34,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No jobs available',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Browse all openings or pull down to refresh new opportunities.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: onBrowse,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Browse Jobs'),
          ),
        ],
      ),
    );
  }
}

class _FeaturedSkeleton extends StatelessWidget {
  const _FeaturedSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 214,
      child: Row(
        children: [
          Expanded(child: _SkeletonBox(radius: 24)),
          SizedBox(width: 12),
          SizedBox(width: 28, child: _SkeletonBox(radius: 24)),
        ],
      ),
    );
  }
}

class _JobListSkeleton extends StatelessWidget {
  const _JobListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: _SkeletonBox(height: 190, radius: 20),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double? height;
  final double radius;

  const _SkeletonBox({this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.35, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, _) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              colors: [
                const Color(0xFFEAF0FF).withValues(alpha: value),
                const Color(0xFFF8FAFF),
                const Color(0xFFEAF0FF).withValues(alpha: value),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TinySkeleton extends StatelessWidget {
  const _TinySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 18,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0FF),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
    );
  }
}
