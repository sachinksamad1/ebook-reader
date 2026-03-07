import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String id;
  final String userId;
  final String title;
  final String author;
  final String? coverUrl;
  final String fileUrl;
  final String fileType; // 'epub' or 'pdf'
  final DateTime? lastRead;
  final double progress; // 0.0 to 1.0
  final String? lastLocation;

  Book({
    required this.id,
    required this.userId,
    required this.title,
    required this.author,
    this.coverUrl,
    required this.fileUrl,
    required this.fileType,
    this.lastRead,
    this.progress = 0.0,
    this.lastLocation,
  });

  factory Book.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Book(
      id: doc.id,
      userId: data['user_id'] ?? '',
      title: data['title'] ?? '',
      author: data['author'] ?? 'Unknown',
      coverUrl: data['cover_url'],
      fileUrl: data['file_url'] ?? '',
      fileType: data['file_type'] ?? 'epub',
      lastRead: data['last_read'] != null
          ? (data['last_read'] as Timestamp).toDate()
          : null,
      progress: (data['progress'] ?? 0.0).toDouble(),
      lastLocation: data['lastLocation'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'title': title,
      'author': author,
      'cover_url': coverUrl,
      'file_url': fileUrl,
      'file_type': fileType,
      'last_read': lastRead != null ? Timestamp.fromDate(lastRead!) : null,
      'progress': progress,
      if (lastLocation != null) 'lastLocation': lastLocation,
    };
  }

  Book copyWith({
    String? id,
    String? userId,
    String? title,
    String? author,
    String? coverUrl,
    String? fileUrl,
    String? fileType,
    DateTime? lastRead,
    double? progress,
    String? lastLocation,
  }) {
    return Book(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      lastRead: lastRead ?? this.lastRead,
      progress: progress ?? this.progress,
      lastLocation: lastLocation ?? this.lastLocation,
    );
  }
}
