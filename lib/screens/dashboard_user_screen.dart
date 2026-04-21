import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'create_ticket_screen.dart';
import 'ticket_list_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';

class DashboardUserScreen extends StatefulWidget {
  const DashboardUserScreen({super.key});
  @override
  State<DashboardUserScreen> createState() => _DashboardUserScreenState();
}

class _DashboardUserScreenState extends State<DashboardUserScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final scheme = Theme.of(context).colorScheme;
    final pages = [
      _HomeTab(),
      const TicketListScreen(),
      const NotificationScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Tiket'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Notifikasi'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final scheme = Theme.of(context).colorScheme;
    final myTickets = provider.myTickets;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Halo, ${provider.currentUser?.name ?? ''}! 👋',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Ada masalah IT? Laporkan sekarang.',
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
                CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(Icons.person, color: scheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Stats row
            Row(
              children: [
                _StatCard(label: 'Tiket Saya', value: myTickets.length, icon: Icons.confirmation_number, color: scheme.primary),
                const SizedBox(width: 12),
                _StatCard(label: 'Dalam Proses', value: myTickets.where((t) => t.status == 'on_progress').length, icon: Icons.pending_actions, color: Colors.orange),
                const SizedBox(width: 12),
                _StatCard(label: 'Selesai', value: myTickets.where((t) => t.status == 'resolved').length, icon: Icons.check_circle_outline, color: Colors.green),
              ],
            ),
            const SizedBox(height: 24),
            // Quick action button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTicketScreen())),
                icon: const Icon(Icons.add),
                label: const Text('Buat Tiket Baru', style: TextStyle(fontSize: 16)),
                style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ),
            const SizedBox(height: 24),
            Text('Tiket Terbaru', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (myTickets.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 60, color: scheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text('Belum ada tiket', style: TextStyle(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              )
            else
              ...myTickets.take(3).map((t) => _TicketTile(ticket: t)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text('$value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  final ticket;
  const _TicketTile({required this.ticket});

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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _statusColor(ticket.status).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.confirmation_number_outlined, color: _statusColor(ticket.status), size: 20),
        ),
        title: Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(ticket.id, style: const TextStyle(fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor(ticket.status).withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(_statusLabel(ticket.status), style: TextStyle(fontSize: 11, color: _statusColor(ticket.status), fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}