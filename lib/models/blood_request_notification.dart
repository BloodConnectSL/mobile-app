enum BloodRequestUrgency {
  normal('Normal'),
  urgent('Urgent'),
  critical('Critical');

  const BloodRequestUrgency(this.label);

  final String label;
}

class BloodRequestNotification {
  const BloodRequestNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.bloodGroup,
    required this.hospitalName,
    required this.createdAt,
    required this.urgency,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final String bloodGroup;
  final String hospitalName;
  final DateTime createdAt;
  final BloodRequestUrgency urgency;
  final bool isRead;

  BloodRequestNotification copyWith({bool? isRead}) {
    return BloodRequestNotification(
      id: id,
      title: title,
      message: message,
      bloodGroup: bloodGroup,
      hospitalName: hospitalName,
      createdAt: createdAt,
      urgency: urgency,
      isRead: isRead ?? this.isRead,
    );
  }
}
