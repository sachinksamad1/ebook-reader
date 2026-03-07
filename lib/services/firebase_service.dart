import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/book.dart';
import '../models/highlight.dart';
import '../models/note.dart';
import '../models/vocabulary.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'ebook-reader',
  );
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUserId {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('No user logged in');
    return uid;
  }

  // ════════════════════════════════════════
  // BOOKS
  // ════════════════════════════════════════

  /// Stream all books, ordered by last read
  Stream<List<Book>> streamBooks() {
    return _firestore
        .collection('books')
        .where('user_id', isEqualTo: _currentUserId)
        .orderBy('last_read', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList(),
        );
  }

  /// Get a single book
  Future<Book?> getBook(String bookId) async {
    final doc = await _firestore.collection('books').doc(bookId).get();
    if (!doc.exists) return null;
    return Book.fromFirestore(doc);
  }

  /// Upload a book file to Firebase Storage and save metadata to Firestore
  Future<Book> uploadBook({
    required File file,
    required String title,
    required String author,
    required String fileType,
  }) async {
    final bookId = _uuid.v4();
    final uid = _currentUserId;
    final fileName = '$bookId.$fileType';

    // Upload file to Storage under user-specific path
    final ref = _storage.ref().child('ebooks/$uid/$fileName');
    await ref.putFile(file);
    final fileUrl = await ref.getDownloadURL();

    // Save metadata to Firestore
    final book = Book(
      id: bookId,
      userId: uid,
      title: title,
      author: author,
      fileUrl: fileUrl,
      fileType: fileType,
      lastRead: DateTime.now(),
    );
    await _firestore.collection('books').doc(bookId).set(book.toFirestore());

    return book;
  }

  /// Update book progress and location
  Future<void> updateBookProgress(
    String bookId,
    double progress, {
    String? lastLocation,
  }) async {
    final data = <String, dynamic>{
      'progress': progress,
      'last_read': Timestamp.fromDate(DateTime.now()),
    };
    if (lastLocation != null) {
      data['lastLocation'] = lastLocation;
    }

    await _firestore.collection('books').doc(bookId).update(data);
  }

  /// Delete a book
  Future<void> deleteBook(String bookId) async {
    final book = await getBook(bookId);
    if (book != null) {
      // Delete file from storage
      try {
        final ref = _storage.refFromURL(book.fileUrl);
        await ref.delete();
      } catch (_) {}

      // Delete cover if exists
      if (book.coverUrl != null) {
        try {
          final ref = _storage.refFromURL(book.coverUrl!);
          await ref.delete();
        } catch (_) {}
      }
    }
    await _firestore.collection('books').doc(bookId).delete();
  }

  /// Update book cover
  Future<void> updateBookCover(String bookId, File imageFile) async {
    final uid = _currentUserId;
    final ext = imageFile.path.split('.').last.toLowerCase();
    final fileName = '${bookId}_cover.$ext';

    // Upload image to Storage under user-specific path
    final ref = _storage.ref().child('ebooks/$uid/$fileName');
    await ref.putFile(imageFile);
    final coverUrl = await ref.getDownloadURL();

    // Update metadata in Firestore
    await _firestore.collection('books').doc(bookId).update({
      'cover_url': coverUrl,
    });
  }

  /// Delete book cover
  Future<void> deleteBookCover(String bookId, String coverUrl) async {
    // Delete from Storage
    try {
      final ref = _storage.refFromURL(coverUrl);
      await ref.delete();
    } catch (_) {}

    // Update metadata in Firestore
    await _firestore.collection('books').doc(bookId).update({
      'cover_url': FieldValue.delete(),
    });
  }

  // ════════════════════════════════════════
  // HIGHLIGHTS
  // ════════════════════════════════════════

  Stream<List<Highlight>> streamHighlights(String bookId) {
    return _firestore
        .collection('highlights')
        .where('user_id', isEqualTo: _currentUserId)
        .where('book_id', isEqualTo: bookId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Highlight.fromFirestore(doc)).toList(),
        );
  }

  Future<Highlight> addHighlight(Highlight highlight) async {
    final id = _uuid.v4();
    final newHighlight = Highlight(
      id: id,
      userId: _currentUserId,
      bookId: highlight.bookId,
      chapter: highlight.chapter,
      startOffset: highlight.startOffset,
      endOffset: highlight.endOffset,
      text: highlight.text,
      color: highlight.color,
    );
    await _firestore
        .collection('highlights')
        .doc(id)
        .set(newHighlight.toFirestore());
    return newHighlight;
  }

  Future<void> deleteHighlight(String highlightId) async {
    await _firestore.collection('highlights').doc(highlightId).delete();
    // Also delete associated notes
    final notes = await _firestore
        .collection('notes')
        .where('highlight_id', isEqualTo: highlightId)
        .get();
    for (final doc in notes.docs) {
      await doc.reference.delete();
    }
  }

  // ════════════════════════════════════════
  // NOTES
  // ════════════════════════════════════════

  Stream<List<Note>> streamNotes(String bookId) {
    return _firestore
        .collection('notes')
        .where('user_id', isEqualTo: _currentUserId)
        .where('book_id', isEqualTo: bookId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList(),
        );
  }

  /// Stream all notes across all books
  Stream<List<Note>> streamAllNotes() {
    return _firestore
        .collection('notes')
        .where('user_id', isEqualTo: _currentUserId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList(),
        );
  }

  Future<Note> addNote(Note note) async {
    final id = _uuid.v4();
    final newNote = Note(
      id: id,
      userId: _currentUserId,
      bookId: note.bookId,
      highlightId: note.highlightId,
      noteText: note.noteText,
    );
    await _firestore.collection('notes').doc(id).set(newNote.toFirestore());
    return newNote;
  }

  Future<void> updateNote(String noteId, String text) async {
    await _firestore.collection('notes').doc(noteId).update({
      'note_text': text,
    });
  }

  Future<void> deleteNote(String noteId) async {
    await _firestore.collection('notes').doc(noteId).delete();
  }

  // ════════════════════════════════════════
  // VOCABULARY
  // ════════════════════════════════════════

  Stream<List<VocabularyWord>> streamVocabulary() {
    return _firestore
        .collection('vocabulary')
        .where('user_id', isEqualTo: _currentUserId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => VocabularyWord.fromFirestore(doc))
              .toList(),
        );
  }

  Future<VocabularyWord> addVocabularyWord(VocabularyWord word) async {
    final id = _uuid.v4();
    final newWord = VocabularyWord(
      id: id,
      userId: _currentUserId,
      word: word.word,
      meaning: word.meaning,
      bookId: word.bookId,
    );
    await _firestore
        .collection('vocabulary')
        .doc(id)
        .set(newWord.toFirestore());
    return newWord;
  }

  Future<void> deleteVocabularyWord(String wordId) async {
    await _firestore.collection('vocabulary').doc(wordId).delete();
  }
}
