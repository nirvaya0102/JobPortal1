import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../models/application_model.dart';

class CandidateAppliedJobsScreen extends StatefulWidget {
  const CandidateAppliedJobsScreen({super.key});

  @override
  State<CandidateAppliedJobsScreen> createState() =>
      _CandidateAppliedJobsScreenState();
}

class _CandidateAppliedJobsScreenState
    extends State<CandidateAppliedJobsScreen> {
  late final Future<List<ApplicationModel>> _applicationsFuture;

  @override
  void initState() {
    super.initState();
    _applicationsFuture = _loadApplications();
  }

  Future<List<ApplicationModel>> _loadApplications() async {
    final response = await ApiClient.dio.get(
      'jobs/my-applications?page=1&limit=50',
    );
    final data = response.data['data'] ?? {};
    final applicationsJson = (data['applications'] ?? []) as List;
    return applicationsJson
        .map(
          (item) => ApplicationModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Applied Jobs')),
      body: FutureBuilder<List<ApplicationModel>>(
        future: _applicationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final applications = snapshot.data ?? const [];
          if (applications.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No applications yet.'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final application = applications[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.work_outline)),
                  title: Text(application.candidate.name),
                  subtitle: Text('Status: ${application.status}'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
