import 'package:prana/models/blood_request_notification.dart';

class PushNotificationService {
  Future<List<BloodRequestNotification>> fetchNotifications() async {
    // Replace this fixture with the authenticated push/API integration.
    final now = DateTime.now();
    return [
      BloodRequestNotification(
        id: 'request-001',
        title: 'Urgent blood request',
        message: 'A nearby patient needs a compatible donor today.',
        bloodGroup: 'O+',
        hospitalName: 'National Hospital of Sri Lanka',
        createdAt: now.subtract(const Duration(minutes: 12)),
        urgency: BloodRequestUrgency.urgent,
      ),
      BloodRequestNotification(
        id: 'request-002',
        title: 'Blood drive reminder',
        message: 'Your preferred donation centre is accepting donors.',
        bloodGroup: 'A+',
        hospitalName: 'Colombo Central Donor Point',
        createdAt: now.subtract(const Duration(hours: 3)),
        urgency: BloodRequestUrgency.normal,
        isRead: true,
      ),
    ];
  }
}
