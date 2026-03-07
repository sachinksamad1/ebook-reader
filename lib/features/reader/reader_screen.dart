import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/book.dart';
import '../../services/cache_service.dart';
import 'epub_reader_screen.dart';
import 'pdf_reader_screen.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final Book book;

  const ReaderScreen({super.key, required this.book});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  bool _isLoading = true;
  File? _localFile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    try {
      final cacheService = CacheService();
      final file = await cacheService.getCachedFile(widget.book.fileUrl);
      if (mounted) {
        setState(() {
          _localFile = file;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.book.title)),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Downloading book...'),
            ],
          ),
        ),
      );
    }

    if (_error != null || _localFile == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.book.title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load book:\n${_error ?? "Unknown error"}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadBook();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Route to the appropriate reader based on file type
    if (widget.book.fileType == 'pdf') {
      return PdfReaderScreen(book: widget.book, file: _localFile!);
    } else {
      return EpubReaderScreen(book: widget.book, file: _localFile!);
    }
  }
}
