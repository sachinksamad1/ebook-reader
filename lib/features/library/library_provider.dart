import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/book.dart';
import '../../services/firebase_service.dart';

// Firebase service provider
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

// Stream of all books
final booksStreamProvider = StreamProvider<List<Book>>((ref) {
  final service = ref.watch(firebaseServiceProvider);
  return service.streamBooks();
});

// Search query state
final searchQueryProvider = StateProvider<String>((ref) => '');

// Sort mode
enum SortMode { recent, titleAsc, titleDesc }

final sortModeProvider = StateProvider<SortMode>((ref) => SortMode.recent);

// Filtered and sorted books
final filteredBooksProvider = Provider<AsyncValue<List<Book>>>((ref) {
  final booksAsync = ref.watch(booksStreamProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final sortMode = ref.watch(sortModeProvider);

  return booksAsync.whenData((books) {
    var filtered = books.where((book) {
      if (query.isEmpty) return true;
      return book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query);
    }).toList();

    switch (sortMode) {
      case SortMode.recent:
        filtered.sort((a, b) {
          final aTime = a.lastRead ?? DateTime(2000);
          final bTime = b.lastRead ?? DateTime(2000);
          return bTime.compareTo(aTime);
        });
        break;
      case SortMode.titleAsc:
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortMode.titleDesc:
        filtered.sort((a, b) => b.title.compareTo(a.title));
        break;
    }

    return filtered;
  });
});

// Book upload state
final bookUploadProvider =
    StateNotifierProvider<BookUploadNotifier, AsyncValue<void>>((ref) {
      return BookUploadNotifier(ref.watch(firebaseServiceProvider));
    });

class BookUploadNotifier extends StateNotifier<AsyncValue<void>> {
  final FirebaseService _service;
  BookUploadNotifier(this._service) : super(const AsyncData(null));

  Future<void> uploadBook({
    required File file,
    required String title,
    required String author,
    required String fileType,
  }) async {
    state = const AsyncLoading();
    try {
      await _service.uploadBook(
        file: file,
        title: title,
        author: author,
        fileType: fileType,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
