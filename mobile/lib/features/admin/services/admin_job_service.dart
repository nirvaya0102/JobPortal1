import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../jobs/models/job_model.dart';

class AdminJobsPageResult {
  final List<JobModel> jobs;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const AdminJobsPageResult({
    required this.jobs,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory AdminJobsPageResult.fromJson(Map<String, dynamic> json) {
    final jobsJson = (json['jobs'] ?? []) as List;
    final pagination = json['pagination'] is Map
        ? Map<String, dynamic>.from(json['pagination'])
        : <String, dynamic>{};

    return AdminJobsPageResult(
      jobs: jobsJson
          .whereType<Map>()
          .map((job) => JobModel.fromJson(Map<String, dynamic>.from(job)))
          .toList(),
      total: int.tryParse('${pagination['total'] ?? jobsJson.length}') ??
          jobsJson.length,
      page: int.tryParse('${pagination['page'] ?? 1}') ?? 1,
      limit: int.tryParse('${pagination['limit'] ?? jobsJson.length}') ??
          jobsJson.length,
      totalPages: int.tryParse('${pagination['totalPages'] ?? 1}') ?? 1,
      hasNextPage: pagination['hasNextPage'] == true,
      hasPreviousPage: pagination['hasPreviousPage'] == true,
    );
  }
}

class AdminJobService {
  Future<AdminJobsPageResult> getJobs({
    String? status,
    String? search,
    int page = 1,
    int limit = 20,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    try {
      final response = await ApiClient.dio.get(
        'admin/jobs',
        queryParameters: {
          'page': page,
          'limit': limit,
          'sortBy': sortBy,
          'sortOrder': sortOrder,
          if (status != null && status.isNotEmpty) 'status': status,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
      );

      final data = response.data['data'] is Map
          ? Map<String, dynamic>.from(response.data['data'])
          : <String, dynamic>{};
      return AdminJobsPageResult.fromJson(data);
    } on DioException catch (e) {
      throw Exception(_readableError(e, 'Failed to load admin jobs'));
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  Future<JobModel> approveJob(String jobId) async {
    return _patchJob('admin/jobs/$jobId/approve');
  }

  Future<JobModel> rejectJob(String jobId, {String? rejectionReason}) async {
    return _patchJob(
      'admin/jobs/$jobId/reject',
      data: {
        if (rejectionReason != null && rejectionReason.trim().isNotEmpty)
          'rejectionReason': rejectionReason.trim(),
      },
    );
  }

  Future<JobModel> closeJob(String jobId) async {
    return _patchJob('admin/jobs/$jobId/close');
  }

  Future<JobModel> _patchJob(String path, {Map<String, dynamic>? data}) async {
    try {
      final response = await ApiClient.dio.patch(path, data: data);
      final responseData = response.data['data'] is Map
          ? Map<String, dynamic>.from(response.data['data'])
          : <String, dynamic>{};
      final jobJson = responseData['job'] is Map
          ? Map<String, dynamic>.from(responseData['job'])
          : responseData;
      return JobModel.fromJson(jobJson);
    } on DioException catch (e) {
      throw Exception(_readableError(e, 'Failed to update job'));
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
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
    if (error.response?.statusCode == 403) {
      return 'Only admins can perform this action.';
    }
    if (error.response?.statusCode == 401) {
      return 'Session expired. Please login again.';
    }

    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }

    return fallback;
  }
}
