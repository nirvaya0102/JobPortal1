import '../../../core/api/api_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await ApiClient.dio
          .get('notifications')
          .timeout(const Duration(seconds: 15));

      final body = response.data;

      final dynamic data = body is Map ? body['data'] : null;
      final dynamic list = data is List
          ? data
          : (data is Map ? (data['notifications'] ?? data['items']) : null);

      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(NotificationModel.fromJson)
            .toList();
      }

      return const <NotificationModel>[];
    } catch (e) {
      print('Error fetching notifications: $e');
      throw Exception('Failed to fetch notifications');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await ApiClient.dio
          .put('notifications/$id/read')
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      print('Error marking notification as read: $e');
      throw Exception('Failed to mark notification as read');
    }
  }

  Future<void> generateDemoNotifications() async {
    try {
      await ApiClient.dio
          .post('notifications/demo')
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      print('Error generating demo notifications: $e');
    }
  }
}
