import 'package:flutter/material.dart';

import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/section_title.dart';
import '../../jobs/models/job_model.dart';
import '../../jobs/screens/create_job_screen.dart';
import '../../jobs/services/job_service.dart';
import '../widgets/employer_dashboard_theme.dart';
import '../widgets/employer_quick_action_button.dart';
import '../widgets/employer_recent_job_card.dart';
import '../widgets/employer_stat_card.dart';
import 'applicants_screen.dart';
import 'employer_profile_screen.dart';

class EmployerDashboardScreen extends StatefulWidget {
  final String token;
  final String name;

  const EmployerDashboardScreen({
    super.key,
    required this.token,
    required this.name,
  });

  @override
  State<EmployerDashboardScreen> createState() => _EmployerDashboardScreenState();
}

class _EmployerDashboardScreenState extends State<EmployerDashboardScreen> {
  final JobService _jobService = JobService();
  final AuthService _authService = AuthService();

  late Future<List<JobModel>> _jobsFuture;

  @override
  void initState() {
    super.initState();
    _jobsFuture = _jobService.getMyJobs(widget.token);
  }

  Future<void> _refreshJobs() async {
    setState(() {
      _jobsFuture = _jobService.getMyJobs(widget.token);
    });
    await _jobsFuture;
  }

  Future<void> _openCreateJob() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreateJobScreen(token: widget.token)),
    );
    if (created == true) {
      await _refreshJobs();
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) {
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openApplicants(JobModel job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApplicantsScreen(jobId: job.id, jobTitle: job.title),
      ),
    );
  }

  Future<void> _openApplicantsFromShortcut() async {
    try {
      final jobs = await _jobService.getMyJobs(widget.token);
      if (!mounted) return;
      if (jobs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No jobs posted yet.')),
        );
        return;
      }
      _openApplicants(jobs.first);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Please try again.')),
      );
    }
  }

  String _friendlyError(Object? error) {
    final message = error.toString().toLowerCase();
    if (message.contains('socket') || message.contains('network')) {
      return 'No internet connection.';
    }
    if (message.contains('401') || message.contains('unauthorized')) {
      return 'Your session has expired. Please login again.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateJob,
        backgroundColor: EmployerDashboardPalette.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: _BottomNav(
        onTap: (index) {
          if (index == 0) return;
          if (index == 1) {
            _openCreateJob();
            return;
          }
          if (index == 2) {
            _openApplicantsFromShortcut();
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmployerProfileScreen()),
          );
        },
      ),
      backgroundColor: EmployerDashboardPalette.canvas,
      body: EmployerGradientBackground(
        child: SafeArea(
          child: FutureBuilder<List<JobModel>>(
            future: _jobsFuture,
            builder: (context, snapshot) {
              final loading = snapshot.connectionState == ConnectionState.waiting;
              final hasError = snapshot.hasError;
              final jobs = snapshot.data ?? <JobModel>[];
              final activeJobs = jobs
                  .where((job) => job.status == 'OPEN' || job.status == 'ACTIVE')
                  .length;
              final totalApplicants = jobs.fold<int>(
                0,
                (sum, job) => sum + job.applicantsCount,
              );
              final jobsWithApplicants = jobs.where((job) => job.applicantsCount > 0).length;

              return RefreshIndicator(
                color: EmployerDashboardPalette.primary,
                onRefresh: _refreshJobs,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DashboardTopBar(onLogout: _logout),
                            const SizedBox(height: 18),
                            _WelcomeCard(name: widget.name),
                            const SizedBox(height: 14),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final compact = constraints.maxWidth < 360;
                                final items = [
                                  EmployerStatCard(
                                    icon: Icons.work_outline,
                                    label: 'Posted Jobs',
                                    value: '${jobs.length}',
                                    helper: '$activeJobs active right now',
                                    accent: EmployerDashboardPalette.primary,
                                  ),
                                  EmployerStatCard(
                                    icon: Icons.groups_2_outlined,
                                    label: 'Applicants',
                                    value: '$totalApplicants',
                                    helper: '$jobsWithApplicants jobs with activity',
                                    accent: EmployerDashboardPalette.success,
                                  ),
                                ];

                                if (compact) {
                                  return Column(
                                    children: [
                                      items[0],
                                      const SizedBox(height: 10),
                                      items[1],
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(child: items[0]),
                                    const SizedBox(width: 10),
                                    Expanded(child: items[1]),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 18),
                            const SectionTitle(title: 'Quick Actions'),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                EmployerQuickActionButton(
                                  icon: Icons.add_box_outlined,
                                  title: 'Post Job',
                                  onTap: _openCreateJob,
                                ),
                                EmployerQuickActionButton(
                                  icon: Icons.groups_2_outlined,
                                  title: 'Applicants',
                                  onTap: jobs.isEmpty ? null : () => _openApplicants(jobs.first),
                                ),
                                EmployerQuickActionButton(
                                  icon: Icons.refresh_rounded,
                                  title: 'Refresh',
                                  onTap: _refreshJobs,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            SectionTitle(
                              title: 'Recent Jobs',
                              actionText: jobs.isNotEmpty ? '${jobs.length} total' : null,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              hasError
                                  ? _friendlyError(snapshot.error)
                                  : 'Track applicant activity and review your latest postings.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: EmployerDashboardPalette.textMuted,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      sliver: loading
                          ? const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.only(top: 30),
                                child: Center(child: CircularProgressIndicator()),
                              ),
                            )
                          : jobs.isEmpty
                              ? const SliverToBoxAdapter(child: _EmptyJobsCard())
                              : SliverList.separated(
                                  itemCount: jobs.length > 4 ? 4 : jobs.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final job = jobs[index];
                                    final location = (job.location?.isNotEmpty ?? false)
                                        ? job.location!
                                        : 'Location not set';
                                    final type = (job.type?.isNotEmpty ?? false) ? job.type! : 'Full-time';

                                    return EmployerRecentJobCard(
                                      title: job.title,
                                      subtitle: '$location • $type',
                                      applicantSummary: '${job.applicantsCount} applicants',
                                      status: job.status,
                                      onTapApplicants: () => _openApplicants(job),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DashboardTopBar extends StatelessWidget {
  final VoidCallback onLogout;

  const _DashboardTopBar({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Employer Dashboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: EmployerDashboardPalette.primary,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onLogout,
          tooltip: 'Logout',
          icon: const Icon(Icons.logout_rounded),
          color: EmployerDashboardPalette.primary,
        ),
      ],
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String name;

  const _WelcomeCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: EmployerDashboardPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EmployerDashboardPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $name',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: EmployerDashboardPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Here is your latest hiring snapshot and priority actions for today.',
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: EmployerDashboardPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyJobsCard extends StatelessWidget {
  const _EmptyJobsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EmployerDashboardPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmployerDashboardPalette.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No jobs posted yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: EmployerDashboardPalette.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Create your first job post to start receiving applicants.',
            style: TextStyle(
              fontSize: 13,
              color: EmployerDashboardPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final ValueChanged<int> onTap;

  const _BottomNav({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        onTap: onTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: EmployerDashboardPalette.primary,
        unselectedItemColor: Colors.grey.shade400,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.space_dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            label: 'Applicants',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
