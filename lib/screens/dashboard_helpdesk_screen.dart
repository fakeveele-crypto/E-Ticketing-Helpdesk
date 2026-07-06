import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ticket_model.dart';
import '../providers/app_provider.dart';
import 'create_ticket_screen.dart';
import 'ticket_list_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';

class DashboardHelpdeskScreen extends StatefulWidget {
  const DashboardHelpdeskScreen({super.key});

  @override
  State<DashboardHelpdeskScreen> createState() =>
      _DashboardHelpdeskScreenState();
}

class _DashboardHelpdeskScreenState extends State<DashboardHelpdeskScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HelpdeskHomeTab(),
      const TicketListScreen(isHelpdesk: true),
      const NotificationScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Tugas',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: false,
              label: const Text(''),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: const Icon(Icons.notifications),
            label: 'Notifikasi',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _HelpdeskHomeTab extends StatelessWidget {
  const _HelpdeskHomeTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final scheme = Theme.of(context).colorScheme;
    final tasks = provider.assignedTickets;

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
                    Text(
                      'Halo, ${provider.currentUser?.name ?? ''}! 👋',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Kelola tiket yang ditugaskan kepada Anda.',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(Icons.support_agent, color: scheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _StatCard(
                  label: 'Tugas Saya',
                  value: tasks.length,
                  icon: Icons.confirmation_number,
                  color: scheme.primary,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Diproses',
                  value: tasks.where((t) => t.status == 'on_progress').length,
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Selesai',
                  value: tasks.where((t) => t.status == 'completed').length,
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Buat Tiket Baru', style: TextStyle(fontSize: 16)),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tiket Ditugaskan',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (tasks.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 60,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada tugas tiket',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...tasks.take(4).map((t) => _TaskCard(ticket: t)),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TicketModel ticket;
  const _TaskCard({required this.ticket});

  Color _statusColor(String s) {
    switch (s) {
      case 'new':
        return Colors.blue;
      case 'on_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'new':
        return 'Baru';
      case 'on_progress':
        return 'Diproses';
      case 'completed':
        return 'Selesai';
      default:
        return 'Ditutup';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        title: Text(
          ticket.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(ticket.ticketCode, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 6),
            Text(
              ticket.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _statusColor(ticket.status).withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _statusLabel(ticket.status),
            style: TextStyle(
              color: _statusColor(ticket.status),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
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
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

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
            Text(
              '$value',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }
}
