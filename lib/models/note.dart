import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String userId;
  final String bookId;
  final String? highlightId;
  final String noteText;
  final DateTime createdAt;

  Note({
    required this.id,
    required this.userId,
    required this.bookId,
    this.highlightId,
    required this.noteText,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Note.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Note(
      id: doc.id,
      userId: data['user_id'] ?? '',
      bookId: data['book_id'] ?? '',
      highlightId: data['highlight_id'],
      noteText: data['note_text'] ?? '',
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'book_id': bookId,
      'highlight_id': highlightId,
      'note_text': noteText,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
