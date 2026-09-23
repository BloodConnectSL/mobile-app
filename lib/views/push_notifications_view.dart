import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prana/controllers/push_notification_controller.dart';
import 'package:prana/models/blood_request_notification.dart';

class PushNotificationsView extends ConsumerStatefulWidget {
  const PushNotificationsView({super.key});

  @override
  ConsumerState<PushNotificationsView> createState() =>
      _PushNotificationsViewState();
}

class _PushNotificationsViewState
    extends ConsumerState<PushNotificationsView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(pushNotificationControllerProvider.notifier)
          .loadNotifications(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pushNotificationControllerProvider);
    final controller = ref.read(pushNotificationControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Blood requests${state.unreadCount == 0 ? '' : ' (${state.unreadCount})'}'),
        actions: [
          if (state.unreadCount > 0)
            IconButton(
              tooltip: 'Mark all as read',
              onPressed: controller.markAllAsRead,
              icon: const Icon(Icons.done_all),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: _NotificationBody(state: state, onRead: controller.markAsRead),
      ),
    );
  }
}

class _NotificationBody extends StatelessWidget {
  const _NotificationBody({required this.state, required this.onRead});

  final PushNotificationState state;
  final ValueChanged<String> onRead;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.notifications.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 180),
          Center(child: Text(state.errorMessage!)),
        ],
      );
    }
    if (state.notifications.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 180),
          Center(child: Text('No blood request notifications yet.')),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.notifications.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final notification = state.notifications[index];
        return _NotificationTile(notification: notification, onRead: onRead);
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onRead});

  final BloodRequestNotification notification;
  final ValueChanged<String> onRead;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final urgencyColor = notification.urgency == BloodRequestUrgency.critical
        ? colors.error
        : notification.urgency == BloodRequestUrgency.urgent
            ? colors.primary
            : colors.secondary;

    return Card(
      color: notification.isRead ? null : colors.primaryContainer.withAlpha(80),
      child: ListTile(
        onTap: () => onRead(notification.id),
        leading: CircleAvatar(
          backgroundColor: urgencyColor,
          foregroundColor: colors.onPrimary,
          child: const Icon(Icons.bloodtype),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${notification.message}\n${notification.hospitalName} | ${notification.bloodGroup}',
        ),
        isThreeLine: true,
        trailing: notification.isRead
            ? null
            : Icon(Icons.circle, size: 10, color: colors.primary),
      ),
    );
  }
}
