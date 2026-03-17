import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../models/book.dart';
import '../../core/theme/app_theme.dart';
import '../dictionary/dictionary_popup.dart';
import 'reader_settings.dart';
import 'add_note_sheet.dart';
import 'chapter_sidebar.dart';
import '../library/library_provider.dart';
import '../settings/settings_provider.dart';

class PdfReaderScreen extends ConsumerStatefulWidget {
  final Book book;
  final File file;

  const PdfReaderScreen({super.key, required this.book, required this.file});

  @override
  ConsumerState<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen> {
  late PdfViewerController _pdfController;
  bool _showControls = true;
  bool _showSidebar = false;
  int _totalPages = 0;
  int _currentPage = 0;
  List<ChapterEntry> _pageChapters = [];

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(userSettingsProvider);
    final settings = settingsAsync.value;

    final readerTheme = ReaderTheme.fromMode(
      settings?.themeMode ?? ReaderThemeMode.light,
    );
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: readerTheme.backgroundColor,
      appBar: _showControls
          ? AppBar(
              backgroundColor: readerTheme.backgroundColor.withValues(
                alpha: 0.95,
              ),
              foregroundColor: readerTheme.textColor,
              title: Text(
                widget.book.title,
                style: TextStyle(color: readerTheme.textColor, fontSize: 16),
              ),
              actions: [
                if (_totalPages > 0)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        '$_currentPage / $_totalPages',
                        style: TextStyle(
                          color: readerTheme.textColor.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.toc),
                  tooltip: 'Pages',
                  onPressed: _toggleSidebar,
                ),
                IconButton(
                  icon: const Icon(Icons.note_add_outlined),
                  onPressed: _showAddNoteSheet,
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: _showSettings,
                ),
              ],
            )
          : null,
      body: ScrollConfiguration(
        behavior: const _SmoothScrollBehavior(),
        child: Stack(
          children: [
            GestureDetector(
              onTap: () {
                setState(() => _showControls = !_showControls);
              },
              child: Stack(
                children: [
                  SfPdfViewer.file(
                    widget.file,
                    controller: _pdfController,
                    canShowScrollHead: _showControls,
                    onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                      if (mounted) {
                        setState(() {
                          _totalPages = details.document.pages.count;
                          _currentPage = 1;
                        });
                        _buildPageChapters();
                        // Jump to last saved location if available
                        if (widget.book.lastLocation != null) {
                          final targetPage = int.tryParse(
                            widget.book.lastLocation!,
                          );
                          if (targetPage != null &&
                              targetPage > 0 &&
                              targetPage <= _totalPages) {
                            _pdfController.jumpToPage(targetPage);
                          }
                        }
                      }
                    },
                    onPageChanged: (PdfPageChangedDetails details) {
                      setState(() {
                        _currentPage = details.newPageNumber;
                      });
                      _updateProgress();
                    },
                    onTextSelectionChanged:
                        (PdfTextSelectionChangedDetails details) {
                          if (details.selectedText != null &&
                              details.selectedText!.isNotEmpty) {
                            _showDictionaryPopup(details.selectedText!);
                          }
                        },
                  ),
                  if (_showControls && _totalPages > 0)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: _currentPage / _totalPages,
                        backgroundColor: readerTheme.backgroundColor.withValues(
                          alpha: 0.5,
                        ),
                        color: theme.colorScheme.primary,
                        minHeight: 4,
                      ),
                    ),
                ],
              ),
            ),
            // Chapter sidebar overlay
            if (_showSidebar)
              Positioned.fill(
                child: ChapterSidebar(
                  chapters: _pageChapters,
                  currentChapterIndex: _currentPage,
                  onChapterSelected: _onPageSelected,
                  onClose: () => setState(() => _showSidebar = false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSettings() {
    final settingsAsync = ref.read(userSettingsProvider);
    final settings = settingsAsync.value;
    if (settings == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => ReaderSettingsSheet(
        currentTheme: settings.themeMode,
        currentFontSize: settings.fontSize,
        currentFontFamily: settings.fontFamily,
        onThemeChanged: (theme) {
          ref
              .read(userSettingsNotifierProvider.notifier)
              .updateThemeMode(theme);
        },
        onFontSizeChanged: (size) {
          ref.read(userSettingsNotifierProvider.notifier).updateFontSize(size);
        },
        onFontFamilyChanged: (family) {
          ref
              .read(userSettingsNotifierProvider.notifier)
              .updateFontFamily(family);
        },
      ),
    );
  }

  void _showAddNoteSheet({String? initialText}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          AddNoteSheet(bookId: widget.book.id, initialText: initialText),
    );
  }

  void _toggleSidebar() {
    setState(() => _showSidebar = !_showSidebar);
  }

  void _buildPageChapters() {
    setState(() {
      _pageChapters = List.generate(
        _totalPages,
        (i) => ChapterEntry(title: 'Page ${i + 1}', index: i + 1),
      );
    });
  }

  void _onPageSelected(ChapterEntry chapter) {
    _pdfController.jumpToPage(chapter.index);
  }

  void _showDictionaryPopup(String selectedText) {
    // Extract the first word if multiple words are selected
    final word = selectedText.trim().split(RegExp(r'\s+')).first;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DictionaryPopup(word: word, bookId: widget.book.id),
    );
  }

  void _updateProgress() {
    if (_totalPages > 0) {
      final progress = _currentPage / _totalPages;
      final service = ref.read(firebaseServiceProvider);
      service.updateBookProgress(
        widget.book.id,
        progress,
        lastLocation: _currentPage.toString(),
      );
    }
  }
}

/// Custom scroll behavior that applies smooth, bouncing scroll physics.
class _SmoothScrollBehavior extends ScrollBehavior {
  const _SmoothScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      decelerationRate: ScrollDecelerationRate.fast,
    );
  }
}
