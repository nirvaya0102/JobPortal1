class JobModel {
  final String id;
  final String title;
  final String? companyName;
  final String? companyLogo;
  final String? location;
  final String? salary;
  final String? type;
  final String? description;
   final String status;
    final int applicantsCount;

  JobModel({
    required this.id,
    required this.title,
    this.companyName,
    this.companyLogo,
    this.location,
    this.salary,
    this.type,
    this.description,
     required this.status,
        required this.applicantsCount,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    int parsedApplicantsCount = 0;
    if (json['applicantsCount'] != null) {
      parsedApplicantsCount = int.tryParse(json['applicantsCount'].toString()) ?? 0;
    } else if (json['_count'] != null && json['_count']['applications'] != null) {
      parsedApplicantsCount = int.tryParse(json['_count']['applications'].toString()) ?? 0;
    }

    return JobModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Job',
      companyName: (json['company'] is Map ? json['company']['name'] : null)?.toString() ?? json['companyName']?.toString(),
      companyLogo: (json['company'] is Map ? json['company']['logo'] : null)?.toString() ?? json['companyLogo']?.toString(),
      location: json['location']?.toString(),
      salary: json['salary']?.toString(),
      type: (json['type'] ?? json['jobType'])?.toString(),
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? '',
      applicantsCount: parsedApplicantsCount,
    );
  }
}