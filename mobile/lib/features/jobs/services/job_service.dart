import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/api/api_client.dart';
import '../../../core/config/app_config.dart';
import '../models/job_model.dart';
import '../models/application_model.dart';

class JobsPageResult {
  final List<JobModel> jobs;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const JobsPageResult({
    required this.jobs,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory JobsPageResult.fromJson(Map<String, dynamic> json) {
    final jobsJson = (json['jobs'] ?? []) as List;
    final pagination = json['pagination'] is Map
        ? Map<String, dynamic>.from(json['pagination'])
        : <String, dynamic>{};

    final jobs = jobsJson
        .whereType<Map>()
        .map((job) => JobModel.fromJson(Map<String, dynamic>.from(job)))
        .toList();

    return JobsPageResult(
      jobs: jobs,
      total: int.tryParse('${pagination['total'] ?? jobs.length}') ?? jobs.length,
      page: int.tryParse('${pagination['page'] ?? 1}') ?? 1,
      limit: int.tryParse('${pagination['limit'] ?? jobs.length}') ?? jobs.length,
      totalPages: int.tryParse('${pagination['totalPages'] ?? 1}') ?? 1,
      hasNextPage: pagination['hasNextPage'] == true,
      hasPreviousPage: pagination['hasPreviousPage'] == true,
    );
  }
}

class JobService {
  final String baseUrl = AppConfig.apiBaseUrl.endsWith('/')
      ? AppConfig.apiBaseUrl.substring(0, AppConfig.apiBaseUrl.length - 1)
      : AppConfig.apiBaseUrl;

  Future<List<JobModel>> getMyJobs(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/jobs/my-jobs?page=1&limit=100'),
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
    final result = await getJobsPage(page: page, limit: limit);
    return result.jobs;
  }

  Future<JobsPageResult> getJobsPage({
    int page = 1,
    int limit = 10,
    String? search,
    String? location,
    String? jobType,
    int? salaryMin,
    int? salaryMax,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    String status = 'OPEN',
  }) async {
    try {
      final response = await ApiClient.dio.get(
        'jobs',
        queryParameters: {
          'page': page,
          'limit': limit,
          'status': status,
          'sortBy': sortBy,
          'sortOrder': sortOrder,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (location != null && location.trim().isNotEmpty)
            'location': location.trim(),
          if (jobType != null && jobType.trim().isNotEmpty)
            'jobType': jobType.trim(),
          if (salaryMin != null) 'salaryMin': salaryMin,
          if (salaryMax != null) 'salaryMax': salaryMax,
        },
      );

      final data = response.data['data'] is Map
          ? Map<String, dynamic>.from(response.data['data'])
          : <String, dynamic>{};
      return JobsPageResult.fromJson(data);
    } on DioException catch (e) {
      throw Exception(_readableError(e, 'Failed to load jobs'));
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  Future<List<JobModel>> searchJobs({
    required String query,
    int page = 1,
    int limit = 10,
  }) async {
    final result = await getJobsPage(
      search: query,
      page: page,
      limit: limit,
    );
    return result.jobs;
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

    // Job creation request completed

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

  String _readableError(DioException error, String fallback) {
    if (error.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Connection timeout. Please try again.';
    }

    final statusCode = error.response?.statusCode;
    if (statusCode == 401) {
      return 'Session expired. Please login again.';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'Server error. Please try again later.';
    }

    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      final message = data['message'].toString().trim();
      if (message.isNotEmpty) return message;
    }

    final message = error.message?.trim();
    return message == null || message.isEmpty ? fallback : message;
  }
}
