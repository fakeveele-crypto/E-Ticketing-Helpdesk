class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String ticketId;
  final String recipientId;
  final String recipientRole;
  final String createdAt;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.ticketId,
    required this.recipientId,
    required this.recipientRole,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      ticketId: map['ticket_id']?.toString() ?? '',
      recipientId: map['recipient_id']?.toString() ?? '',
      recipientRole: map['recipient_role']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? '',
      isRead: map['is_read'] == true || map['is_read']?.toString() == 'true',
    );
  }
}
