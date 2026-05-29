import 'package:flutter/material.dart';

class CandidateSavedJobsScreen extends StatelessWidget {
  const CandidateSavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Jobs')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('You have not saved any jobs yet.'),
        ),
      ),
    );
  }
}
