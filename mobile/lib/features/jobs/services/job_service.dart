import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/api/api_client.dart';
import '../models/job_model.dart';
import '../models/application_model.dart';

class JobService {
  final String baseUrl = 'http://10.0.2.2:5000/api';

  Future<List<JobModel>> getMyJobs(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/jobs/my-jobs'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final List jobs = data['data']['jobs'] ?? [];
      return jobs.map((job) => JobModel.fromJson(job)).toList();
    }

    throw Exception(data['message'] ?? 'Failed to load jobs');
  }

  Future<List<JobModel>> getJobs({int page = 1, int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/jobs?page=$page&limit=$limit'),
      headers: {'Content-Type': 'application/json'},
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final List data = decoded['data']['jobs'] ?? [];
      return data.map((job) => JobModel.fromJson(job)).toList();
    }

    throw Exception(decoded['message'] ?? 'Failed to load jobs');
  }

  // SEARCH-001: Search functionality
  Future<List<JobModel>> searchJobs({
    required String query,
    int page = 1,
    int limit = 10,
  }) async {
    if (query.isEmpty) {
      return getJobs(page: page, limit: limit);
    }

    final response = await http.get(
      Uri.parse('$baseUrl/jobs/search?q=$query&page=$page&limit=$limit'),
      headers: {'Content-Type': 'application/json'},
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final List data = decoded['data']['jobs'] ?? [];
      return data.map((job) => JobModel.fromJson(job)).toList();
    }

    throw Exception(decoded['message'] ?? 'Search failed');
  }

  Future<JobModel> getJobById(String id) async {
    try {
      final response = await ApiClient.dio.get('jobs/$id');
      final data = response.data['data'];
      final jobJson = data['job'] ?? data;
      return JobModel.fromJson(jobJson);
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ??
          e.message ??
          'Failed to load job details';
      throw Exception(message);
    }
  }

  Future<void> createJob({
    required String token,
    required String title,
    required String description,
    required String location,
    required String jobType,
    required int salaryMin,
    required int salaryMax,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/jobs'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'location': location,
        'jobType': jobType,
        'salaryMin': salaryMin,
        'salaryMax': salaryMax,
      }),
    );

    final data = jsonDecode(response.body);

    print('CREATE JOB STATUS: ${response.statusCode}');
    print('CREATE JOB BODY: $data');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    String message = data['message'] ?? 'Failed to create job';

    if (data['errors'] != null) {
      message = data['errors'].toString();
    }

    throw Exception(message);
  }

  Future<List<ApplicationModel>> getJobApplicants(String jobId) async {
    try {
      final response = await ApiClient.dio.get('jobs/$jobId/applicants');
      final data = response.data['data'];
      final List applicantsJson = data['applicants'] ?? [];
      return applicantsJson
          .map((json) => ApplicationModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ??
          e.message ??
          'Failed to load applicants';
      throw Exception(message);
    }
  }

  Future<String> getApplicationResume(
    String jobId,
    String applicationId,
  ) async {
    try {
      final response = await ApiClient.dio.get(
        'jobs/$jobId/applications/$applicationId/resume',
      );
      final data = response.data['data'];
      return data['url'] ?? '';
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ?? e.message ?? 'Failed to load resume';
      throw Exception(message);
    }
  }

  Future<void> updateApplicationStatus(
    String jobId,
    String applicationId,
    String status,
  ) async {
    try {
      await ApiClient.dio.patch(
        'jobs/$jobId/applications/$applicationId/status',
        data: {'status': status},
      );
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ?? e.message ?? 'Failed to update status';
      throw Exception(message);
    }
  }
}
