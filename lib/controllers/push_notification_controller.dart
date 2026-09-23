import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prana/models/blood_request_notification.dart';
import 'package:prana/services/push_notification_service.dart';

class PushNotificationState {
  const PushNotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<BloodRequestNotification> notifications;
  final bool isLoading;
  final String? errorMessage;

  int get unreadCount => notifications.where((item) => !item.isRead).length;

  PushNotificationState copyWith({
    List<BloodRequestNotification>? notifications,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PushNotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class PushNotificationController
    extends Notifier<PushNotificationState> {
  PushNotificationService get _service => ref.read(pushNotificationServiceProvider);

  @override
  PushNotificationState build() => const PushNotificationState();

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final notifications = await _service.fetchNotifications();
      state = state.copyWith(notifications: notifications, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load blood request notifications.',
      );
    }
  }

  void markAsRead(String notificationId) {
    final notifications = state.notifications.map((notification) {
      if (notification.id != notificationId) return notification;
      return notification.copyWith(isRead: true);
    }).toList(growable: false);
    state = state.copyWith(notifications: notifications);
  }

  void markAllAsRead() {
    state = state.copyWith(
      notifications: state.notifications
          .map((notification) => notification.copyWith(isRead: true))
          .toList(growable: false),
    );
  }

  Future<void> refresh() => loadNotifications();
}

final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) => PushNotificationService());

final pushNotificationControllerProvider = NotifierProvider<
    PushNotificationController, PushNotificationState>(
  PushNotificationController.new,
);
