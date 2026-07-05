import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ticket_model.dart';
import '../models/ticket_tracking_model.dart';
import '../providers/app_provider.dart';

/// Widget to display ticket tracking/history
class TicketTrackingWidget extends StatelessWidget {
  final String ticketId;

  const TicketTrackingWidget({
    Key? key,
    required this.ticketId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final tracking = provider.getTicketTrackingHistory(ticketId);
        final ticket = provider.getTicketById(ticketId);

        if (ticket == null) {
          return const Center(child: Text('Tiket tidak ditemukan'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Tracking Tiket',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (tracking.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Belum ada aktivitas'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tracking.length,
                itemBuilder: (context, index) {
                  final track = tracking[index];
                  return _buildTrackingItem(context, track, index == tracking.length - 1);
                },
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSummaryCard(context, ticket),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrackingItem(
    BuildContext context,
    TicketTrackingModel track,
    bool isLast,
  ) {
    final actionEmoji = _getActionEmoji(track.action);
    final actionLabel = _getActionLabel(track.action);

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: _getActionColor(track.action),
                    child: Text(
                      actionEmoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 40,
                      color: Colors.grey[300],
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        actionLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        track.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (track.actorName != null)
                        Text(
                          'Oleh: ${track.actorName}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      Text(
                        _formatDateTime(track.createdAt),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (!isLast) const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, TicketModel ticket) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Status',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            _buildStatusLine(
              '• Dibuat pada',
              _formatDateTime(ticket.createdAt),
            ),
            if (ticket.receivedByAdminAt != null)
              _buildStatusLine(
                '• Diterima admin pada',
                _formatDateTime(ticket.receivedByAdminAt!),
              ),
            if (ticket.forwardedToHelpdeskAt != null)
              _buildStatusLine(
                '• Diforward ke helpdesk pada',
                _formatDateTime(ticket.forwardedToHelpdeskAt!),
              ),
            if (ticket.completedAt != null)
              _buildStatusLine(
                '• Diselesaikan pada',
                _formatDateTime(ticket.completedAt!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
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

  String _getActionEmoji(String action) {
    switch (action) {
      case 'created':
        return '📝';
      case 'accepted_by_admin':
        return '✅';
      case 'forwarded_to_helpdesk':
        return '📤';
      case 'accepted_by_helpdesk':
        return '🔧';
      case 'completed':
        return '✨';
      default:
        return '•';
    }
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'created':
        return 'Tiket Dibuat';
      case 'accepted_by_admin':
        return 'Diterima Admin';
      case 'forwarded_to_helpdesk':
        return 'Diforward ke Helpdesk';
      case 'accepted_by_helpdesk':
        return 'Diterima Helpdesk';
      case 'completed':
        return 'Diselesaikan';
      default:
        return action;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'created':
        return Colors.blue;
      case 'accepted_by_admin':
        return Colors.orange;
      case 'forwarded_to_helpdesk':
        return Colors.purple;
      case 'accepted_by_helpdesk':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} jam yang lalu';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} menit yang lalu';
      } else {
        return 'Baru saja';
      }
    } catch (e) {
      return isoString;
    }
  }
}

/// Widget for Admin to manage ticket workflow
class AdminTicketActionsWidget extends StatefulWidget {
  final String ticketId;

  const AdminTicketActionsWidget({
    Key? key,
    required this.ticketId,
  }) : super(key: key);

  @override
  State<AdminTicketActionsWidget> createState() =>
      _AdminTicketActionsWidgetState();
}

class _AdminTicketActionsWidgetState extends State<AdminTicketActionsWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final ticket = provider.getTicketById(widget.ticketId);

        if (ticket == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (ticket.receivedByAdminAt == null)
                _buildButton(
                  label: 'Terima Tiket',
                  onPressed: _isLoading ? null : () => _acceptTicket(provider),
                  color: Colors.orange,
                  isLoading: _isLoading,
                )
              else if (ticket.forwardedToHelpdeskAt == null)
                _buildAssignToHelpdeskButton(provider)
              else
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Chip(
                    label: const Text('Tiket sudah diforward'),
                    backgroundColor: Colors.green.withOpacity(0.2),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssignToHelpdeskButton(AppProvider provider) {
    return FutureBuilder<List<UserModel>>(
      future: _getHelpdeskUsers(provider),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final helpdeskUsers = snapshot.data ?? [];

        if (helpdeskUsers.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Tidak ada staff helpdesk tersedia'),
          );
        }

        return Column(
          children: [
            Text(
              'Pilih Helpdesk untuk ditugaskan:',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              isExpanded: true,
              hint: const Text('Pilih helpdesk...'),
              items: helpdeskUsers
                  .map((user) => DropdownMenuItem(
                        value: user.id,
                        child: Text(user.name),
                      ))
                  .toList(),
              onChanged: _isLoading
                  ? null
                  : (value) {
                      if (value != null) {
                        _forwardToHelpdesk(provider, value);
                      }
                    },
            ),
          ],
        );
      },
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback? onPressed,
    required Color color,
    required bool isLoading,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }

  Future<void> _acceptTicket(AppProvider provider) async {
    setState(() => _isLoading = true);
    try {
      await provider.acceptTicketAsAdmin(widget.ticketId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiket berhasil diterima')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forwardToHelpdesk(AppProvider provider, String helpdeskId) async {
    setState(() => _isLoading = true);
    try {
      await provider.forwardTicketToHelpdesk(widget.ticketId, helpdeskId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiket berhasil diforward ke helpdesk')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<UserModel>> _getHelpdeskUsers(AppProvider provider) async {
    // This should query your user database for helpdesk staff
    // For now, returning empty list - implement based on your backend
    return [];
  }
}

/// Widget for Helpdesk to manage ticket workflow
class HelpdeskTicketActionsWidget extends StatefulWidget {
  final String ticketId;

  const HelpdeskTicketActionsWidget({
    Key? key,
    required this.ticketId,
  }) : super(key: key);

  @override
  State<HelpdeskTicketActionsWidget> createState() =>
      _HelpdeskTicketActionsWidgetState();
}

class _HelpdeskTicketActionsWidgetState extends State<HelpdeskTicketActionsWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final ticket = provider.getTicketById(widget.ticketId);

        if (ticket == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (ticket.status == 'in_progress' && ticket.completedAt == null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _completeTicket(provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Tandai Selesai'),
                  ),
                )
              else if (ticket.completedAt != null)
                Chip(
                  label: const Text('Tiket sudah diselesaikan'),
                  backgroundColor: Colors.green.withOpacity(0.2),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _completeTicket(AppProvider provider) async {
    setState(() => _isLoading = true);
    try {
      await provider.completeTicketByHelpdesk(widget.ticketId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiket berhasil diselesaikan')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
