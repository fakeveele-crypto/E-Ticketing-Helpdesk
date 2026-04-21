import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/ticket_model.dart';

class TicketDetailScreen extends StatefulWidget {
  final TicketModel ticket;
  final bool isAdmin;

  const TicketDetailScreen({
    super.key,
    required this.ticket,
    this.isAdmin = false,
  });

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  // ── Helper warna & label status ─────────────────────────
  Color _statusColor(String s) {
    switch (s) {
      case 'open':
        return Colors.blue;
      case 'on_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'open':
        return 'Baru';
      case 'on_progress':
        return 'Sedang Diproses';
      case 'resolved':
        return 'Selesai';
      default:
        return 'Ditutup';
    }
  }

  // ── Dialog lihat foto fullscreen ─────────────────────────
  void _showFullImage(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.file(
                  File(path),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom sheet update status (admin/helpdesk) ──────────
  void _showStatusSheet(BuildContext context, AppProvider provider, TicketModel ticket) {
    final statuses = [
      ('open', 'Baru', Icons.fiber_new_outlined, Colors.blue),
      ('on_progress', 'Sedang Diproses', Icons.pending_actions_outlined, Colors.orange),
      ('resolved', 'Selesai', Icons.check_circle_outline, Colors.green),
      ('closed', 'Ditutup', Icons.cancel_outlined, Colors.grey),
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Ubah Status Tiket',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...statuses.map(
                (s) => ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: s.$4.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(s.$3, color: s.$4),
                  ),
                  title: Text(s.$2),
                  trailing: ticket.status == s.$1
                      ? Icon(Icons.check_circle, color: s.$4)
                      : null,
                  onTap: () {
                    provider.updateTicketStatus(ticket.id, s.$1);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Status diubah ke: ${s.$2}'),
                        backgroundColor: s.$4,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final scheme = Theme.of(context).colorScheme;

    // Ambil tiket terbaru dari provider agar status/komentar selalu update
    final ticket = provider.getTicketById(widget.ticket.id) ?? widget.ticket;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ticket.id,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (widget.isAdmin)
            IconButton(
              onPressed: () => _showStatusSheet(context, provider, ticket),
              icon: const Icon(Icons.edit_note_rounded),
              tooltip: 'Ubah Status',
            ),
        ],
      ),

      body: Column(
        children: [
          // ── Konten utama (scrollable) ──────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Status & Kategori Badge ──────────────────
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _statusColor(ticket.status).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color:
                                  _statusColor(ticket.status).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle,
                                size: 8, color: _statusColor(ticket.status)),
                            const SizedBox(width: 6),
                            Text(
                              _statusLabel(ticket.status),
                              style: TextStyle(
                                color: _statusColor(ticket.status),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          ticket.category,
                          style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Judul ────────────────────────────────────
                  Text(
                    ticket.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  // ── Info pembuat & waktu ─────────────────────
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 14, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        ticket.createdBy,
                        style: TextStyle(
                            fontSize: 13, color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time,
                          size: 14, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        ticket.createdAt,
                        style: TextStyle(
                            fontSize: 13, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),

                  const Divider(height: 28),

                  // ── Deskripsi ────────────────────────────────
                  Text(
                    'Deskripsi',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ticket.description,
                    style: const TextStyle(height: 1.6, fontSize: 14),
                  ),

                  // ── Foto Lampiran ────────────────────────────
                  if (ticket.imagePaths.isNotEmpty) ...[
                    const Divider(height: 28),
                    Text(
                      'Foto Lampiran (${ticket.imagePaths.length})',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: ticket.imagePaths.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, i) => GestureDetector(
                          onTap: () =>
                              _showFullImage(context, ticket.imagePaths[i]),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(ticket.imagePaths[i]),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // ── Ditangani oleh ───────────────────────────
                  if (ticket.assignedTo != null &&
                      ticket.assignedTo!.isNotEmpty) ...[
                    const Divider(height: 28),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.support_agent,
                              size: 18, color: scheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Ditangani oleh: ',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: scheme.primary),
                          ),
                          Text(
                            ticket.assignedTo!,
                            style: TextStyle(color: scheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Divider(height: 28),

                  // ── Komentar ─────────────────────────────────
                  Text(
                    'Komentar (${ticket.comments.length})',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (ticket.comments.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Belum ada komentar.',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
                    ...ticket.comments.map(
                      (c) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: scheme.primaryContainer,
                                  child: Text(
                                    c.author[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: scheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  c.author,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                                const Spacer(),
                                Text(
                                  c.timestamp,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: scheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              c.message,
                              style: const TextStyle(
                                  fontSize: 14, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Input Komentar (selalu di bawah) ────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(
                top: BorderSide(color: scheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tulis komentar...',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final text = _commentCtrl.text.trim();
                    if (text.isEmpty) return;
                    provider.addComment(ticket.id, text);
                    _commentCtrl.clear();
                    FocusScope.of(context).unfocus();
                  },
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(14),
                  ),
                  child: const Icon(Icons.send_rounded, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}