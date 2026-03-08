import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/book.dart';
import '../reader/reader_screen.dart';
import 'library_provider.dart';
import 'book_card.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(filteredBooksProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search books...',
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
              )
            : const Text('My Library'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                }
              });
            },
          ),
          PopupMenuButton<SortMode>(
            icon: const Icon(Icons.sort),
            onSelected: (mode) {
              ref.read(sortModeProvider.notifier).state = mode;
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortMode.recent,
                child: Text('Recently Read'),
              ),
              const PopupMenuItem(
                value: SortMode.titleAsc,
                child: Text('Title A-Z'),
              ),
              const PopupMenuItem(
                value: SortMode.titleDesc,
                child: Text('Title Z-A'),
              ),
            ],
          ),
        ],
      ),
      body: booksAsync.when(
        data: (books) {
          if (books.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 80,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your library is empty',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first book',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.58,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: books.length,
              itemBuilder: (context, index) {
                return BookCard(
                  book: books[index],
                  onTap: () => _openBook(books[index]),
                  onDelete: () => _deleteBook(books[index]),
                  onChangeCover: () => _changeCover(books[index]),
                  onDeleteCover: () => _deleteCover(books[index]),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(booksStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploadBook,
        icon: const Icon(Icons.add),
        label: const Text('Add Book'),
      ),
    );
  }

  void _openBook(Book book) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => ReaderScreen(book: book)));
  }

  Future<void> _deleteBook(Book book) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text('Are you sure you want to delete "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final service = ref.read(firebaseServiceProvider);
      await service.deleteBook(book.id);
    }
  }

  Future<void> _changeCover(Book book) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Uploading cover...')));
    }

    try {
      final service = ref.read(firebaseServiceProvider);
      await service.updateBookCover(book.id, File(image.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update cover: $e')));
      }
    }
  }

  Future<void> _deleteCover(Book book) async {
    if (book.coverUrl == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Cover'),
        content: const Text('Are you sure you want to remove the cover image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final service = ref.read(firebaseServiceProvider);
      await service.deleteBookCover(book.id, book.coverUrl!);
    }
  }

  Future<void> _uploadBook() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub', 'pdf'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = File(result.files.single.path!);
    final fileName = result.files.single.name;
    final ext = fileName.split('.').last.toLowerCase();

    if (!mounted) return;

    // Show dialog to enter book details
    final details = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _BookDetailsDialog(fileName: fileName),
    );

    if (details == null) return;

    ref
        .read(bookUploadProvider.notifier)
        .uploadBook(
          file: file,
          title: details['title'] ?? fileName,
          author: details['author'] ?? 'Unknown',
          fileType: ext,
        );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Uploading book...')));
    }
  }
}

class _BookDetailsDialog extends StatefulWidget {
  final String fileName;

  const _BookDetailsDialog({required this.fileName});

  @override
  State<_BookDetailsDialog> createState() => _BookDetailsDialogState();
}

class _BookDetailsDialogState extends State<_BookDetailsDialog> {
  late final TextEditingController _titleController;
  final _authorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Use filename without extension as default title
    final name = widget.fileName.contains('.')
        ? widget.fileName.substring(0, widget.fileName.lastIndexOf('.'))
        : widget.fileName;
    _titleController = TextEditingController(text: name);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Book Details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'Enter book title',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _authorController,
            decoration: const InputDecoration(
              labelText: 'Author',
              hintText: 'Enter author name',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {
              'title': _titleController.text.trim(),
              'author': _authorController.text.trim(),
            });
          },
          child: const Text('Upload'),
        ),
      ],
    );
  }
}
