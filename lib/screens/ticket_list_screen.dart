import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/ticket_model.dart';
import 'ticket_detail_screen.dart';

class TicketListScreen extends StatefulWidget {
  final bool isAdmin;
  const TicketListScreen({super.key, this.isAdmin = false});
  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  String _filter = 'all';

  Color _statusColor(String s) {
    switch (s) {
      case 'open': return Colors.blue;
      case 'on_progress': return Colors.orange;
      case 'resolved': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'open': return 'Baru';
      case 'on_progress': return 'Diproses';
      case 'resolved': return 'Selesai';
      default: return 'Ditutup';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final allTickets = widget.isAdmin ? provider.tickets : provider.myTickets;
    final filtered = _filter == 'all'
        ? allTickets
        : allTickets.where((t) => t.status == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Semua Tiket' : 'Tiket Saya'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in [
                    ('all', 'Semua'),
                    ('open', 'Baru'),
                    ('on_progress', 'Diproses'),
                    ('resolved', 'Selesai'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(f.$2),
                        selected: _filter == f.$1,
                        onSelected: (_) => setState(() => _filter = f.$1),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text('Tidak ada tiket', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final t = filtered[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: t, isAdmin: widget.isAdmin)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _statusColor(t.status).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(_statusLabel(t.status), style: TextStyle(fontSize: 11, color: _statusColor(t.status), fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(t.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.tag, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 4),
                                    Text(t.id, style: const TextStyle(fontSize: 12)),
                                    const Spacer(),
                                    Icon(Icons.access_time, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 4),
                                    Text(t.createdAt, style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}