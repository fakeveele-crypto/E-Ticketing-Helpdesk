import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ticket_model.dart';
import '../providers/app_provider.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _refreshUsers());
  }

  Future<void> _refreshUsers() async {
    if (!mounted) return;
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      await context.read<AppProvider>().fetchProfiles();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _changeRole(AppProvider provider, UserModel user) async {
    final roleOptions = <String>['user', 'helpdesk', 'admin'];
    final selectedRole = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Ubah role pengguna'),
          children: roleOptions.map((role) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, role),
              child: Row(
                children: [
                  Icon(
                    role == 'admin'
                        ? Icons.admin_panel_settings
                        : role == 'helpdesk'
                        ? Icons.support_agent
                        : Icons.person,
                    color: role == user.role
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(role.toUpperCase()),
                ],
              ),
            );
          }).toList(),
        );
      },
    );

    if (selectedRole == null || selectedRole == user.role) return;

    try {
      await provider.updateUserRole(user.id, selectedRole);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Role ${user.name} diubah menjadi ${selectedRole.toUpperCase()}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengubah role: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final users = provider.allUsers;

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Pengguna'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _refreshUsers,
        child: _isRefreshing && users.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : users.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  else
                    const Center(child: Text('Belum ada data pengguna.')),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'U',
                        ),
                      ),
                      title: Text(
                        user.name.isNotEmpty ? user.name : user.username,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('@${user.username}'),
                          const SizedBox(height: 4),
                          Text(
                            user.email.isNotEmpty
                                ? user.email
                                : 'Email belum tersedia',
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(
                            label: Text(user.role.toUpperCase()),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Ubah role',
                            onPressed: () => _changeRole(provider, user),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
