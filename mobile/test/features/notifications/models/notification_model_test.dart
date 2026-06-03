import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/notifications/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    group('fromJson', () {
      test('creates NotificationModel from complete JSON', () {
        final json = {
          'id': 'notif1',
          'title': 'New Job Alert',
          'message': 'Flutter Developer job posted',
          'type': 'JOB_ALERT',
          'read': false,
          'actionUrl': '/job/123',
          'createdAt': '2025-06-01T10:30:00Z',
        };

        final notification = NotificationModel.fromJson(json);

        expect(notification.id, 'notif1');
        expect(notification.title, 'New Job Alert');
        expect(notification.message, 'Flutter Developer job posted');
        expect(notification.type, NotificationType.jobAlert);
        expect(notification.read, false);
        expect(notification.actionUrl, '/job/123');
        expect(notification.createdAt, DateTime.parse('2025-06-01T10:30:00Z'));
      });

      test('parses JOB_ALERT type correctly', () {
        final json = {
          'id': 'notif1',
          'title': 'Alert',
          'message': 'msg',
          'type': 'JOB_ALERT',
          'read': false,
          'createdAt': '2025-06-01T10:30:00Z',
        };

        final notification = NotificationModel.fromJson(json);

        expect(notification.type, NotificationType.jobAlert);
      });

      test('parses APPLICATION_VIEWED type correctly', () {
        final json = {
          'id': 'notif2',
          'title': 'Application Viewed',
          'message': 'Your application was viewed',
          'type': 'APPLICATION_VIEWED',
          'read': true,
          'createdAt': '2025-06-01T10:30:00Z',
        };

        final notification = NotificationModel.fromJson(json);

        expect(notification.type, NotificationType.applicationViewed);
        expect(notification.read, true);
      });

      test('parses INTERVIEW_SCHEDULED type correctly', () {
        final json = {
          'id': 'notif3',
          'title': 'Interview Scheduled',
          'message': 'Your interview is scheduled',
          'type': 'INTERVIEW_SCHEDULED',
          'read': false,
          'createdAt': '2025-06-01T14:00:00Z',
        };

        final notification = NotificationModel.fromJson(json);

        expect(notification.type, NotificationType.interviewScheduled);
      });

      test('parses PROFILE_OPTIMIZATION type correctly', () {
        final json = {
          'id': 'notif4',
          'title': 'Profile Tip',
          'message': 'Complete your profile',
          'type': 'PROFILE_OPTIMIZATION',
          'read': false,
          'createdAt': '2025-06-01T10:30:00Z',
        };

        final notification = NotificationModel.fromJson(json);

        expect(notification.type, NotificationType.profileOptimization);
      });

      test('defaults to general type for unknown type', () {
        final json = {
          'id': 'notif5',
          'title': 'General',
          'message': 'Generic message',
          'type': 'UNKNOWN_TYPE',
          'read': false,
          'createdAt': '2025-06-01T10:30:00Z',
        };

        final notification = NotificationModel.fromJson(json);

        expect(notification.type, NotificationType.general);
      });

      test('defaults read to false when missing', () {
        final json = {
          'id': 'notif6',
          'title': 'Title',
          'message': 'Message',
          'type': 'JOB_ALERT',
          'createdAt': '2025-06-01T10:30:00Z',
        };

        final notification = NotificationModel.fromJson(json);

        expect(notification.read, false);
      });

      test('handles nullable actionUrl', () {
        final json = {
          'id': 'notif7',
          'title': 'Title',
          'message': 'Message',
          'type': 'GENERAL',
          'read': false,
          'createdAt': '2025-06-01T10:30:00Z',
        };

        final notification = NotificationModel.fromJson(json);

        expect(notification.actionUrl, isNull);
      });

      test('parses createdAt date correctly', () {
        final json = {
          'id': 'notif8',
          'title': 'Title',
          'message': 'Message',
          'type': 'JOB_ALERT',
          'read': false,
          'createdAt': '2025-12-31T23:59:59Z',
        };

        final notification = NotificationModel.fromJson(json);

        final expectedDate = DateTime.parse('2025-12-31T23:59:59Z');
        expect(notification.createdAt, expectedDate);
      });
    });

    group('Constructor', () {
      test('creates NotificationModel with all fields', () {
        final createdAt = DateTime.parse('2025-06-01T10:30:00Z');

        final notification = NotificationModel(
          id: 'notif1',
          title: 'New Job',
          message: 'Job posted',
          type: NotificationType.jobAlert,
          read: true,
          actionUrl: '/jobs/123',
          createdAt: createdAt,
        );

        expect(notification.id, 'notif1');
        expect(notification.title, 'New Job');
        expect(notification.type, NotificationType.jobAlert);
        expect(notification.read, true);
        expect(notification.actionUrl, '/jobs/123');
      });

      test('allows nullable actionUrl', () {
        final createdAt = DateTime.parse('2025-06-01T10:30:00Z');

        final notification = NotificationModel(
          id: 'notif2',
          title: 'Alert',
          message: 'Message',
          type: NotificationType.general,
          read: false,
          createdAt: createdAt,
        );

        expect(notification.actionUrl, isNull);
      });
    });

    group('NotificationType enum', () {
      test('has all required types', () {
        expect(NotificationType.jobAlert, isNotNull);
        expect(NotificationType.applicationViewed, isNotNull);
        expect(NotificationType.interviewScheduled, isNotNull);
        expect(NotificationType.profileOptimization, isNotNull);
        expect(NotificationType.general, isNotNull);
      });
    });
  });
}
