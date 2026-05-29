import 'package:flutter/material.dart';

import '../services/candidate_profile_service.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../../core/storage/user_storage.dart';

class CandidateProfileScreen extends StatefulWidget {
  const CandidateProfileScreen({super.key});

  @override
  State<CandidateProfileScreen> createState() => _CandidateProfileScreenState();
}

class _CandidateProfileScreenState extends State<CandidateProfileScreen>
    with SingleTickerProviderStateMixin {
  late final CandidateProfileService _service;
  late final Future<dynamic> _profileFuture;
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _service = CandidateProfileService();
    _profileFuture = _service.fetchProfile();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFFF7FAFF);
    const navy = Color(0xFF0B2B6B);
    const blue = Color(0xFF243B9B);
    const softBlue = Color(0xFFEFF3FF);
    const mutedText = Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<dynamic>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final profile = snapshot.data;
          if (profile == null) {
            return const Center(child: Text('Unable to load profile'));
          }

          final stats = [
            _ProfileStat(
              value: '${profile.profileCompletion}%',
              label: 'Completion',
            ),
            _ProfileStat(
              value: profile.applicationsCount.toString(),
              label: 'Applications',
            ),
            _ProfileStat(
              value: profile.skills.length.toString(),
              label: 'Skills',
            ),
            _ProfileStat(
              value: profile.hasResume ? '1' : '0',
              label: 'Resumes',
            ),
          ];

          final sections = [
            _ProfileSection(
              title: 'About',
              items: [
                _ProfileRowItem(
                  icon: Icons.work_outline,
                  title: 'Headline',
                  subtitle: profile.headline,
                ),
                _ProfileRowItem(
                  icon: Icons.notes_outlined,
                  title: 'Bio',
                  subtitle: profile.bio,
                ),
                _ProfileRowItem(
                  icon: Icons.interests_outlined,
                  title: 'Skills',
                  subtitle: profile.skills.isEmpty
                      ? 'No skills added yet'
                      : profile.skills.join(' · '),
                ),
                _ProfileRowItem(
                  icon: Icons.description_outlined,
                  title: 'Resume',
                  subtitle: profile.hasResume
                      ? (profile.resumeFileName.isNotEmpty
                            ? profile.resumeFileName
                            : 'Resume uploaded')
                      : 'No resume uploaded yet',
                ),
              ],
            ),
            _ProfileSection(
              title: 'Account',
              items: [
                _ProfileRowItem(
                  icon: Icons.person_outline,
                  title: 'Name',
                  subtitle: profile.name,
                ),
                _ProfileRowItem(
                  icon: Icons.badge_outlined,
                  title: 'Role',
                  subtitle: profile.role,
                ),
                _ProfileRowItem(
                  icon: Icons.location_on_outlined,
                  title: 'Location',
                  subtitle: profile.location,
                ),
                _ProfileRowItem(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  subtitle: profile.email,
                ),
              ],
            ),
            _ProfileSection(
              title: 'Recommendations',
              items: [
                _ProfileRowItem(
                  icon: Icons.trending_up_outlined,
                  title: 'Profile Status',
                  subtitle: profile.profileCompletion >= 80
                      ? 'Your profile looks strong'
                      : 'Complete more fields to improve visibility',
                ),
                _ProfileRowItem(
                  icon: Icons.notifications_outlined,
                  title: 'Job Alerts',
                  subtitle: profile.location == 'Your location'
                      ? 'Add a location to improve alerts'
                      : 'Alerts tuned for ${profile.location}',
                ),
              ],
            ),
          ];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _ProfileCard(
                      profile: profile,
                      stats: stats,
                      blue: blue,
                      softBlue: softBlue,
                      mutedText: mutedText,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                for (final section in sections) ...[
                  _SectionTitle(title: section.title),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _SectionCard(items: section.items),
                  ),
                  const SizedBox(height: 12),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      await AuthService().logout();
                      await UserStorage.clear();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text(
                      'Logout',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final dynamic profile;
  final List<_ProfileStat> stats;
  final Color blue;
  final Color softBlue;
  final Color mutedText;

  const _ProfileCard({
    required this.profile,
    required this.stats,
    required this.blue,
    required this.softBlue,
    required this.mutedText,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          children: [
            Text(
              profile.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: blue,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              profile.headline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: mutedText,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 14, color: mutedText),
                const SizedBox(width: 4),
                Text(
                  profile.location,
                  style: TextStyle(fontSize: 12.5, color: mutedText),
                ),
                const SizedBox(width: 10),
                Icon(Icons.email_outlined, size: 14, color: mutedText),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    profile.email,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: mutedText),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.98, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: SizedBox(
                width: 140,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              children: stats
                  .map(
                    (stat) => SizedBox(
                      width: 74,
                      child: _StatItem(
                        value: stat.value,
                        label: stat.label,
                        accent: softBlue,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color accent;

  const _StatItem({
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0B2B6B),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1F2937),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<_ProfileRowItem> items;

  const _SectionCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _AnimatedProfileTile(item: items[index]),
            if (index != items.length - 1) const Divider(height: 1, indent: 56),
          ],
        ],
      ),
    );
  }
}

class _AnimatedProfileTile extends StatelessWidget {
  final _ProfileRowItem item;

  const _AnimatedProfileTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF3FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, size: 18, color: const Color(0xFF243B9B)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  if (item.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        height: 1.1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat {
  final String value;
  final String label;

  const _ProfileStat({required this.value, required this.label});
}

class _ProfileSection {
  final String title;
  final List<_ProfileRowItem> items;

  const _ProfileSection({required this.title, required this.items});
}

class _ProfileRowItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ProfileRowItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
