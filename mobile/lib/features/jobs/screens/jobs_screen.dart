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
  final TextEditingController searchController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController salaryMinController = TextEditingController();
  final TextEditingController salaryMaxController = TextEditingController();

  List<JobModel> jobs = [];

  int page = 1;
  final int limit = 10;

  bool loading = false;
  bool loadingMore = false;
  bool hasMore = true;
  bool searching = false;
  String? errorMessage;
  String searchQuery = '';
  String locationFilter = '';
  String jobTypeFilter = '';
  String sortBy = 'createdAt';
  String sortOrder = 'desc';
  int? salaryMinFilter;
  int? salaryMaxFilter;
  Timer? _searchDebounce;

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

    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      searchQuery = searchController.text.trim();
      fetchJobs();
    });
  }

  Future<void> fetchJobs() async {
    try {
      setState(() {
        loading = true;
        searching = searchQuery.isNotEmpty;
        errorMessage = null;
        page = 1;
        hasMore = true;
      });

      final result = await jobService.getJobsPage(
        page: page,
        limit: limit,
        search: searchQuery,
        location: locationFilter,
        jobType: jobTypeFilter,
        salaryMin: salaryMinFilter,
        salaryMax: salaryMaxFilter,
        sortBy: sortBy,
        sortOrder: sortOrder,
        status: 'APPROVED',
      );

      if (!mounted) return;

      setState(() {
        jobs = result.jobs;
        hasMore = result.hasNextPage;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = _getErrorMessage(e.toString());
      });
    } finally {
      if (!mounted) return;
      setState(() {
        loading = false;
        searching = false;
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

  Future<void> _performSearch() async {
    searchQuery = searchController.text.trim();
    await fetchJobs();
  }

  bool get _hasActiveFilters =>
      locationFilter.isNotEmpty ||
      jobTypeFilter.isNotEmpty ||
      salaryMinFilter != null ||
      salaryMaxFilter != null;

  void _applySort(String value) {
    final parts = value.split(':');
    setState(() {
      sortBy = parts.first;
      sortOrder = parts.length > 1 ? parts.last : 'desc';
    });
    fetchJobs();
  }

  Future<void> _openFilters() async {
    locationController.text = locationFilter;
    salaryMinController.text = salaryMinFilter?.toString() ?? '';
    salaryMaxController.text = salaryMaxFilter?.toString() ?? '';
    var selectedJobType = jobTypeFilter;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter jobs',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    value: selectedJobType.isEmpty ? null : selectedJobType,
                    decoration: const InputDecoration(
                      labelText: 'Job type',
                      prefixIcon: Icon(Icons.work_outline),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Full-time', child: Text('Full-time')),
                      DropdownMenuItem(value: 'Part-time', child: Text('Part-time')),
                      DropdownMenuItem(value: 'Remote', child: Text('Remote')),
                    ],
                    onChanged: (value) {
                      setSheetState(() {
                        selectedJobType = value ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: salaryMinController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Min salary',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: salaryMaxController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Max salary',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          locationController.clear();
                          salaryMinController.clear();
                          salaryMaxController.clear();
                          selectedJobType = '';
                          Navigator.pop(context, true);
                        },
                        child: const Text('Clear'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (applied != true) return;

    setState(() {
      locationFilter = locationController.text.trim();
      jobTypeFilter = selectedJobType.trim();
      salaryMinFilter = int.tryParse(salaryMinController.text.trim());
      salaryMaxFilter = int.tryParse(salaryMaxController.text.trim());
    });
    fetchJobs();
  }

  Future<void> fetchMoreJobs() async {
    try {
      setState(() {
        loadingMore = true;
      });

      final nextPage = page + 1;
      final result = await jobService.getJobsPage(
        page: nextPage,
        limit: limit,
        search: searchQuery,
        location: locationFilter,
        jobType: jobTypeFilter,
        salaryMin: salaryMinFilter,
        salaryMax: salaryMaxFilter,
        sortBy: sortBy,
        sortOrder: sortOrder,
        status: 'APPROVED',
      );

      if (!mounted) return;

      setState(() {
        page = nextPage;
        final existingIds = jobs.map((job) => job.id).toSet();
        jobs.addAll(result.jobs.where((job) => !existingIds.contains(job.id)));
        hasMore = result.hasNextPage;
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
    locationController.dispose();
    salaryMinController.dispose();
    salaryMaxController.dispose();
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
                  icon: Icon(
                    _hasActiveFilters
                        ? Icons.filter_alt_rounded
                        : Icons.filter_alt_outlined,
                    size: 19,
                  ),
                  onPressed: _openFilters,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: '$sortBy:$sortOrder',
                  isDense: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.sort_rounded, size: 18),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
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
                    DropdownMenuItem(
                      value: 'createdAt:desc',
                      child: Text('Newest first'),
                    ),
                    DropdownMenuItem(
                      value: 'createdAt:asc',
                      child: Text('Oldest first'),
                    ),
                    DropdownMenuItem(
                      value: 'salaryMax:desc',
                      child: Text('Salary high to low'),
                    ),
                    DropdownMenuItem(
                      value: 'salaryMin:asc',
                      child: Text('Salary low to high'),
                    ),
                    DropdownMenuItem(
                      value: 'applicantsCount:desc',
                      child: Text('Most applicants'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) _applySort(value);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ActionChip(
                avatar: Icon(
                  _hasActiveFilters ? Icons.filter_alt_rounded : Icons.tune_rounded,
                  size: 17,
                ),
                label: Text(_hasActiveFilters ? 'Filters on' : 'Filters'),
                onPressed: _openFilters,
                backgroundColor: _hasActiveFilters
                    ? AppColors.primary.withValues(alpha: 0.10)
                    : Colors.white,
                side: const BorderSide(color: AppColors.borderLight),
              ),
            ],
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
                        title: searchQuery.isNotEmpty
                            ? 'No jobs found for "$searchQuery"'
                            : _hasActiveFilters
                            ? 'No jobs match these filters'
                            : 'No jobs available right now',
                        message: searchQuery.isNotEmpty || _hasActiveFilters
                            ? 'Try different keywords or filters.'
                            : 'Check back later for new opportunities.',
                        actionLabel: searchQuery.isNotEmpty || _hasActiveFilters
                            ? 'Clear Filters'
                            : 'Refresh',
                        onAction: () {
                          if (searchQuery.isNotEmpty) {
                            searchController.clear();
                          }
                          setState(() {
                            searchQuery = '';
                            locationFilter = '';
                            jobTypeFilter = '';
                            salaryMinFilter = null;
                            salaryMaxFilter = null;
                            page = 1;
                          });
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
