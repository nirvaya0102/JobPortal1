import 'package:flutter/material.dart';
import '../../jobs/models/job_model.dart';
import '../../jobs/services/job_service.dart';
import '../../jobs/screens/create_job_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';
import 'applicants_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens — edit these to retheme the whole screen instantly
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  // Brand
  static const primary = Color(0xFF1A1F8F);
  // Gradient stops (top → bottom)
  static const gradTop = Color(0xFFE2DCFF); // richest lavender
  static const gradMid = Color(0xFFEDE9FF); // softer
  static const gradFade = Color(0xFFF6F4FF); // almost white-purple
  // Cards / surface
  static const surface = Colors.white;
  static const border = Color(0xFFDDDAF4);
  static const iconBg = Color(0xFFEEEBFF);
  // Semantic
  static const green = Color(0xFF1FAD45);
  static const greenBg = Color(0xFFD5F5DD);
  static const red = Color(0xFFE53935);
  static const redBg = Color(0xFFFFE5E5);
  static const orange = Color(0xFFF5A623);
  // Text
  static const textDark = Color(0xFF1C1C2E);
  static const textMid = Color(0xFF6B6B8A);
  static const textLight = Color(0xFFAAAAAC);
}

class _T {
  static const navTitle = TextStyle(
    color: _C.primary,
    fontSize: 17,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.1,
  );
  static const welcomeHeading = TextStyle(
    color: _C.primary,
    fontSize: 23,
    fontWeight: FontWeight.w800,
    height: 1.18,
  );
  static const welcomeSub = TextStyle(
    color: Color(0xFF7070A0),
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );
  static const statLabel = TextStyle(
    color: _C.textMid,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
  static const statValue = TextStyle(
    color: _C.primary,
    fontSize: 38,
    fontWeight: FontWeight.w900,
    height: 1.0,
  );
  static const badgeBase = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
  );
  static const sectionHeading = TextStyle(
    color: _C.textDark,
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );
  static const sectionCaption = TextStyle(
    color: Color(0xFF9898B2),
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
  static const cardName = TextStyle(
    color: _C.textDark,
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
  );
  static const cardRole = TextStyle(
    color: Color(0xFF7A7A9A),
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
  static const cardTime = TextStyle(
    color: _C.textLight,
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class EmployerDashboardScreen extends StatefulWidget {
  final String token;
  final String name;

  const EmployerDashboardScreen({
    super.key,
    required this.token,
    required this.name,
  });

  @override
  State<EmployerDashboardScreen> createState() =>
      _EmployerDashboardScreenState();
}

class _EmployerDashboardScreenState extends State<EmployerDashboardScreen> {
  // ── kept so other files that reference these constants still compile ───────
  static const Color primaryBlue = _C.primary;
  static const Color bgPurple = Color(0xFFF3F0FF);
  static const Color softGreen = _C.greenBg;
  static const Color green = _C.green;
  static const Color softRed = _C.redBg;
  static const Color red = _C.red;
  static const Color orange = _C.orange;
  // ─────────────────────────────────────────────────────────────────────────

  final JobService jobService = JobService();
  final AuthService authService = AuthService();
  late Future<List<JobModel>> jobsFuture;

  @override
  void initState() {
    super.initState();
    jobsFuture = jobService.getMyJobs(widget.token); // logic unchanged
  }

  Future<void> _openCreateJob() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateJobScreen(token: widget.token)),
    );
    if (result == true) {
      setState(() => jobsFuture = jobService.getMyJobs(widget.token));
    }
  }

  Future<void> _logout() async {
    await authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.gradTop,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _C.primary,
        shape: const CircleBorder(),
        onPressed: _openCreateJob,
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
      bottomNavigationBar: const _BottomNav(),
      body: FutureBuilder<List<JobModel>>(
        future: jobsFuture,
        builder: (context, snapshot) {
          final isLoading =
              snapshot.connectionState == ConnectionState.waiting;
          final jobs = snapshot.data ?? [];

          // ── derived stats (logic unchanged) ──────────────────────────────
          final activeJobs = jobs
              .where((j) => j.status == 'OPEN' || j.status == 'ACTIVE')
              .length;
          final totalApplicants =
              jobs.fold<int>(0, (s, j) => s + j.applicantsCount);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ════════════════════════════════════════════════════════════
              // GRADIENT ZONE — AppBar + Welcome Card + Stat Cards
              // ════════════════════════════════════════════════════════════
              SliverToBoxAdapter(
                child: _GradientZone(
                  name: widget.name,
                  isLoading: isLoading,
                  hasError: snapshot.hasError,
                  errorText:
                      snapshot.hasError ? snapshot.error.toString() : '',
                  activeJobs: activeJobs,
                  totalJobs: jobs.length,
                  totalApplicants: totalApplicants,
                  onLogout: _logout,
                ),
              ),

              // ════════════════════════════════════════════════════════════
              // WHITE ZONE — Recent Applicants
              // ════════════════════════════════════════════════════════════
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          const Text('Recent Applicants',
                              style: _T.sectionHeading),
                          const Spacer(),
                          Text(
                            'View All',
                            style: _T.sectionCaption.copyWith(
                              color: _C.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text('Candidates awaiting your review.',
                          style: _T.sectionCaption),
                      const SizedBox(height: 14),

                      // Cards
                      if (isLoading)
                        const SizedBox.shrink()
                      else if (snapshot.hasError)
                        const SizedBox.shrink()
                      else if (jobs.isEmpty)
                        _EmptyBox()
                      else
                        ...jobs.take(4).map(
                              (job) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ApplicantCard(
                                  name: job.title,
                                  role: 'Applied for ${job.title}',
                                  timeAgo: '${job.applicantsCount} applicants',
                                  initials: job.title.isNotEmpty
                                      ? job.title[0].toUpperCase()
                                      : '?',
                                  onReview: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ApplicantsScreen(
                                          jobId: job.id,
                                          jobTitle: job.title,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gradient Zone widget
// ─────────────────────────────────────────────────────────────────────────────
class _GradientZone extends StatelessWidget {
  final String name;
  final bool isLoading;
  final bool hasError;
  final String errorText;
  final int activeJobs;
  final int totalJobs;
  final int totalApplicants;
  final VoidCallback onLogout;

  const _GradientZone({
    required this.name,
    required this.isLoading,
    required this.hasError,
    required this.errorText,
    required this.activeJobs,
    required this.totalJobs,
    required this.totalApplicants,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _C.gradTop,   // 0 %  — richest lavender
            _C.gradMid,   // 45 % — softer purple
            _C.gradFade,  // 80 % — barely tinted
            Colors.white, // 100 % — bleeds into white zone
          ],
          stops: [0.0, 0.40, 0.78, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // ── App bar ──────────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.menu_rounded,
                      color: _C.primary, size: 24),
                  const SizedBox(width: 12),
                  const Text('RojgarKendra', style: _T.navTitle),
                  const Spacer(),
                  IconButton(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout, color: _C.primary),
                  ),
                  const CircleAvatar(
                    radius: 17,
                    backgroundImage: NetworkImage(
                        'https://i.pravatar.cc/100?img=12'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Welcome card ─────────────────────────────────────────────
              _WelcomeCard(name: name),

              const SizedBox(height: 16),

              // ── Stat cards ───────────────────────────────────────────────
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (hasError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(errorText,
                      style: const TextStyle(color: Colors.red)),
                )
              else ...[
                _StatCard(
                  icon: Icons.business_center_outlined,
                  iconColor: _C.primary,
                  title: 'Active Job Postings',
                  value: activeJobs.toString(),
                  badge: '+$totalJobs this week',
                  badgeColor: _C.green,
                  badgeBg: _C.greenBg,
                  badgeIcon: Icons.trending_up_rounded,
                ),
                const SizedBox(height: 13),
                _StatCard(
                  icon: Icons.people_alt_outlined,
                  iconColor: _C.orange,
                  title: 'Total Applicants',
                  value: totalApplicants.toString(),
                  badge: '+48 this week',
                  badgeColor: _C.green,
                  badgeBg: _C.greenBg,
                  badgeIcon: Icons.trending_up_rounded,
                ),
                const SizedBox(height: 13),
                _StatCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: _C.primary,
                  title: 'New Messages',
                  value: '0',
                  badge: '0 Unread',
                  badgeColor: _C.textLight,
                  badgeBg: _C.iconBg,
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Welcome Card
// ─────────────────────────────────────────────────────────────────────────────
class _WelcomeCard extends StatelessWidget {
  final String name;
  const _WelcomeCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company icon box
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _C.iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.landscape_rounded,
              color: _C.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back,\n$name', style: _T.welcomeHeading),
                const SizedBox(height: 6),
                const Text(
                  'Here is what\'s happening with\nyour job postings today.',
                  style: _T.welcomeSub,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat Card
// ─────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String badge;
  final Color badgeColor;
  final Color badgeBg;
  final IconData? badgeIcon;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.badge,
    required this.badgeColor,
    required this.badgeBg,
    this.badgeIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + Badge row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _C.iconBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
              _BadgePill(
                  label: badge,
                  color: badgeColor,
                  bg: badgeBg,
                  icon: badgeIcon),
            ],
          ),
          const SizedBox(height: 14),
          Text(title, style: _T.statLabel),
          const SizedBox(height: 3),
          Text(value, style: _T.statValue),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge Pill
// ─────────────────────────────────────────────────────────────────────────────
class _BadgePill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final IconData? icon;

  const _BadgePill({
    required this.label,
    required this.color,
    required this.bg,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 3),
          ],
          Text(label, style: _T.badgeBase.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Applicant Card
// ─────────────────────────────────────────────────────────────────────────────
class _ApplicantCard extends StatelessWidget {
  final String name;
  final String role;
  final String timeAgo;
  final String initials;
  final String? avatarUrl;
  final VoidCallback onReview;

  const _ApplicantCard({
    required this.name,
    required this.role,
    required this.timeAgo,
    required this.initials,
    required this.onReview,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAF2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFE8EBF8),
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: _C.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Name + role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: _T.cardName),
                    const SizedBox(height: 2),
                    Text(role, style: _T.cardRole),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Time + Review button
          Row(
            children: [
              Text(timeAgo, style: _T.cardTime),
              const Spacer(),
              SizedBox(
                height: 32,
                width: 90,
                child: OutlinedButton(
                  onPressed: onReview,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: _C.primary.withOpacity(0.4), width: 1),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Review',
                    style: TextStyle(
                      color: _C.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAEAF2)),
      ),
      child: const Text(
        'No jobs posted yet. Tap + to create your first job.',
        style: TextStyle(color: Colors.black54, fontSize: 13),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Navigation Bar
// ─────────────────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  const _BottomNav();

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
            color: Colors.black.withOpacity(0.10),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 3,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _C.primary,
        unselectedItemColor: Colors.grey.shade400,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Applied',
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