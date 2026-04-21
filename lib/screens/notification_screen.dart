import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/notification_model.dart';
import 'ticket_detail_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final scheme = Theme.of(context).colorScheme;
    final notifications = provider.myNotifications;
    final isAdmin = provider.currentUser?.role != 'user';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        centerTitle: true,
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () => provider.markAllRead(),
              child: const Text('Tandai semua'),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_outlined,
                      size: 72, color: scheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('Tidak ada notifikasi',
                      style: TextStyle(
                          fontSize: 16, color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text('Notifikasi akan muncul di sini',
                      style: TextStyle(
                          fontSize: 13, color: scheme.onSurfaceVariant)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, i) {
                final notif = notifications[i];
                return _NotifTile(
                  notif: notif,
                  onTap: () {
                    // Tandai sudah dibaca
                    provider.markOneRead(notif.id);

                    // Navigasi ke detail tiket
                    final ticket = provider.getTicketById(notif.ticketId);
                    if (ticket != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TicketDetailScreen(
                            ticket: ticket,
                            isAdmin: isAdmin,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tiket tidak ditemukan')),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback onTap;

  const _NotifTile({required this.notif, required this.onTap});

  IconData get _icon {
    if (notif.title.contains('Baru')) return Icons.fiber_new_outlined;
    if (notif.title.contains('Selesai')) return Icons.check_circle_outline;
    if (notif.title.contains('Komentar')) return Icons.comment_outlined;
    return Icons.notifications_outlined;
  }

  Color _iconColor(BuildContext context) {
    if (notif.title.contains('Baru')) return Colors.blue;
    if (notif.title.contains('Selesai')) return Colors.green;
    if (notif.title.contains('Komentar')) return Colors.orange;
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUnread = !notif.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUnread ? scheme.primaryContainer.withOpacity(0.25) : null,
          border: Border(bottom: BorderSide(color: scheme.outlineVariant, width: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _iconColor(context).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _iconColor(context), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(notif.message,
                      style: TextStyle(
                          fontSize: 13, color: scheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(notif.timestamp,
                          style: TextStyle(
                              fontSize: 11, color: scheme.onSurfaceVariant)),
                      const Spacer(),
                      Text('Lihat tiket →',
                          style: TextStyle(
                              fontSize: 11,
                              color: scheme.primary,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}