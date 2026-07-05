class TicketTrackingModel {
  final String id;
  final String ticketId;
  final String action; // 'created', 'accepted_by_admin', 'forwarded_to_helpdesk', 'completed'
  final String? actorId;
  final String? actorName;
  final String? actorRole;
  final String description;
  final String createdAt;

  TicketTrackingModel({
    required this.id,
    required this.ticketId,
    required this.action,
    this.actorId,
    this.actorName,
    this.actorRole,
    required this.description,
    required this.createdAt,
  });

  factory TicketTrackingModel.fromMap(Map<String, dynamic> map) {
    return TicketTrackingModel(
      id: map['id']?.toString() ?? '',
      ticketId: map['ticket_id']?.toString() ?? '',
      action: map['action']?.toString() ?? '',
      actorId: map['actor_id']?.toString(),
      actorName: map['actor_name']?.toString(),
      actorRole: map['actor_role']?.toString(),
      description: map['description']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'action': action,
      'actor_id': actorId,
      'actor_name': actorName,
      'actor_role': actorRole,
      'description': description,
      'created_at': createdAt,
    };
  }
}
