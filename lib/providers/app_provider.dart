import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import '../models/notification_model.dart';

class AppProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  UserModel? _currentUser;
  List<TicketModel> _tickets = [];
  List<NotificationModel> _notifications = [];

  bool get isDarkMode => _isDarkMode;
  UserModel? get currentUser => _currentUser;
  List<TicketModel> get tickets => _tickets;

  final List<UserModel> _users = [
    UserModel(username: 'admin', password: '123456', role: 'admin', name: 'Admin Sistem'),
    UserModel(username: 'helpdesk1', password: '123456', role: 'helpdesk', name: 'Budi Helpdesk'),
    UserModel(username: 'user1', password: '123456', role: 'user', name: 'Andi Pengguna'),
    UserModel(username: 'user2', password: '123456', role: 'user', name: 'Siti Pengguna'),
  ];

  AppProvider() {
    _loadDummyData();
  }

  void _loadDummyData() {
    _tickets = [
      TicketModel(
        id: 'TKT-001',
        title: 'Komputer tidak bisa menyala',
        description: 'Komputer di meja saya tiba-tiba tidak bisa dinyalakan sejak kemarin sore.',
        category: 'Hardware',
        status: 'open',
        createdBy: 'user1',
        createdAt: '2026-04-15 09:00',
      ),
      TicketModel(
        id: 'TKT-002',
        title: 'Tidak bisa akses email kantor',
        description: 'Saya tidak bisa login ke email kantor, muncul error "invalid credentials".',
        category: 'Software',
        status: 'on_progress',
        createdBy: 'user1',
        createdAt: '2026-04-16 10:30',
        assignedTo: 'helpdesk1',
        comments: [
          CommentModel(
            author: 'helpdesk1',
            message: 'Sedang kami cek ya, kemungkinan password expired.',
            timestamp: '2026-04-16 11:00',
          ),
        ],
      ),
      TicketModel(
        id: 'TKT-003',
        title: 'Printer tidak terdeteksi',
        description: 'Printer di ruang kerja lantai 2 tidak terdeteksi oleh semua komputer.',
        category: 'Hardware',
        status: 'resolved',
        createdBy: 'user2',
        createdAt: '2026-04-17 08:00',
        assignedTo: 'helpdesk1',
      ),
    ];

    // Dummy notifikasi awal
    _notifications = [
      NotificationModel(
        id: 'NOTIF-001',
        title: 'Tiket Baru Masuk',
        message: 'TKT-001: Komputer tidak bisa menyala menunggu penanganan.',
        ticketId: 'TKT-001',
        timestamp: '2026-04-15 09:05',
        targetRole: 'admin',
        targetUser: 'all',
      ),
      NotificationModel(
        id: 'NOTIF-002',
        title: 'Tiket Diperbarui',
        message: 'Tiket TKT-002 kamu sedang diproses oleh helpdesk1.',
        ticketId: 'TKT-002',
        timestamp: '2026-04-16 11:00',
        targetRole: 'user',
        targetUser: 'user1',
      ),
      NotificationModel(
        id: 'NOTIF-003',
        title: 'Tiket Selesai',
        message: 'Tiket TKT-003 kamu telah selesai ditangani.',
        ticketId: 'TKT-003',
        timestamp: '2026-04-17 14:00',
        targetRole: 'user',
        targetUser: 'user2',
      ),
      NotificationModel(
        id: 'NOTIF-004',
        title: 'Tiket Baru Masuk',
        message: 'TKT-002: Tidak bisa akses email kantor butuh perhatian.',
        ticketId: 'TKT-002',
        timestamp: '2026-04-16 10:35',
        targetRole: 'admin',
        targetUser: 'all',
      ),
    ];
  }

  // ─── Auth ───────────────────────────────────────────────
  bool login(String username, String password) {
    final found = _users.where(
      (u) => u.username == username && u.password == password,
    ).toList();
    if (found.isNotEmpty) {
      _currentUser = found.first;
      notifyListeners();
      return true;
    }
    return false;
  }

  bool register(String username, String password, String name) {
    if (_users.any((u) => u.username == username)) return false;
    _users.add(UserModel(username: username, password: password, role: 'user', name: name));
    return true;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // ─── Tiket ──────────────────────────────────────────────
  void createTicket(
    String title,
    String description,
    String category, {
    List<String> imagePaths = const [],
  }) {
    final id = 'TKT-${(_tickets.length + 1).toString().padLeft(3, '0')}';
    _tickets.add(TicketModel(
      id: id,
      title: title,
      description: description,
      category: category,
      status: 'open',
      createdBy: _currentUser!.username,
      createdAt: DateTime.now().toString().substring(0, 16),
      imagePaths: List.from(imagePaths),
    ));
    // Tambah notifikasi untuk admin saat tiket baru dibuat
    _addNotification(
      title: 'Tiket Baru Masuk',
      message: '$id: $title menunggu penanganan.',
      ticketId: id,
      targetRole: 'admin',
      targetUser: 'all',
    );
    notifyListeners();
  }

  void updateTicketStatus(String ticketId, String newStatus) {
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx == -1) return;
    _tickets[idx].status = newStatus;

    final t = _tickets[idx];
    final statusLabel = {
      'open': 'kembali dibuka',
      'on_progress': 'sedang diproses',
      'resolved': 'telah selesai',
      'closed': 'ditutup',
    }[newStatus] ?? newStatus;

    // Notifikasi ke user pemilik tiket
    _addNotification(
      title: 'Status Tiket Diperbarui',
      message: 'Tiket ${t.id} "${t.title}" $statusLabel.',
      ticketId: ticketId,
      targetRole: 'user',
      targetUser: t.createdBy,
    );
    notifyListeners();
  }

  void assignTicket(String ticketId, String assignTo) {
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx == -1) return;
    _tickets[idx].assignedTo = assignTo;
    notifyListeners();
  }

  void addComment(String ticketId, String message) {
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx == -1) return;
    _tickets[idx].comments.add(CommentModel(
      author: _currentUser!.username,
      message: message,
      timestamp: DateTime.now().toString().substring(0, 16),
    ));
    // Kalau helpdesk/admin komen → notif ke user
    if (_currentUser!.role != 'user') {
      _addNotification(
        title: 'Komentar Baru di Tiket',
        message: '${_currentUser!.name} membalas tiket ${_tickets[idx].id}.',
        ticketId: ticketId,
        targetRole: 'user',
        targetUser: _tickets[idx].createdBy,
      );
    }
    notifyListeners();
  }

  // ─── Notifikasi ─────────────────────────────────────────
  void _addNotification({
    required String title,
    required String message,
    required String ticketId,
    required String targetRole,
    required String targetUser,
  }) {
    _notifications.insert(
      0,
      NotificationModel(
        id: 'NOTIF-${_notifications.length + 1}',
        title: title,
        message: message,
        ticketId: ticketId,
        timestamp: DateTime.now().toString().substring(0, 16),
        targetRole: targetRole,
        targetUser: targetUser,
      ),
    );
  }

  /// Notifikasi yang relevan untuk user yang sedang login
  List<NotificationModel> get myNotifications {
    final user = _currentUser;
    if (user == null) return [];
    return _notifications.where((n) {
      final roleMatch = n.targetRole == user.role ||
          n.targetRole == 'all' ||
          (user.role == 'admin' && n.targetRole == 'admin') ||
          (user.role == 'helpdesk' && n.targetRole == 'admin');
      final userMatch = n.targetUser == 'all' || n.targetUser == user.username;
      return roleMatch && userMatch;
    }).toList();
  }

  int get unreadCount => myNotifications.where((n) => !n.isRead).length;

  void markAllRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void markOneRead(String notifId) {
    final idx = _notifications.indexWhere((n) => n.id == notifId);
    if (idx != -1) _notifications[idx].isRead = true;
    notifyListeners();
  }

  // ─── Getters ─────────────────────────────────────────────
  List<TicketModel> get myTickets =>
      _tickets.where((t) => t.createdBy == _currentUser?.username).toList();

  int get totalTickets => _tickets.length;
  int get openTickets => _tickets.where((t) => t.status == 'open').length;
  int get onProgressTickets => _tickets.where((t) => t.status == 'on_progress').length;
  int get resolvedTickets => _tickets.where((t) => t.status == 'resolved').length;

  TicketModel? getTicketById(String id) {
    try {
      return _tickets.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}