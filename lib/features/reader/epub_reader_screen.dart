import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epub_view/epub_view.dart';

import '../../models/book.dart';
import '../../core/theme/app_theme.dart';
import 'reader_settings.dart';
import 'add_note_sheet.dart';
import 'chapter_sidebar.dart';
import '../library/library_provider.dart';

class EpubReaderScreen extends ConsumerStatefulWidget {
  final Book book;
  final File file;

  const EpubReaderScreen({super.key, required this.book, required this.file});

  @override
  ConsumerState<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends ConsumerState<EpubReaderScreen> {
  late EpubController _epubController;
  bool _showControls = false;
  bool _showSidebar = false;
  ReaderThemeMode _readerTheme = ReaderThemeMode.light;
  double _fontSize = 16.0;
  int _totalChapters = 1;
  double _currentProgress = 0.0;
  List<ChapterEntry> _chapters = [];

  @override
  void initState() {
    super.initState();
    _epubController = EpubController(
      document: EpubDocument.openFile(widget.file),
      epubCfi: widget.book.lastLocation,
    );
  }

  @override
  void dispose() {
    _epubController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readerTheme = ReaderTheme.fromMode(_readerTheme);
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
                IconButton(
                  icon: const Icon(Icons.toc),
                  tooltip: 'Chapters',
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
                  EpubView(
                    controller: _epubController,
                    builders: EpubViewBuilders<DefaultBuilderOptions>(
                      options: DefaultBuilderOptions(
                        textStyle: TextStyle(
                          fontSize: _fontSize,
                          color: readerTheme.textColor,
                          height: 1.6,
                        ),
                      ),
                      chapterDividerBuilder: (_) => const Divider(height: 32),
                    ),
                    onDocumentLoaded: (document) {
                      debugPrint('EPUB loaded: ${document.Title}');
                      if (mounted) {
                        setState(() {
                          _totalChapters = document.Chapters?.length ?? 1;
                          if (_totalChapters == 0) _totalChapters = 1;
                        });
                        // Build chapter list from TOC
                        _buildChapterList();
                      }
                    },
                    onChapterChanged: (value) {
                      if (value == null || !mounted) return;

                      final int chapterIndex = value.chapterNumber;
                      final double chapterProgress = value.progress / 100.0;

                      int baseIndex = chapterIndex - 1;
                      if (baseIndex < 0) baseIndex = 0;

                      final progress =
                          (baseIndex + chapterProgress) / _totalChapters;

                      setState(() {
                        _currentProgress = progress.clamp(0.0, 1.0);
                      });
                      _updateProgress();
                    },
                  ),
                  if (_showControls)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: _currentProgress,
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
                  chapters: _chapters,
                  onChapterSelected: _onChapterSelected,
                  onClose: () => setState(() => _showSidebar = false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ReaderSettingsSheet(
        currentTheme: _readerTheme,
        currentFontSize: _fontSize,
        onThemeChanged: (theme) {
          setState(() => _readerTheme = theme);
        },
        onFontSizeChanged: (size) {
          setState(() => _fontSize = size);
        },
      ),
    );
  }

  void _showAddNoteSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddNoteSheet(bookId: widget.book.id),
    );
  }

  void _toggleSidebar() {
    setState(() => _showSidebar = !_showSidebar);
  }

  void _buildChapterList() {
    final toc = _epubController.tableOfContents();
    setState(() {
      _chapters = toc
          .map(
            (ch) => ChapterEntry(
              title: ch.title ?? 'Untitled',
              index: ch.startIndex,
              isSubChapter: ch.type == 'subchapter',
            ),
          )
          .toList();
    });
  }

  void _onChapterSelected(ChapterEntry chapter) {
    _epubController.scrollTo(
      index: chapter.index,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _updateProgress() {
    // Update reading progress in Firestore
    final service = ref.read(firebaseServiceProvider);

    // Generate the current CFI to save exactly where the user is
    final cfi = _epubController.generateEpubCfi();

    service.updateBookProgress(
      widget.book.id,
      _currentProgress,
      lastLocation: cfi,
    );
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
