import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radii.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/app_search_field.dart';
import '../models/job_model.dart';
import '../services/job_service.dart';
import '../widgets/job_card.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final JobService jobService = JobService();
  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();  // SEARCH-001

  List<JobModel> jobs = [];

  int page = 1;
  final int limit = 10;

  bool loading = false;
  bool loadingMore = false;
  bool hasMore = true;
  bool searching = false;
  String? errorMessage;
  String searchQuery = '';  // SEARCH-001
  Timer? _searchDebounce;  // SEARCH-001

  @override
  void initState() {
    super.initState();
    fetchJobs();

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200 &&
          !loadingMore &&
          hasMore &&
          !loading) {
        fetchMoreJobs();
      }
    });

    // SEARCH-001: Setup search with debouncing
    searchController.addListener(_onSearchChanged);
  }

  // SEARCH-001: Debounced search
  void _onSearchChanged() {
    // Keep suffix icon and search field state reactive while typing.
    if (mounted) {
      setState(() {});
    }
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        searchQuery = searchController.text.trim();
        page = 1;
      });
      if (searchQuery.isEmpty) {
        fetchJobs();
      } else {
        _performSearch();
      }
    });
  }

  // SEARCH-001: Perform search
  Future<void> _performSearch() async {
    if (searchQuery.isEmpty) {
      fetchJobs();
      return;
    }

    try {
      setState(() {
        loading = true;
        searching = true;
        errorMessage = null;
        hasMore = true;
      });

      final result = await jobService.searchJobs(
        query: searchQuery,
        page: page,
        limit: limit,
      );

      setState(() {
        jobs = result;
        hasMore = result.length == limit;
      });
    } catch (e) {
      setState(() {
        errorMessage = _getErrorMessage(e.toString());
      });
    } finally {
      setState(() {
        loading = false;
        searching = false;
      });
    }
  }

  Future<void> fetchJobs() async {
    try {
      setState(() {
        loading = true;
        errorMessage = null;
        page = 1;
        hasMore = true;
      });

      final result = await jobService.getJobs(page: page, limit: limit);

      setState(() {
        jobs = result;
        hasMore = result.length == limit;
      });
    } catch (e) {
      setState(() {
        errorMessage = _getErrorMessage(e.toString());
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  // ERROR-001: User-friendly error messages
  String _getErrorMessage(String error) {
    if (error.contains('No internet') || error.contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    } else if (error.contains('timeout')) {
      return 'Connection timeout. Please try again.';
    } else if (error.contains('401') || error.contains('Unauthorized')) {
      return 'Session expired. Please login again.';
    } else if (error.contains('404')) {
      return 'Jobs not found.';
    } else if (error.contains('500') || error.contains('Internal Server Error')) {
      return 'Server error. Please try again later.';
    } else {
      return error.replaceAll('Exception: ', '');
    }
  }

  Future<void> fetchMoreJobs() async {
    try {
      setState(() {
        loadingMore = true;
      });

      final nextPage = page + 1;
      final result = searchQuery.isEmpty
          ? await jobService.getJobs(page: nextPage, limit: limit)
          : await jobService.searchJobs(
              query: searchQuery,
              page: nextPage,
              limit: limit,
            );

      if (!mounted) return;

      setState(() {
        page = nextPage;
        jobs.addAll(result);
        hasMore = result.length == limit;
      });
    } catch (e) {
      if (!mounted) return;
      // Show error but don't block the list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getErrorMessage(e.toString()))),
      );
    }
    
    if (mounted) {
      setState(() {
        loadingMore = false;
      });
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Widget buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          height: 112,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading && searchQuery.isEmpty) {
      return buildSkeleton();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discover Opportunities',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Find the right job for your next move',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: IconButton(
                  icon: const Icon(Icons.filter_alt_outlined, size: 19),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sort and filter options coming soon.')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              boxShadow: AppShadows.soft(),
            ),
            child: AppSearchField(
              controller: searchController,
              hintText: 'Search jobs, companies...',
              trailingText: searchController.text.isNotEmpty ? 'Clear' : 'Search',
              onSubmitted: (_) => _performSearch(),
              onTapTrailing: () {
                if (searchController.text.isNotEmpty) {
                  searchController.clear();
                  setState(() {
                    searchQuery = '';
                    page = 1;
                  });
                  fetchJobs();
                } else {
                  _performSearch();
                }
              },
            ),
          ),
        ),
        if (searching)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: LinearProgressIndicator(minHeight: 3),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: fetchJobs,
            child: errorMessage != null
                ? ListView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    children: [
                      const SizedBox(height: 120),
                      _ExploreStateCard(
                        icon: Icons.error_outline_rounded,
                        title: 'Could not load jobs',
                        message: errorMessage!,
                        actionLabel: 'Retry',
                        onAction: fetchJobs,
                      ),
                    ],
                  )
                : jobs.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    children: [
                      const SizedBox(height: 120),
                      _ExploreStateCard(
                        icon: Icons.work_outline_rounded,
                        title: searchQuery.isEmpty
                            ? 'No jobs available right now'
                            : 'No jobs found for "$searchQuery"',
                        message: searchQuery.isEmpty
                            ? 'Check back later for new opportunities.'
                            : 'Try different keywords or browse all jobs.',
                        actionLabel: searchQuery.isNotEmpty ? 'Clear Search' : 'Refresh',
                        onAction: () {
                          if (searchQuery.isNotEmpty) {
                            searchController.clear();
                            setState(() {
                              searchQuery = '';
                              page = 1;
                            });
                          }
                          fetchJobs();
                        },
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    itemCount: jobs.length + (loadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == jobs.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      return JobCard(job: jobs[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _ExploreStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _ExploreStateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.soft(),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.primaryBlue),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
