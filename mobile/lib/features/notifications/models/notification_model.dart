enum NotificationType {
  jobAlert,
  applicationViewed,
  interviewScheduled,
  profileOptimization,
  general,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final bool read;
  final String? actionUrl;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    this.actionUrl,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: _parseType(json['type'] as String),
      read: json['read'] as bool? ?? false,
      actionUrl: json['actionUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static NotificationType _parseType(String type) {
    switch (type) {
      case 'JOB_ALERT':
        return NotificationType.jobAlert;
      case 'APPLICATION_VIEWED':
        return NotificationType.applicationViewed;
      case 'INTERVIEW_SCHEDULED':
        return NotificationType.interviewScheduled;
      case 'PROFILE_OPTIMIZATION':
        return NotificationType.profileOptimization;
      default:
        return NotificationType.general;
    }
  }
}
