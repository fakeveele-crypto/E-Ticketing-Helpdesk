import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../models/ticket_model.dart';
import '../models/ticket_tracking_model.dart';

class AppProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  UserModel? _currentUser;
  List<TicketModel> _tickets = [];
  List<NotificationModel> _notifications = [];
  Map<String, List<TicketTrackingModel>> _ticketTracking = {};
  String? _authErrorMessage;

  // Daftar semua profil (untuk dropdown helpdesk, menampilkan nama asli, dan kelola pengguna)
  List<UserModel> _helpdeskUsers = [];
  List<UserModel> _allUsers = [];
  final Map<String, String> _profileNames = {};

  // Realtime channels — dibuka saat login, ditutup saat logout
  RealtimeChannel? _ticketsChannel;
  RealtimeChannel? _commentsChannel;
  RealtimeChannel? _trackingChannel;
  RealtimeChannel? _notificationsChannel;

  bool get isDarkMode => _isDarkMode;
  UserModel? get currentUser => _currentUser;
  List<TicketModel> get tickets => _tickets;
  List<NotificationModel> get notifications => _notifications;
  Map<String, List<TicketTrackingModel>> get ticketTracking => _ticketTracking;
  String? get authErrorMessage => _authErrorMessage;
  List<UserModel> get helpdeskUsers => _helpdeskUsers;
  List<UserModel> get allUsers => _allUsers;

  AppProvider();

  /// Nama tampilan untuk sebuah id/username user (fallback ke value aslinya
  /// kalau belum ada di cache profil).
  String displayNameFor(String? idOrUsername) {
    if (idOrUsername == null || idOrUsername.isEmpty) return '-';
    return _profileNames[idOrUsername] ?? idOrUsername;
  }

  String _authEmail(String username) {
    final trimmed = username.trim().toLowerCase();
    if (trimmed.contains('@')) {
      return trimmed;
    }
    final clean = trimmed.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    return '$clean@eticketing.local';
  }

  UserModel _userFromAuthUser(User user) {
    final metadata = user.userMetadata ?? {};
    final username =
        metadata['username']?.toString() ??
        user.email?.split('@').first ??
        user.id;
    final name = metadata['name']?.toString() ?? username;
    final role = metadata['role']?.toString() ?? 'user';
    return UserModel(
      id: user.id,
      username: username,
      name: name,
      role: role,
      email: user.email ?? '',
    );
  }

  Future<bool> register(String username, String password, String name) async {
    try {
      final email = _authEmail(username);
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username, 'name': name, 'role': 'user'},
      );
      _authErrorMessage = null;
      return response.user != null || response.session != null;
    } catch (error) {
      _authErrorMessage = error.toString();
      debugPrint('Register failed: $_authErrorMessage');
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final email = _authEmail(username);
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        return false;
      }
      _currentUser = _userFromAuthUser(response.user!);
      await loadData();
      _subscribeRealtime();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> resetPassword(String usernameOrEmail) async {
    try {
      final email = _authEmail(usernameOrEmail);
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      _authErrorMessage = null;
      return true;
    } catch (error) {
      _authErrorMessage = error.toString();
      debugPrint('Reset password failed: $_authErrorMessage');
      return false;
    }
  }

  Future<void> logout() async {
    await _unsubscribeRealtime();
    await Supabase.instance.client.auth.signOut();
    _currentUser = null;
    _tickets = [];
    _notifications = [];
    _ticketTracking = {};
    _helpdeskUsers = [];
    _allUsers = [];
    _profileNames.clear();
    notifyListeners();
  }

  /// Buka channel Supabase Realtime supaya tiket, komentar, tracking, dan
  /// notifikasi otomatis ter-update tanpa perlu logout-login ulang.
  void _subscribeRealtime() {
    final client = Supabase.instance.client;

    _ticketsChannel = client
        .channel('public:tickets')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tickets',
          callback: (payload) => fetchTickets(),
        )
        .subscribe();

    _commentsChannel = client
        .channel('public:ticket_comments')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'ticket_comments',
          callback: (payload) => fetchTickets(),
        )
        .subscribe();

    _trackingChannel = client
        .channel('public:ticket_tracking')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'ticket_tracking',
          callback: (payload) => fetchTicketTracking(),
        )
        .subscribe();

    _notificationsChannel = client
        .channel('public:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          callback: (payload) => fetchNotifications(),
        )
        .subscribe();
  }

  Future<void> _unsubscribeRealtime() async {
    final client = Supabase.instance.client;
    if (_ticketsChannel != null) await client.removeChannel(_ticketsChannel!);
    if (_commentsChannel != null) {
      await client.removeChannel(_commentsChannel!);
    }
    if (_trackingChannel != null) {
      await client.removeChannel(_trackingChannel!);
    }
    if (_notificationsChannel != null) {
      await client.removeChannel(_notificationsChannel!);
    }
    _ticketsChannel = null;
    _commentsChannel = null;
    _trackingChannel = null;
    _notificationsChannel = null;
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  Future<void> loadData() async {
    await Future.wait([fetchTickets(), fetchNotifications(), fetchProfiles()]);
    await fetchTicketTracking();
  }

  /// Ambil semua profil (untuk cache nama tampilan) dan daftar user helpdesk
  /// (untuk dropdown "Assign ke Helpdesk"). Kalau tabel `profiles` belum ada
  /// (migration belum dijalankan), gagal dengan aman tanpa meng-crash app.
  Future<void> fetchProfiles() async {
    try {
      final response = await Supabase.instance.client.from('profiles').select();
      final rows = response as List<dynamic>? ?? [];
      _profileNames.clear();
      final helpdesk = <UserModel>[];
      final allUsers = <UserModel>[];
      for (final row in rows) {
        final map = Map<String, dynamic>.from(row as Map);
        final id = map['id']?.toString() ?? '';
        final username = map['username']?.toString() ?? '';
        final name = map['name']?.toString().isNotEmpty == true
            ? map['name'].toString()
            : username;
        final role = map['role']?.toString() ?? 'user';
        if (id.isEmpty) continue;
        _profileNames[id] = name;
        if (username.isNotEmpty) _profileNames[username] = name;
        final userProfile = UserModel(
          id: id,
          username: username,
          name: name,
          role: role,
          email: map['email']?.toString() ?? '',
        );
        allUsers.add(userProfile);
        if (role == 'helpdesk') {
          helpdesk.add(userProfile);
        }
      }
      _allUsers = allUsers;
      _helpdeskUsers = helpdesk;
      notifyListeners();
    } catch (error) {
      debugPrint(
        'Fetch profiles failed (pastikan tabel `profiles` sudah dibuat via DATABASE_MIGRATION.sql): $error',
      );
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    if (userId.isEmpty) {
      throw Exception('User ID tidak valid');
    }

    await Supabase.instance.client
        .from('profiles')
        .update({'role': newRole})
        .eq('id', userId);

    await fetchProfiles();
  }

  Future<void> fetchTickets() async {
    final response = await Supabase.instance.client
        .from('tickets')
        .select()
        .order('created_at', ascending: false);
    final rows = response as List<dynamic>? ?? [];
    final tickets = rows
        .map(
          (row) => TicketModel.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
    if (tickets.isNotEmpty) {
      final ticketIds = tickets.map((t) => t.id).toList();
      final commentsResponse = await Supabase.instance.client
          .from('ticket_comments')
          .select()
          .inFilter('ticket_id', ticketIds)
          .order('created_at', ascending: true);
      final commentRows = commentsResponse as List<dynamic>? ?? [];
      final commentsByTicket = <String, List<CommentModel>>{};
      for (final comment in commentRows) {
        final model = CommentModel.fromMap(
          Map<String, dynamic>.from(comment as Map),
        );
        commentsByTicket.putIfAbsent(model.ticketId, () => []).add(model);
      }
      for (final ticket in tickets) {
        ticket.comments = commentsByTicket[ticket.id] ?? [];
      }
    }
    _tickets = tickets;
    notifyListeners();
  }

  Future<void> fetchNotifications() async {
    final response = await Supabase.instance.client
        .from('notifications')
        .select()
        .order('created_at', ascending: false);
    final rows = response as List<dynamic>? ?? [];
    final user = _currentUser;
    if (user == null) {
      _notifications = [];
      return;
    }
    _notifications = rows
        .map(
          (row) =>
              NotificationModel.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .where((notif) {
          return notif.recipientRole == 'all' ||
              notif.recipientRole == user.role ||
              notif.recipientId == user.id ||
              notif.recipientId == user.username;
        })
        .toList();
    notifyListeners();
  }

  Future<void> createTicket(
    String title,
    String description,
    String category, {
    String? photoPath,
  }) async {
    if (_currentUser == null) {
      throw Exception('User tidak ditemukan. Silakan login ulang.');
    }
    final ticketCode = 'TKT-${DateTime.now().millisecondsSinceEpoch}';
    final authUserId =
        Supabase.instance.client.auth.currentUser?.id ?? _currentUser!.id;
    try {
      final response = await Supabase.instance.client
          .from('tickets')
          .insert({
            'ticket_code': ticketCode,
            'title': title,
            'description': description,
            'category': category,
            'status': 'new',
            'priority': 'normal',
            'url_foto': photoPath?.isEmpty ?? true ? null : photoPath,
            'created_by': authUserId,
            'assigned_to': null,
          })
          .select()
          .single();
      final ticket = TicketModel.fromMap(
        Map<String, dynamic>.from(response as Map),
      );
      _tickets.insert(0, ticket);

      // Add tracking entry for ticket creation
      await _addTracking(
        ticketId: ticket.id,
        action: 'created',
        description: 'Tiket dibuat oleh ${_currentUser!.name}',
      );

      // Add notification to admins
      await _addNotification(
        title: 'Tiket Baru Masuk',
        message:
            'Tiket baru ${ticketCode}: "$title" telah dibuat oleh ${_currentUser!.name}',
        ticketId: ticket.id,
        recipientRole: 'admin',
      );

      notifyListeners();
    } catch (error) {
      debugPrint('Create ticket failed: $error');
      rethrow;
    }
  }

  Future<void> updateTicketStatus(String ticketId, String newStatus) async {
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx == -1) return;
    final ticket = _tickets[idx];
    final normalizedStatus = TicketModel.normalizeStatus(newStatus);
    await Supabase.instance.client
        .from('tickets')
        .update({
          'status': normalizedStatus,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', ticketId)
        .select()
        .single();
    ticket.status = normalizedStatus;
    final statusLabel =
        {
          'new': 'kembali dibuka',
          'on_progress': 'sedang diproses',
          'completed': 'telah selesai',
        }[normalizedStatus] ??
        normalizedStatus;
    await _addSystemComment(
      ticketId,
      'Status tiket diubah menjadi $statusLabel.',
    );
    await _addNotification(
      title: 'Status Tiket Diperbarui',
      message: 'Tiket ${ticket.ticketCode} "${ticket.title}" $statusLabel.',
      ticketId: ticket.id,
      recipientId: ticket.createdBy,
    );
    notifyListeners();
  }

  /// Catatan bug lama: kolom `ticket_comments.user_id` bertipe UUID, tapi
  /// sebelumnya di-insert dengan `_currentUser!.username` (string biasa).
  /// Insert itu gagal ("invalid input syntax for type uuid") dan karena
  /// dipanggil tanpa try/catch di tengah forwardTicketToHelpdesk(), satu
  /// error ini menghentikan seluruh proses assign sebelum notifikasi ke
  /// helpdesk sempat dibuat. Sekarang pakai `_currentUser!.id` (uuid asli
  /// dari Supabase Auth) dan dibungkus try/catch supaya gagal komentar
  /// sistem tidak pernah menggagalkan alur utama (assign/complete/dsb).
  Future<void> _addSystemComment(String ticketId, String message) async {
    if (_currentUser == null) return;
    try {
      final response = await Supabase.instance.client
          .from('ticket_comments')
          .insert({
            'ticket_id': ticketId,
            'user_id': _currentUser!.id,
            'message': message,
          })
          .select()
          .single();
      final comment = CommentModel.fromMap(
        Map<String, dynamic>.from(response as Map),
      );
      final idx = _tickets.indexWhere((t) => t.id == ticketId);
      if (idx != -1) {
        _tickets[idx].comments.add(comment);
      }
    } catch (error) {
      debugPrint('Add system comment failed: $error');
    }
  }

  Future<void> addComment(String ticketId, String message) async {
    if (_currentUser == null) return;
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx == -1) return;
    final response = await Supabase.instance.client
        .from('ticket_comments')
        .insert({
          'ticket_id': ticketId,
          'user_id': _currentUser!.id,
          'message': message,
        })
        .select()
        .single();
    final comment = CommentModel.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
    _tickets[idx].comments.add(comment);
    if (_currentUser!.role != 'user') {
      await _addNotification(
        title: 'Komentar Baru di Tiket',
        message:
            '${_currentUser!.name} membalas tiket ${_tickets[idx].ticketCode}.',
        ticketId: ticketId,
        recipientId: _tickets[idx].createdBy,
      );
    }
    notifyListeners();
  }

  Future<void> _addNotification({
    required String title,
    required String message,
    required String ticketId,
    String? recipientId,
    String? recipientRole,
  }) async {
    if (recipientId == null && recipientRole == null) {
      throw Exception('Notification must have a recipientId or recipientRole');
    }

    final payload = <String, dynamic>{
      'ticket_id': ticketId,
      'title': title,
      'message': message,
      'is_read': false,
    };

    if (recipientRole != null) {
      payload['recipient_role'] = recipientRole;
      payload['recipient_id'] = null;
    } else {
      payload['recipient_id'] = recipientId;
      payload['recipient_role'] = null;
    }

    final response = await Supabase.instance.client
        .from('notifications')
        .insert(payload)
        .select()
        .single();
    final notification = NotificationModel.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
    _notifications.insert(0, notification);
    notifyListeners();
  }

  List<NotificationModel> get myNotifications {
    final user = _currentUser;
    if (user == null) return [];
    return _notifications.where((n) {
      return n.recipientRole == 'all' ||
          n.recipientRole == user.role ||
          n.recipientId == user.id ||
          n.recipientId == user.username;
    }).toList();
  }

  int get unreadCount => myNotifications.where((n) => !n.isRead).length;

  Future<void> markAllRead() async {
    final ids = myNotifications.map((n) => n.id).toList();
    if (ids.isEmpty) return;
    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})
        .inFilter('id', ids);
    for (final notif in _notifications) {
      if (ids.contains(notif.id)) {
        notif.isRead = true;
      }
    }
    notifyListeners();
  }

  Future<void> markOneRead(String notifId) async {
    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notifId);
    final idx = _notifications.indexWhere((n) => n.id == notifId);
    if (idx != -1) {
      _notifications[idx].isRead = true;
      notifyListeners();
    }
  }

  List<TicketModel> get myTickets {
    final user = _currentUser;
    if (user == null) return [];
    return _tickets.where((t) {
      return t.createdBy == user.id || t.createdBy == user.username;
    }).toList();
  }

  List<TicketModel> get assignedTickets {
    final user = _currentUser;
    if (user == null) return [];
    return _tickets.where((t) {
      return t.assignedTo == user.id || t.assignedTo == user.username;
    }).toList();
  }

  List<TicketModel> get unassignedTickets => _tickets
      .where((t) => t.assignedTo == null || t.assignedTo!.isEmpty)
      .toList();

  int get totalTickets => _tickets.length;
  int get openTickets => _tickets.where((t) => t.status == 'new').length;
  int get inProgressTickets =>
      _tickets.where((t) => t.status == 'on_progress').length;
  int get closedTickets =>
      _tickets.where((t) => t.status == 'completed').length;
  int get assignedTicketCount => _tickets
      .where((t) => t.assignedTo != null && t.assignedTo!.isNotEmpty)
      .length;

  TicketModel? getTicketById(String id) {
    try {
      return _tickets.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  // ============ TICKET WORKFLOW METHODS ============

  /// Admin accepts the ticket from user
  Future<void> acceptTicketAsAdmin(String ticketId) async {
    if (_currentUser == null || _currentUser!.role == 'user') {
      throw Exception('Hanya admin yang dapat menerima tiket.');
    }

    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx == -1) return;

    final ticket = _tickets[idx];
    final now = DateTime.now().toIso8601String();

    // Update ticket in database
    await Supabase.instance.client
        .from('tickets')
        .update({'received_by_admin_at': now, 'updated_at': now})
        .eq('id', ticketId)
        .select()
        .single();

    ticket.receivedByAdminAt = now;

    // Add tracking entry
    await _addTracking(
      ticketId: ticketId,
      action: 'accepted_by_admin',
      description: 'Tiket diterima oleh admin ${_currentUser!.name}',
    );

    // Notify ticket creator
    await _addNotification(
      title: 'Tiket Diterima Admin',
      message:
          'Tiket ${ticket.ticketCode} "${ticket.title}" telah diterima oleh admin.',
      ticketId: ticketId,
      recipientId: ticket.createdBy,
    );

    notifyListeners();
  }

  /// Admin forwards ticket to helpdesk (assigns to helpdesk role)
  Future<void> forwardTicketToHelpdesk(
    String ticketId,
    String helpdeskUserId,
  ) async {
    if (_currentUser == null || _currentUser!.role == 'user') {
      throw Exception('Hanya admin yang dapat memforward tiket ke helpdesk.');
    }
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx == -1) return;
    final ticket = _tickets[idx];
    final now = DateTime.now().toIso8601String();
    await Supabase.instance.client
        .from('tickets')
        .update({
          'assigned_to': helpdeskUserId,
          'status': 'on_progress',
          'forwarded_to_helpdesk_at': now,
          'updated_at': now,
        })
        .eq('id', ticketId)
        .select()
        .single();
    ticket.assignedTo = helpdeskUserId;
    ticket.status = 'on_progress';
    ticket.forwardedToHelpdeskAt = now;
    await _addTracking(
      ticketId: ticketId,
      action: 'forwarded_to_helpdesk',
      description:
          'Tiket diforward ke helpdesk oleh admin ${_currentUser!.name}',
    );
    await _addSystemComment(
      ticketId,
      'Tiket diforward ke helpdesk oleh ${_currentUser!.name} untuk ditangani.',
    );
    await _addNotification(
      title: 'Tiket Baru dari Admin',
      message:
          'Anda menerima tiket baru ${ticket.ticketCode}: "${ticket.title}"',
      ticketId: ticketId,
      recipientId: helpdeskUserId,
    );
    await _addNotification(
      title: 'Tiket Sedang Diproses Helpdesk',
      message: 'Tiket ${ticket.ticketCode} sedang diproses oleh tim helpdesk.',
      ticketId: ticketId,
      recipientId: ticket.createdBy,
    );
    notifyListeners();
  }

  /// Helpdesk accepts the ticket
  Future<void> acceptTicketAsHelpdesk(String ticketId) async {
    if (_currentUser == null || _currentUser!.role != 'helpdesk') {
      throw Exception('Hanya helpdesk yang dapat menerima tiket.');
    }

    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx == -1) return;

    final ticket = _tickets[idx];
    final now = DateTime.now().toIso8601String();

    // Update ticket in database
    await Supabase.instance.client
        .from('tickets')
        .update({'status': 'on_progress', 'updated_at': now})
        .eq('id', ticketId)
        .select()
        .single();

    ticket.status = 'on_progress';

    // Add tracking entry
    await _addTracking(
      ticketId: ticketId,
      action: 'accepted_by_helpdesk',
      description: 'Tiket diterima oleh helpdesk ${_currentUser!.name}',
    );

    // Add system comment
    await _addSystemComment(
      ticketId,
      'Tiket sedang ditangani oleh ${_currentUser!.name}.',
    );

    // Notify ticket creator
    await _addNotification(
      title: 'Tiket Sedang Ditangani',
      message: 'Tiket ${ticket.ticketCode} sedang ditangani oleh helpdesk.',
      ticketId: ticketId,
      recipientId: ticket.createdBy,
    );

    // Notify admin
    await _addNotification(
      title: 'Helpdesk Sedang Menangani Tiket',
      message:
          'Tiket ${ticket.ticketCode} sedang ditangani oleh ${_currentUser!.name}.',
      ticketId: ticketId,
      recipientRole: 'admin',
    );

    notifyListeners();
  }

  /// Helpdesk completes the ticket
  Future<void> completeTicketByHelpdesk(String ticketId) async {
    if (_currentUser == null || _currentUser!.role != 'helpdesk') {
      throw Exception('Hanya helpdesk yang dapat menyelesaikan tiket.');
    }

    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx == -1) return;

    final ticket = _tickets[idx];
    final now = DateTime.now().toIso8601String();

    // Update ticket in database
    await Supabase.instance.client
        .from('tickets')
        .update({'status': 'completed', 'completed_at': now, 'updated_at': now})
        .eq('id', ticketId)
        .select()
        .single();

    ticket.status = 'completed';
    ticket.completedAt = now;

    // Add tracking entry
    await _addTracking(
      ticketId: ticketId,
      action: 'completed',
      description: 'Tiket diselesaikan oleh helpdesk ${_currentUser!.name}',
    );

    // Add system comment
    await _addSystemComment(
      ticketId,
      'Tiket telah diselesaikan oleh ${_currentUser!.name}.',
    );

    // Notify ticket creator
    await _addNotification(
      title: 'Tiket Selesai',
      message:
          'Tiket ${ticket.ticketCode} "${ticket.title}" telah diselesaikan.',
      ticketId: ticketId,
      recipientId: ticket.createdBy,
    );

    // Notify admin
    await _addNotification(
      title: 'Tiket Diselesaikan',
      message:
          'Tiket ${ticket.ticketCode} telah diselesaikan oleh ${_currentUser!.name}.',
      ticketId: ticketId,
      recipientRole: 'admin',
    );

    notifyListeners();
  }

  /// Add tracking entry for ticket status changes
  Future<void> _addTracking({
    required String ticketId,
    required String action,
    required String description,
  }) async {
    try {
      final user = _currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('ticket_tracking')
          .insert({
            'ticket_id': ticketId,
            'action': action,
            'actor_id': user.id,
            'actor_name': user.name,
            'actor_role': user.role,
            'description': description,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final tracking = TicketTrackingModel.fromMap(
        Map<String, dynamic>.from(response as Map),
      );

      _ticketTracking.putIfAbsent(ticketId, () => []).add(tracking);
    } catch (error) {
      debugPrint('Add tracking failed: $error');
    }
  }

  /// Fetch ticket tracking history
  Future<void> fetchTicketTracking() async {
    try {
      final response = await Supabase.instance.client
          .from('ticket_tracking')
          .select()
          .order('created_at', ascending: true);

      final rows = response as List<dynamic>? ?? [];
      _ticketTracking.clear();

      for (final row in rows) {
        final tracking = TicketTrackingModel.fromMap(
          Map<String, dynamic>.from(row as Map),
        );
        _ticketTracking.putIfAbsent(tracking.ticketId, () => []).add(tracking);
      }

      notifyListeners();
    } catch (error) {
      debugPrint('Fetch ticket tracking failed: $error');
    }
  }

  /// Get tracking history for a specific ticket
  List<TicketTrackingModel> getTicketTrackingHistory(String ticketId) {
    return _ticketTracking[ticketId] ?? [];
  }

  /// Get a formatted tracking summary for display
  String getTrackingSummary(String ticketId) {
    final tracking = getTicketTrackingHistory(ticketId);
    final ticket = getTicketById(ticketId);
    if (ticket == null) return 'Tiket tidak ditemukan';

    final summaryParts = <String>[];
    summaryParts.add('✓ Tiket dibuat oleh ${ticket.createdBy}');

    if (ticket.receivedByAdminAt != null) {
      summaryParts.add('✓ Diterima oleh admin');
    }

    if (ticket.forwardedToHelpdeskAt != null) {
      summaryParts.add('✓ Diforward ke helpdesk');
    }

    if (ticket.completedAt != null) {
      summaryParts.add('✓ Diselesaikan oleh helpdesk');
    }

    return summaryParts.join('\n');
  }

  /// Get visible tickets for current user based on their role
  List<TicketModel> getVisibleTicketsForCurrentUser() {
    final user = _currentUser;
    if (user == null) return [];

    if (user.role == 'user') {
      // Users can only see their own tickets
      return _tickets.where((t) {
        return t.createdBy == user.id || t.createdBy == user.username;
      }).toList();
    } else if (user.role == 'admin') {
      // Admins see semua tiket sampai status completed
      return _tickets.where((t) => t.status != 'completed').toList();
    } else if (user.role == 'helpdesk') {
      // Helpdesk hanya melihat tiket yang ditugaskan ke dirinya sendiri
      return _tickets.where((t) {
        return t.assignedTo == user.id || t.assignedTo == user.username;
      }).toList();
    }

    return [];
  }
}
