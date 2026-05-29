import 'package:flutter/material.dart';

import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../../core/storage/user_storage.dart';
import '../models/job_model.dart';
import '../services/job_service.dart';
import '../widgets/job_compact_card.dart';
import '../../../shared/widgets/app_search_field.dart';
import '../../../shared/widgets/app_section_header.dart';

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

  bool loading = false;
  String? errorMessage;
  List<JobModel> jobs = [];
  String? name;
  String? location;

  @override
  void initState() {
    super.initState();
    _loadHeader();
    _loadJobs();
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

  Future<void> _loadJobs() async {
    try {
      setState(() {
        loading = true;
        errorMessage = null;
      });

      final result = await _jobService.getJobs(page: 1, limit: 6);

      setState(() {
        jobs = result;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
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
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final resolvedName = (name ?? '').trim().isEmpty ? null : name!.trim();
    final resolvedLocation = (location ?? '').trim().isEmpty
        ? null
        : location!.trim();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Khojgar Kendra'),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: widget.onOpenProfile,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.surfaceContainerHighest,
              child: Text(
                ((resolvedName ?? 'U').isNotEmpty
                        ? (resolvedName ?? 'U')[0]
                        : 'U')
                    .toUpperCase(),
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
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
            icon: const Icon(Icons.notifications_none),
          ),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadJobs,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (resolvedLocation != null)
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    resolvedLocation,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resolvedName == null
                        ? _greetingForNow()
                        : '${_greetingForNow()},\n$resolvedName',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Discover the opportunities that align with your career trajectory.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppSearchField(
                    controller: _searchController,
                    hintText: 'Search jobs, companies, or skills',
                    onSubmitted: (_) => widget.onOpenJobs?.call(),
                    onTapTrailing: widget.onOpenJobs,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile Strength',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add your latest portfolio items to unlock relevant recommendations.',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: null,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: widget.onOpenProfile,
                      child: const Text('Update Profile'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onOpenJobs,
                    icon: const Icon(Icons.work_outline),
                    label: const Text('Browse Jobs'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onOpenApplications,
                    icon: const Icon(Icons.assignment_outlined),
                    label: const Text('Applications'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppSectionHeader(
              title: 'Recommended',
              actionText: 'View all',
              onAction: widget.onOpenJobs,
            ),
            const SizedBox(height: 12),
            if (loading)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.92,
                ),
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  );
                },
              )
            else if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.error),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _loadJobs,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (jobs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No jobs available right now.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: jobs.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.92,
                ),
                itemBuilder: (context, index) {
                  return JobCompactCard(job: jobs[index]);
                },
              ),
          ],
        ),
      ),
    );
  }
}
