class ApplicationModel {
  final String id;
  final String jobId;
  final String candidateId;
  final String? coverLetter;
  final String status;
  final String appliedAt;
  final CandidateModel candidate;
  final String? resumeFileName;

  ApplicationModel({
    required this.id,
    required this.jobId,
    required this.candidateId,
    this.coverLetter,
    required this.status,
    required this.appliedAt,
    required this.candidate,
    this.resumeFileName,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['id'] ?? '',
      jobId: json['jobId'] ?? '',
      candidateId: json['candidateId'] ?? '',
      coverLetter: json['coverLetter'],
      status: json['status'] ?? 'PENDING',
      appliedAt: json['appliedAt'] ?? '',
      resumeFileName: json['resumeFileName'],
      candidate: CandidateModel.fromJson(json['candidate'] ?? {}),
    );
  }
}

class CandidateModel {
  final String id;
  final String name;
  final String email;

  CandidateModel({
    required this.id,
    required this.name,
    required this.email,
  });

  factory CandidateModel.fromJson(Map<String, dynamic> json) {
    return CandidateModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}
