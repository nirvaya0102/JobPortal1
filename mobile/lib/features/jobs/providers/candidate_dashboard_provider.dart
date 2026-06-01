import 'package:flutter/foundation.dart';

import '../models/job_model.dart';

class CandidateDashboardProvider extends ChangeNotifier {
  static const List<String> categories = [
    'All',
    'Design',
    'Technology',
    'Marketing',
    'Sales',
    'Remote',
  ];

  String _selectedCategory = 'All';

  String get selectedCategory => _selectedCategory;

  void selectCategory(String value) {
    if (_selectedCategory == value) {
      return;
    }
    _selectedCategory = value;
    notifyListeners();
  }

  List<JobModel> filterJobs(List<JobModel> jobs) {
    if (_selectedCategory == 'All') {
      return jobs;
    }

    final selected = _selectedCategory.toLowerCase();

    return jobs.where((job) {
      final text =
          '${job.title} ${job.type ?? ''} ${job.companyName ?? ''} ${job.location ?? ''}'
              .toLowerCase();

      if (selected == 'technology') {
        return text.contains('engineer') ||
            text.contains('developer') ||
            text.contains('tech') ||
            text.contains('software');
      }

      if (selected == 'remote') {
        return text.contains('remote') || text.contains('hybrid');
      }

      return text.contains(selected);
    }).toList();
  }
}
