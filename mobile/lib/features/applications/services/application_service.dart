import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class ApplicationService {
  Future<void> applyToJob({
    required String jobId,
    required File resumeFile,
    required String email,
    required String phone,
    required String coverLetter,
    required Function(int sent, int total) onProgress,
  }) async {
    final fileName = resumeFile.path.split(RegExp(r'[/\\]')).last;

    final formData = FormData.fromMap({
      'email': email,
      'phone': phone,
      'coverLetter': coverLetter,
      'resume': await MultipartFile.fromFile(
        resumeFile.path,
        filename: fileName,
      ),
    });

    try {
      await ApiClient.dio.post(
        'jobs/$jobId/apply',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
        onSendProgress: onProgress,
      );
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? e.message ?? 'Failed to submit application';
      throw Exception(message);
    }
  }
}
