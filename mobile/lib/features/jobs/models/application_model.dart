import 'job_model.dart';

class ApplicationModel {
  final String id;
  final String jobId;
  final String candidateId;
  final String? applicantEmail;
  final String? applicantPhone;
  final String? coverLetter;
  final String status;
  final String appliedAt;
  final CandidateModel candidate;
  final String? resumeFileName;
  final JobModel? job;

  ApplicationModel({
    required this.id,
    required this.jobId,
    required this.candidateId,
    this.applicantEmail,
    this.applicantPhone,
    this.coverLetter,
    required this.status,
    required this.appliedAt,
    required this.candidate,
    this.resumeFileName,
    this.job,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['id']?.toString() ?? '',
      jobId: json['jobId']?.toString() ?? '',
      candidateId: json['candidateId']?.toString() ?? '',
      applicantEmail: json['applicantEmail']?.toString(),
      applicantPhone: json['applicantPhone']?.toString(),
      coverLetter: json['coverLetter']?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      appliedAt: json['appliedAt']?.toString() ?? '',
      resumeFileName: json['resumeFileName']?.toString(),
      candidate: CandidateModel.fromJson(
        json['candidate'] is Map
            ? Map<String, dynamic>.from(json['candidate'])
            : <String, dynamic>{},
      ),
      job: json['job'] is Map
          ? JobModel.fromJson(Map<String, dynamic>.from(json['job']))
          : null,
    );
  }
}

class CandidateModel {
  final String id;
  final String name;
  final String email;
  final String phone;

  CandidateModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory CandidateModel.fromJson(Map<String, dynamic> json) {
    return CandidateModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }
}
