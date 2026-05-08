import '../../../core/api/api_client.dart';
import '../models/job_model.dart';

class JobService {
  Future<List<JobModel>> getJobs({
    required int page,
    int limit = 10,
  }) async {
    final response = await ApiClient.dio.get(
      '/jobs',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    final data = response.data['data'];
    final jobsJson = data is List ? data : data['jobs'];

    return List<JobModel>.from(
      jobsJson.map((job) => JobModel.fromJson(job)),
    );
  }

  Future<JobModel> getJobById(String id) async {
  final response = await ApiClient.dio.get('/jobs/$id');

  final data = response.data['data'];

  final jobJson = data['job'] ?? data;

  return JobModel.fromJson(jobJson);
}
}