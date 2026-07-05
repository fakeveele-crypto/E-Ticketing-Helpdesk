import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ticket_model.dart';
import '../providers/app_provider.dart';
import '../widgets/ticket_workflow_widgets.dart';

/// Example: Enhanced Ticket Detail Screen with Workflow
/// This shows how to integrate the ticket workflow system into your detail screens
class EnhancedTicketDetailScreen extends StatelessWidget {
  final String ticketId;

  const EnhancedTicketDetailScreen({
    Key? key,
    required this.ticketId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tiket'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final ticket = provider.getTicketById(ticketId);

          if (ticket == null) {
            return const Center(child: Text('Tiket tidak ditemukan'));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // 1. Ticket Header with Status Badge
                _buildTicketHeader(context, ticket),

                // 2. Ticket Details
                _buildTicketDetails(context, ticket),

                // 3. Status Badge with Current State
                _buildStatusSection(context, ticket),

                // 4. Role-Based Actions (Admin, Helpdesk)
                if (provider.currentUser != null)
                  _buildRoleBasedActions(context, provider, ticket),

                // 5. Comments Section
                _buildCommentsSection(context, provider, ticket),

                // 6. Ticket Tracking/History (NEW)
                TicketTrackingWidget(ticketId: ticketId),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTicketHeader(BuildContext context, TicketModel ticket) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.ticketCode,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    Text(
                      ticket.title,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildStatusChip(ticket.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Chip(
                label: Text(ticket.category),
                backgroundColor: Colors.blue.withOpacity(0.2),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(ticket.priority),
                backgroundColor: _getPriorityColor(ticket.priority),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'new':
        color = Colors.orange;
        label = 'Baru';
        break;
      case 'in_progress':
        color = Colors.blue;
        label = 'Diproses';
        break;
      case 'completed':
        color = Colors.green;
        label = 'Selesai';
        break;
      case 'closed':
        color = Colors.grey;
        label = 'Ditutup';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTicketDetails(BuildContext context, TicketModel ticket) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deskripsi',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(ticket.description),
          const SizedBox(height: 20),
          _buildDetailRow('Dibuat oleh', ticket.createdBy),
          if (ticket.assignedTo != null)
            _buildDetailRow('Ditugaskan ke', ticket.assignedTo!),
          _buildDetailRow('Kategori', ticket.category),
          _buildDetailRow('Prioritas', ticket.priority),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, TicketModel ticket) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status Saat Ini',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _buildStatusTimeline(ticket),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(TicketModel ticket) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimelineStep(
          '1. Dibuat',
          ticket.createdAt,
          true,
        ),
        _buildTimelineStep(
          '2. Diterima Admin',
          ticket.receivedByAdminAt ?? 'Menunggu...',
          ticket.receivedByAdminAt != null,
        ),
        _buildTimelineStep(
          '3. Diproses Helpdesk',
          ticket.forwardedToHelpdeskAt ?? 'Menunggu...',
          ticket.forwardedToHelpdeskAt != null,
        ),
        _buildTimelineStep(
          '4. Selesai',
          ticket.completedAt ?? 'Menunggu...',
          ticket.completedAt != null,
        ),
      ],
    );
  }

  Widget _buildTimelineStep(String label, String timestamp, bool completed) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? Colors.green : Colors.grey[300],
          ),
          child: Center(
            child: Icon(
              completed ? Icons.check : Icons.schedule,
              size: 12,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              Text(
                _formatTimestamp(timestamp),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(String timestamp) {
    if (timestamp == 'Menunggu...') return timestamp;
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  Widget _buildRoleBasedActions(
    BuildContext context,
    AppProvider provider,
    TicketModel ticket,
  ) {
    final userRole = provider.currentUser?.role;

    if (userRole == 'admin') {
      return AdminTicketActionsWidget(ticketId: ticket.id);
    } else if (userRole == 'helpdesk') {
      return HelpdeskTicketActionsWidget(ticketId: ticket.id);
    }

    return const SizedBox.shrink();
  }

  Widget _buildCommentsSection(
    BuildContext context,
    AppProvider provider,
    TicketModel ticket,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Komentar (${ticket.comments.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ticket.comments.length,
            itemBuilder: (context, index) {
              final comment = ticket.comments[index];
              return _buildCommentCard(context, comment);
            },
          ),
          const SizedBox(height: 12),
          _buildCommentInput(context, provider, ticket),
        ],
      ),
    );
  }

  Widget _buildCommentCard(BuildContext context, CommentModel comment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  comment.userId,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  _formatCommentTime(comment.createdAt),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(comment.message),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput(
    BuildContext context,
    AppProvider provider,
    TicketModel ticket,
  ) {
    final controller = TextEditingController();
    bool isSubmitting = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Tambah komentar...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (controller.text.trim().isEmpty) return;
                      setState(() => isSubmitting = true);
                      try {
                        await provider.addComment(
                          ticket.id,
                          controller.text.trim(),
                        );
                        controller.clear();
                      } catch (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $error')),
                        );
                      } finally {
                        setState(() => isSubmitting = false);
                      }
                    },
              icon: isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        );
      },
    );
  }

  String _formatCommentTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h';
      } else {
        return '${difference.inDays}d';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

/// Integration Notes:
/// 
/// 1. Replace your existing ticket detail screens with this enhanced version
/// 
/// 2. Update your route to pass the ticket ID:
///    Navigator.push(
///      context,
///      MaterialPageRoute(
///        builder: (context) => EnhancedTicketDetailScreen(ticketId: ticket.id),
///      ),
///    );
/// 
/// 3. The workflow is now fully integrated:
///    - Users see ticket tracking and comments
///    - Admins see accept and forward buttons
///    - Helpdesk sees completion button
///    - All roles see real-time status updates
/// 
/// 4. Make sure your database is migrated with the new columns:
///    - received_by_admin_at
///    - forwarded_to_helpdesk_at
///    - completed_at
///    - And the ticket_tracking table
/// 
/// 5. Test the complete workflow:
///    - Create ticket as user
///    - Accept as admin
///    - Forward to helpdesk
///    - Complete as helpdesk
///    - Verify tracking shows all steps
