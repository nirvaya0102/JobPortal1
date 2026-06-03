import 'package:flutter/material.dart';
import 'candidate_dashboard_screen.dart';
import '../../../shared/widgets/candidate_footer.dart';
import 'candidate_applied_jobs_screen.dart';
import 'candidate_saved_jobs_screen.dart';
import 'candidate_jobs_list_screen.dart';
import 'package:mobile/features/profile/screens/candidate_profile_screen.dart';

class CandidateMainScreen extends StatefulWidget {
  final int initialIndex;

  const CandidateMainScreen({super.key, this.initialIndex = 0});

  @override
  State<CandidateMainScreen> createState() => _CandidateMainScreenState();
}

class _CandidateMainScreenState extends State<CandidateMainScreen> {
  static const int _tabCount = 4;  // Removed notifications tab from footer
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = _clampIndex(widget.initialIndex);
  }

  List<Widget> _buildPages() {
    return [
      CandidateDashboardScreen(
        onOpenJobs: _openJobsList,
        onOpenApplications: () => _setIndex(2),
        onOpenProfile: () => _setIndex(3),  // Changed from 4 to 3
      ),
      const CandidateSavedJobsScreen(),
      const CandidateAppliedJobsScreen(),
      const CandidateProfileScreen(),
    ];
  }

  void _setIndex(int index) {
    setState(() {
      _currentIndex = _clampIndex(index);
    });
  }

  int _clampIndex(int index) {
    if (index < 0) return 0;
    if (index >= _tabCount) return _tabCount - 1;
    return index;
  }

  void _openJobsList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CandidateJobsListScreen(
          currentIndex: 0,
          onTabSelected: (index) {
            _setIndex(index);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: CandidateFooter(
        currentIndex: _currentIndex,
        onTap: _setIndex,
        items: const [
          CandidateFooterItem(icon: Icons.explore_outlined, label: 'Explore'),
          CandidateFooterItem(icon: Icons.bookmark_outline, label: 'Saved'),
          CandidateFooterItem(icon: Icons.check_box_outlined, label: 'Applied'),
          CandidateFooterItem(icon: Icons.person, label: 'Profile'),
        ],
      ),
    );
  }
}
