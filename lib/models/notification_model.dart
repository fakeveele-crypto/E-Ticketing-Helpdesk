class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String ticketId;
  final String timestamp;
  final String targetRole; // 'all', 'user', 'admin'
  final String targetUser; // username spesifik, atau 'all'
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.ticketId,
    required this.timestamp,
    required this.targetRole,
    required this.targetUser,
    this.isRead = false,
  });
}