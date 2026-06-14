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
      id: json['id'] ?? '',
      jobId: json['jobId'] ?? '',
      candidateId: json['candidateId'] ?? '',
      applicantEmail: json['applicantEmail'],
      applicantPhone: json['applicantPhone'],
      coverLetter: json['coverLetter'],
      status: json['status'] ?? 'PENDING',
      appliedAt: json['appliedAt'] ?? '',
      resumeFileName: json['resumeFileName'],
      candidate: CandidateModel.fromJson(json['candidate'] ?? {}),
      job: json['job'] != null ? JobModel.fromJson(Map<String, dynamic>.from(json['job'])) : null,
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
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}
