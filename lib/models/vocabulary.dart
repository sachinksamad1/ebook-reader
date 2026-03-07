import 'package:cloud_firestore/cloud_firestore.dart';

class VocabularyWord {
  final String id;
  final String userId;
  final String word;
  final String meaning;
  final String? bookId;
  final DateTime createdAt;

  VocabularyWord({
    required this.id,
    required this.userId,
    required this.word,
    required this.meaning,
    this.bookId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory VocabularyWord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VocabularyWord(
      id: doc.id,
      userId: data['user_id'] ?? '',
      word: data['word'] ?? '',
      meaning: data['meaning'] ?? '',
      bookId: data['book_id'],
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'word': word,
      'meaning': meaning,
      'book_id': bookId,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
