import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/storage/user_storage.dart';
import '../models/job_model.dart';

class SavedJobsService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _savedJobsKeyPrefix = 'candidate_saved_jobs_v1';

  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static Future<List<JobModel>> getSavedJobs() async {
    final key = await _savedJobsKey();
    if (key == null) {
      return [];
    }

    final raw = await _storage.read(key: key);
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_mapToJobModel)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> isJobSaved(String jobId) async {
    final jobs = await getSavedJobs();
    return jobs.any((job) => job.id == jobId);
  }

  static Future<bool> toggleSaved(JobModel job) async {
    final key = await _savedJobsKey();
    if (key == null) {
      return false;
    }

    final jobs = await getSavedJobs();
    final existingIndex = jobs.indexWhere((item) => item.id == job.id);
    final willBeSaved = existingIndex == -1;

    if (willBeSaved) {
      jobs.insert(0, job);
    } else {
      jobs.removeAt(existingIndex);
    }

    await _storage.write(
      key: key,
      value: jsonEncode(jobs.map(_jobModelToMap).toList()),
    );
    revision.value = revision.value + 1;
    return willBeSaved;
  }

  static Future<String?> _savedJobsKey() async {
    final userId = (await UserStorage.getId())?.trim();
    if (userId != null && userId.isNotEmpty) {
      return '$_savedJobsKeyPrefix:${_safeKeyPart(userId)}';
    }

    final email = (await UserStorage.getEmail())?.trim().toLowerCase();
    if (email != null && email.isNotEmpty) {
      return '$_savedJobsKeyPrefix:${_safeKeyPart(email)}';
    }

    return null;
  }

  static String _safeKeyPart(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9@._-]'), '_');
  }

  static Map<String, dynamic> _jobModelToMap(JobModel job) {
    return {
      'id': job.id,
      'jobCode': job.jobCode,
      'title': job.title,
      'companyName': job.companyName,
      'companyLogo': job.companyLogo,
      'companyDescription': job.companyDescription,
      'companyLocation': job.companyLocation,
      'companyWebsite': job.companyWebsite,
      'location': job.location,
      'salary': job.salary,
      'type': job.type,
      'description': job.description,
      'status': job.status,
      'applicantsCount': job.applicantsCount,
      'salaryMin': job.salaryMin,
      'salaryMax': job.salaryMax,
      'createdAt': job.createdAt,
      'createdById': job.createdById,
    };
  }

  static JobModel _mapToJobModel(Map<String, dynamic> map) {
    return JobModel(
      id: (map['id'] ?? '').toString(),
      jobCode: map['jobCode']?.toString(),
      title: (map['title'] ?? 'Untitled Job').toString(),
      companyName: map['companyName']?.toString(),
      companyLogo: map['companyLogo']?.toString(),
      companyDescription: map['companyDescription']?.toString(),
      companyLocation: map['companyLocation']?.toString(),
      companyWebsite: map['companyWebsite']?.toString(),
      location: map['location']?.toString(),
      salary: map['salary']?.toString(),
      type: map['type']?.toString(),
      description: map['description']?.toString(),
      status: (map['status'] ?? 'APPROVED').toString(),
      applicantsCount: int.tryParse('${map['applicantsCount'] ?? 0}') ?? 0,
      salaryMin: int.tryParse('${map['salaryMin'] ?? ''}'),
      salaryMax: int.tryParse('${map['salaryMax'] ?? ''}'),
      createdAt: map['createdAt']?.toString(),
      createdById: map['createdById']?.toString(),
    );
  }
}
