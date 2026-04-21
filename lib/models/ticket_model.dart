class TicketModel {
  final String id;
  final String title;
  final String description;
  final String category;
  String status;
  final String createdBy;
  final String createdAt;
  String? assignedTo;
  List<CommentModel> comments;
  List<String> imagePaths; // ← BARU: simpan path foto

  TicketModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.assignedTo,
    List<CommentModel>? comments,
    List<String>? imagePaths,
  })  : comments = comments ?? [],
        imagePaths = imagePaths ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'assignedTo': assignedTo ?? '',
    };
  }
}

class CommentModel {
  final String author;
  final String message;
  final String timestamp;

  CommentModel({
    required this.author,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'author': author,
        'message': message,
        'timestamp': timestamp,
      };
}

class UserModel {
  final String username;
  final String password;
  final String role;
  final String name;

  UserModel({
    required this.username,
    required this.password,
    required this.role,
    required this.name,
  });
}