class JobModel {
  final String id;
  final String title;
  final String? companyName;
  final String? companyLogo;
  final String? location;
  final String? salary;
  final String? type;
  final String? description;

  JobModel({
    required this.id,
    required this.title,
    this.companyName,
    this.companyLogo,
    this.location,
    this.salary,
    this.type,
    this.description,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled Job',
      companyName: json['company']?['name'] ?? json['companyName'],
      companyLogo: json['company']?['logo'] ?? json['companyLogo'],
      location: json['location'],
      salary: json['salary']?.toString(),
      type: json['type'],
      description: json['description'],
    );
  }
}