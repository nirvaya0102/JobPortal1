import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class ApplicationService {
  Future<void> applyToJob({
    required String jobId,
    required File resumeFile,
    required String coverLetter,
    required Function(int sent, int total) onProgress,
  }) async {
    final fileName = resumeFile.path.split('/').last;

    final formData = FormData.fromMap({
      'coverLetter': coverLetter,
      'resume': await MultipartFile.fromFile(
        resumeFile.path,
        filename: fileName,
      ),
    });

    await ApiClient.dio.post(
      'jobs/$jobId/apply',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
      onSendProgress: onProgress,
    );
  }
}