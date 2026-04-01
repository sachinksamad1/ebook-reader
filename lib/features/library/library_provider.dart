import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../models/book.dart';
import '../../models/collection.dart';
import '../../services/firebase_service.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

final booksStreamProvider = StreamProvider<List<Book>>((ref) {
  final service = ref.watch(firebaseServiceProvider);
  return service.streamBooks();
});

final collectionsStreamProvider = StreamProvider<List<Collection>>((ref) {
  final service = ref.watch(firebaseServiceProvider);
  return service.streamCollections();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

enum SortMode { recent, titleAsc, titleDesc }

final sortModeProvider = StateProvider<SortMode>((ref) => SortMode.recent);
final selectedCollectionIdProvider = StateProvider<String?>((ref) => null);

final filteredBooksProvider = Provider<AsyncValue<List<Book>>>((ref) {
  final booksAsync = ref.watch(booksStreamProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final sortMode = ref.watch(sortModeProvider);
  final selectedCollectionId = ref.watch(selectedCollectionIdProvider);

  return booksAsync.whenData((books) {
    var filtered = books.where((book) {
      final matchesQuery = query.isEmpty ||
          book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query);
      
      final matchesCollection = selectedCollectionId == null || 
          book.collectionId == selectedCollectionId;

      return matchesQuery && matchesCollection;
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

final collectionProvider =
    StateNotifierProvider<CollectionNotifier, AsyncValue<void>>((ref) {
  return CollectionNotifier(ref.watch(firebaseServiceProvider));
});

class CollectionNotifier extends StateNotifier<AsyncValue<void>> {
  final FirebaseService _service;
  CollectionNotifier(this._service) : super(const AsyncData(null));

  Future<void> createCollection(String name, {String? description}) async {
    state = const AsyncLoading();
    try {
      await _service.createCollection(name, description: description);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateCollection(String id,
      {String? name, String? description}) async {
    state = const AsyncLoading();
    try {
      await _service.updateCollection(id, name: name, description: description);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteCollection(String id) async {
    state = const AsyncLoading();
    try {
      await _service.deleteCollection(id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> addBookToCollection(String bookId, String? collectionId) async {
    try {
      await _service.updateBookMetadata(bookId,
          collectionId: collectionId, updateCollection: true);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final bookActionProvider =
    StateNotifierProvider<BookActionNotifier, AsyncValue<void>>((ref) {
  return BookActionNotifier(ref.watch(firebaseServiceProvider));
});

class BookActionNotifier extends StateNotifier<AsyncValue<void>> {
  final FirebaseService _service;
  BookActionNotifier(this._service) : super(const AsyncData(null));

  Future<void> updateBookInfo(String id, {String? title, String? author}) async {
    state = const AsyncLoading();
    try {
      await _service.updateBookInfo(id, title: title, author: author);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteBook(String id) async {
    state = const AsyncLoading();
    try {
      await _service.deleteBook(id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateCover(String id, File file) async {
    state = const AsyncLoading();
    try {
      await _service.updateBookCover(id, file);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteCover(String id, String url) async {
    state = const AsyncLoading();
    try {
      await _service.deleteBookCover(id, url);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

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
