import 'package:flutter/material.dart';

import '../../../shared/widgets/candidate_footer.dart';
import 'jobs_screen.dart';

class CandidateJobsListScreen extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const CandidateJobsListScreen({
    super.key,
    this.currentIndex = 0,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore Jobs')),
      body: const JobsScreen(),
      bottomNavigationBar: CandidateFooter(
        currentIndex: currentIndex,
        onTap: onTabSelected,
      ),
    );
  }
}
