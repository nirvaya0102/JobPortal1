import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../../../shared/widgets/candidate_footer.dart';
import '../../jobs/screens/candidate_main_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final int currentIndex;

  const NotificationsScreen({super.key, this.currentIndex = 0});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await _notificationService
          .getNotifications()
          .timeout(const Duration(seconds: 15));

      if (notifications.isEmpty) {
        // Generate demo notifications for testing, but don't block forever.
        await _notificationService.generateDemoNotifications().timeout(
          const Duration(seconds: 10),
        );
        final refreshed = await _notificationService.getNotifications().timeout(
          const Duration(seconds: 15),
        );
        setState(() {
          _notifications = refreshed;
        });
        return;
      }
      setState(() {
        _notifications = notifications;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notifications: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.read) return;
    try {
      await _notificationService.markAsRead(notification.id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = NotificationModel(
            id: notification.id,
            title: notification.title,
            message: notification.message,
            type: notification.type,
            read: true,
            createdAt: notification.createdAt,
            actionUrl: notification.actionUrl,
          );
        }
      });
    } catch (e) {
      // Error marking notification as read
    }
  }

  String _getTimeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData iconData;
    Color bgColor;
    Color iconColor;

    switch (type) {
      case NotificationType.jobAlert:
        iconData = Icons.work;
        bgColor = const Color(0xFFE5E7FA);
        iconColor = const Color(0xFF1E2785);
        break;
      case NotificationType.applicationViewed:
        iconData = Icons.fact_check;
        bgColor = const Color(0xFFFDF0D5);
        iconColor = const Color(0xFFF59E0B);
        break;
      case NotificationType.interviewScheduled:
        iconData = Icons.calendar_today;
        bgColor = const Color(0xFFE0F2E9);
        iconColor = const Color(0xFF10B981);
        break;
      case NotificationType.profileOptimization:
        iconData = Icons.person;
        bgColor = const Color(0xFFEFEFEF);
        iconColor = const Color(0xFF6B7280);
        break;
      default:
        iconData = Icons.notifications;
        bgColor = const Color(0xFFE5E7FA);
        iconColor = const Color(0xFF1E2785);
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  Widget _buildActionButton(NotificationModel notification) {
    if (notification.type == NotificationType.jobAlert) {
      return Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Text(
          'View Jobs',
          style: TextStyle(
            color: const Color(0xFF1E2785),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      );
    } else if (notification.type == NotificationType.interviewScheduled) {
      return Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF000B5E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: const Size(0, 36),
          ),
          child: const Text(
            'Join Meeting',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Color _getIndicatorColor(NotificationType type) {
    switch (type) {
      case NotificationType.jobAlert:
        return const Color(0xFF000B5E);
      case NotificationType.applicationViewed:
        return const Color(0xFFF59E0B);
      case NotificationType.interviewScheduled:
        return const Color(0xFF10B981);
      case NotificationType.profileOptimization:
        return const Color(0xFF9CA3AF);
      default:
        return const Color(0xFF000B5E);
    }
  }

  void _goToTab(int index) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => CandidateMainScreen(initialIndex: index),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), // Soft light background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF000B5E)),
          onPressed: () {},
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Rojgar',
              style: TextStyle(
                color: const Color(0xFF000B5E),
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Kendra',
              style: TextStyle(
                color: const Color(0xFF000B5E),
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              backgroundImage: const NetworkImage(
                'https://i.pravatar.cc/150?img=11',
              ), // Placeholder avatar
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 250,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFEDEEFD), Color(0x00EDEEFD)],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000B5E),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF000B5E),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        color: const Color(0xFF000B5E),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notification = _notifications[index];
                            return GestureDetector(
                              onTap: () => _markAsRead(notification),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Indicator line
                                      Container(
                                        width: 4,
                                        decoration: BoxDecoration(
                                          color: !notification.read
                                              ? _getIndicatorColor(
                                                  notification.type,
                                                )
                                              : Colors.transparent,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            bottomLeft: Radius.circular(16),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildNotificationIcon(
                                                notification.type,
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            notification.title,
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 15,
                                                                  color: Color(
                                                                    0xFF1F2937,
                                                                  ),
                                                                ),
                                                          ),
                                                        ),
                                                        Text(
                                                          _getTimeAgo(
                                                            notification
                                                                .createdAt,
                                                          ),
                                                          style:
                                                              const TextStyle(
                                                                color: Color(
                                                                  0xFF9CA3AF,
                                                                ),
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      notification.message,
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xFF4B5563,
                                                        ),
                                                        fontSize: 14,
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                    _buildActionButton(
                                                      notification,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: CandidateFooter(
        currentIndex: widget.currentIndex,
        onTap: _goToTab,
      ),
    );
  }
}
