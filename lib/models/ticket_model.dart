class TicketModel {
  final String id;
  final String ticketCode;
  final String title;
  final String description;
  final String category;
  String status;
  final String priority;
  final String createdBy;
  final String createdAt;
  String? assignedTo;
  String? urlFoto;
  String? receivedByAdminAt; // Timestamp when admin received/accepted ticket
  String? forwardedToHelpdeskAt; // Timestamp when forwarded to helpdesk
  String? completedAt; // Timestamp when helpdesk completed
  List<CommentModel> comments;

  TicketModel({
    required this.id,
    required this.ticketCode,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    required this.createdBy,
    required this.createdAt,
    this.assignedTo,
    this.urlFoto,
    this.receivedByAdminAt,
    this.forwardedToHelpdeskAt,
    this.completedAt,
    List<CommentModel>? comments,
  }) : comments = comments ?? [];

  static String normalizeStatus(String? status) {
    final raw = status?.toString().trim().toLowerCase();
    switch (raw) {
      case 'open':
        return 'new';
      case 'in_progress':
        return 'on_progress';
      case 'closed':
      case 'resolved':
      case 'completed':
        return 'completed';
      case 'new':
        return 'new';
      default:
        return raw ?? 'new';
    }
  }

  factory TicketModel.fromMap(Map<String, dynamic> map) {
    final rawUrl = map['url_foto'] as String?;
    return TicketModel(
      id: map['id']?.toString() ?? '',
      ticketCode: map['ticket_code']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      status: normalizeStatus(map['status']?.toString()),
      priority: map['priority']?.toString() ?? 'normal',
      createdBy: map['created_by']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? '',
      assignedTo: (map['assigned_to'] as String?)?.isEmpty ?? true
          ? null
          : map['assigned_to']?.toString(),
      urlFoto: rawUrl == null || rawUrl.isEmpty ? null : rawUrl,
      receivedByAdminAt: map['received_by_admin_at']?.toString(),
      forwardedToHelpdeskAt: map['forwarded_to_helpdesk_at']?.toString(),
      completedAt: map['completed_at']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticket_code': ticketCode,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'priority': priority,
      'created_by': createdBy,
      'received_by_admin_at': receivedByAdminAt,
      'forwarded_to_helpdesk_at': forwardedToHelpdeskAt,
      'completed_at': completedAt,
      'created_at': createdAt,
      'assigned_to': assignedTo,
      'url_foto': urlFoto ?? '',
    };
  }
}

class CommentModel {
  final String id;
  final String ticketId;
  final String userId;
  final String message;
  final String createdAt;

  CommentModel({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.message,
    required this.createdAt,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id']?.toString() ?? '',
      ticketId: map['ticket_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? '',
    );
  }
}

class UserModel {
  final String id;
  final String username;
  final String name;
  final String role;
  final String email;

  UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    required this.email,
  });
}
