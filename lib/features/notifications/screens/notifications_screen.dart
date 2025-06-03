// lib/features/notifications/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/utils/theme_utils.dart';
import 'package:cleanslate/data/services/notification_service.dart';
import 'package:cleanslate/data/models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Reload notifications when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationService>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor:
            isDarkMode ? AppColors.backgroundDark : AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primary,
            fontFamily: 'Switzer',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primary,
            ),
            onSelected: (value) async {
              final service = context.read<NotificationService>();
              switch (value) {
                case 'mark_all_read':
                  await service.markAllAsRead();
                  break;
                case 'clear_all':
                  _showClearAllConfirmation();
                  break;
              }
            },
            itemBuilder:
                (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        Icon(
                          Icons.done_all,
                          color:
                              isDarkMode
                                  ? AppColors.textPrimaryDark
                                  : AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Mark all as read',
                          style: TextStyle(
                            color:
                                isDarkMode
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                            fontFamily: 'VarelaRound',
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, color: AppColors.error, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Clear all',
                          style: TextStyle(
                            color: AppColors.error,
                            fontFamily: 'VarelaRound',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Consumer<NotificationService>(
        builder: (context, service, child) {
          if (service.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
              ),
            );
          }

          if (service.notifications.isEmpty) {
            return _buildEmptyState(isDarkMode);
          }

          return RefreshIndicator(
            onRefresh: () => service.loadNotifications(),
            color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: service.notifications.length,
              itemBuilder: (context, index) {
                final notification = service.notifications[index];
                return _buildNotificationTile(notification, isDarkMode);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color:
                isDarkMode
                    ? AppColors.textSecondaryDark.withOpacity(0.5)
                    : AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color:
                  isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
              fontFamily: 'Switzer',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: 16,
              color:
                  isDarkMode
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
              fontFamily: 'VarelaRound',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(
    NotificationModel notification,
    bool isDarkMode,
  ) {
    final service = context.read<NotificationService>();

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        service.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // Implement undo if needed
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color:
              notification.isRead
                  ? (isDarkMode
                      ? AppColors.surfaceDark.withOpacity(0.5)
                      : AppColors.surface.withOpacity(0.5))
                  : (isDarkMode ? AppColors.surfaceDark : AppColors.surface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? AppColors.borderDark : AppColors.border,
            width: notification.isRead ? 0.5 : 1,
          ),
        ),
        child: ListTile(
          onTap: () async {
            if (!notification.isRead) {
              await service.markAsRead(notification.id);
            }
            _handleNotificationTap(notification);
          },
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: notification.getColor().withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              notification.getIcon(),
              color: notification.getColor(),
              size: 24,
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
              color:
                  isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
              fontFamily: 'Switzer',
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.message,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                  fontFamily: 'VarelaRound',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                notification.getTimeAgo(),
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDarkMode
                          ? AppColors.textSecondaryDark.withOpacity(0.7)
                          : AppColors.textSecondary.withOpacity(0.7),
                  fontFamily: 'VarelaRound',
                ),
              ),
            ],
          ),
          trailing:
              !notification.isRead
                  ? Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? AppColors.primaryDark
                              : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  )
                  : null,
        ),
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Handle navigation based on notification type
    switch (notification.type) {
      case 'chore_created':
      case 'chore_assigned':
      case 'deadline_approaching':
        // Navigate to chore details or home screen
        Navigator.pop(context);
        break;
      case 'member_joined':
        // Navigate to members screen
        Navigator.pop(context);
        break;
      default:
        break;
    }
  }

  void _showClearAllConfirmation() {
    final isDarkMode = ThemeUtils.isDarkMode(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Clear All Notifications',
            style: TextStyle(
              color:
                  isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
              fontFamily: 'Switzer',
            ),
          ),
          content: Text(
            'Are you sure you want to clear all notifications? This action cannot be undone.',
            style: TextStyle(
              color:
                  isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
              fontFamily: 'VarelaRound',
            ),
          ),
          backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color:
                      isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await context
                    .read<NotificationService>()
                    .clearAllNotifications();
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }
}
