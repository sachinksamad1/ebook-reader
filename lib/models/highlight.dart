import 'package:cloud_firestore/cloud_firestore.dart';

enum HighlightColor { yellow, green, blue }

class Highlight {
  final String id;
  final String userId;
  final String bookId;
  final String? chapter;
  final int startOffset;
  final int endOffset;
  final String text;
  final HighlightColor color;
  final DateTime createdAt;

  Highlight({
    required this.id,
    required this.userId,
    required this.bookId,
    this.chapter,
    required this.startOffset,
    required this.endOffset,
    required this.text,
    this.color = HighlightColor.yellow,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Highlight.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Highlight(
      id: doc.id,
      userId: data['user_id'] ?? '',
      bookId: data['book_id'] ?? '',
      chapter: data['chapter'],
      startOffset: data['start_offset'] ?? 0,
      endOffset: data['end_offset'] ?? 0,
      text: data['text'] ?? '',
      color: HighlightColor.values.firstWhere(
        (c) => c.name == data['color'],
        orElse: () => HighlightColor.yellow,
      ),
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'book_id': bookId,
      'chapter': chapter,
      'start_offset': startOffset,
      'end_offset': endOffset,
      'text': text,
      'color': color.name,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
