import 'package:flutter/foundation.dart';

import '../models/job_model.dart';

class CandidateDashboardProvider extends ChangeNotifier {
  static const List<String> categories = [
    'All',
    'Remote',
    'Full Time',
    'Internship',
    'Design',
    'Development',
    'Marketing',
    'Engineering',
    'Finance',
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

      if (selected == 'development' || selected == 'engineering') {
        return text.contains('engineer') ||
            text.contains('developer') ||
            text.contains('development') ||
            text.contains('tech') ||
            text.contains('software');
      }

      if (selected == 'full time') {
        return text.contains('full-time') || text.contains('full time');
      }

      if (selected == 'remote') {
        return text.contains('remote') || text.contains('hybrid');
      }

      return text.contains(selected);
    }).toList();
  }
}
