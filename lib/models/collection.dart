import 'package:cloud_firestore/cloud_firestore.dart';

class Collection {
  final String id;
  final String userId;
  final String name;
  final String? description;

  Collection({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
  });

  factory Collection.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Collection(
      id: doc.id,
      userId: data['user_id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'name': name,
      if (description != null) 'description': description,
    };
  }

  Collection copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
  }) {
    return Collection(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }
}
