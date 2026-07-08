class JobModel {
  final String id;
  final String? jobCode;
  final String title;
  final String? companyName;
  final String? companyLogo;
  final String? companyDescription;
  final String? companyLocation;
  final String? companyWebsite;
  final String? location;
  final String? salary;
  final String? type;
  final String? description;
  final String status;
  final int applicantsCount;
  final int? salaryMin;
  final int? salaryMax;
  final String? createdAt;
  final String? createdById;
  final String? rejectionReason;
  final String? employerName;
  final String? employerEmail;

  JobModel({
    required this.id,
    this.jobCode,
    required this.title,
    this.companyName,
    this.companyLogo,
    this.companyDescription,
    this.companyLocation,
    this.companyWebsite,
    this.location,
    this.salary,
    this.type,
    this.description,
    required this.status,
    required this.applicantsCount,
    this.salaryMin,
    this.salaryMax,
    this.createdAt,
    this.createdById,
    this.rejectionReason,
    this.employerName,
    this.employerEmail,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    int parsedApplicantsCount = 0;

    if (json['applicantsCount'] != null) {
      parsedApplicantsCount =
          int.tryParse(json['applicantsCount'].toString()) ?? 0;
    } else if (json['_count'] != null &&
        json['_count']['applications'] != null) {
      parsedApplicantsCount =
          int.tryParse(json['_count']['applications'].toString()) ?? 0;
    }

    final salaryMin = int.tryParse(json['salaryMin']?.toString() ?? '');
    final salaryMax = int.tryParse(json['salaryMax']?.toString() ?? '');

    String? salaryText;
    if (salaryMin != null && salaryMax != null) {
      salaryText = 'Rs $salaryMin - Rs $salaryMax';
    } else if (salaryMin != null) {
      salaryText = 'From Rs $salaryMin';
    } else if (salaryMax != null) {
      salaryText = 'Up to Rs $salaryMax';
    } else {
      salaryText = json['salary']?.toString() ?? 'Negotiable';
    }

    final company = json['company'];
    final employer = json['employer'];
    final createdBy = json['createdBy'];

    return JobModel(
      id: json['id']?.toString() ?? '',
      jobCode: json['jobCode']?.toString(),
      title: json['title']?.toString() ?? 'Untitled Job',
      companyName: company is Map
          ? company['name']?.toString()
          : json['companyName']?.toString(),
      companyLogo: company is Map
          ? company['logo']?.toString()
          : json['companyLogo']?.toString(),
      companyDescription:
          company is Map ? company['description']?.toString() : null,
      companyLocation: company is Map ? company['location']?.toString() : null,
      companyWebsite: company is Map ? company['website']?.toString() : null,
      location: json['location']?.toString(),
      salary: salaryText,
      type: (json['type'] ?? json['jobType'])?.toString(),
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? '',
      applicantsCount: parsedApplicantsCount,
      salaryMin: salaryMin,
      salaryMax: salaryMax,
      createdAt: json['createdAt']?.toString(),
      createdById: json['createdById']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
      employerName: employer is Map
          ? employer['name']?.toString()
          : createdBy is Map
          ? createdBy['name']?.toString()
          : null,
      employerEmail: employer is Map
          ? employer['email']?.toString()
          : createdBy is Map
          ? createdBy['email']?.toString()
          : null,
    );
  }
}
