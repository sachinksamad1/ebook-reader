import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/book.dart';
import '../../core/theme/app_theme.dart';
import '../../services/epub_parser_service.dart';
import '../dictionary/dictionary_popup.dart';
import 'epub_webview_reader.dart';
import 'reader_settings.dart';
import 'add_note_sheet.dart';
import 'chapter_sidebar.dart';
import '../library/library_provider.dart';
import '../settings/settings_provider.dart';

class EpubReaderScreen extends ConsumerStatefulWidget {
  final Book book;
  final File file;

  const EpubReaderScreen({super.key, required this.book, required this.file});

  @override
  ConsumerState<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends ConsumerState<EpubReaderScreen> {
  final GlobalKey<EpubWebViewReaderState> _readerKey = GlobalKey();

  ParsedEpub? _parsedEpub;
  bool _isLoading = true;
  String? _error;

  bool _showControls = false;
  bool _showSidebar = false;
  double _currentProgress = 0.0;
  int _currentChapterIndex = 0;
  List<ChapterEntry> _chapters = [];

  @override
  void initState() {
    super.initState();
    _parseEpub();
  }

  Future<void> _parseEpub() async {
    try {
      final parser = EpubParserService();
      final parsed = await parser.parseBook(widget.file);

      if (!mounted) return;

      // Build chapter list for sidebar
      final chapterEntries = parsed.chapters
          .map((ch) => ChapterEntry(title: ch.title, index: ch.index))
          .toList();

      // Determine starting chapter from last location
      var startChapter = 0;
      double startScroll = 0.0;
      if (widget.book.lastLocation != null) {
        final parts = widget.book.lastLocation!.split(':');
        if (parts.length == 2) {
          startChapter =
              int.tryParse(parts[0])?.clamp(0, parsed.chapters.length - 1) ?? 0;
          startScroll = double.tryParse(parts[1]) ?? 0.0;
        }
      }

      setState(() {
        _parsedEpub = parsed;
        _chapters = chapterEntries;
        _currentChapterIndex = startChapter;
        _isLoading = false;
      });

      // Scroll to saved position after content loads
      if (startScroll > 0.0) {
        // Delay to let WebView finish rendering
        Future.delayed(const Duration(milliseconds: 800), () {
          _readerKey.currentState?.scrollToPercent(startScroll);
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
    final settingsAsync = ref.watch(userSettingsProvider);
    final settings = settingsAsync.valueOrNull;

    // Use default values while settings load to prevent flicker
    final readerTheme = ReaderTheme.fromMode(
      settings?.themeMode ?? ReaderThemeMode.light,
    );
    final fontSize = settings?.fontSize ?? 16.0;
    final fontFamily = settings?.fontFamily ?? ReaderFontFamily.system;

    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: readerTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: readerTheme.backgroundColor,
          foregroundColor: readerTheme.textColor,
          title: Text(widget.book.title),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading book...'),
            ],
          ),
        ),
      );
    }

    if (_error != null || _parsedEpub == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.book.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to parse EPUB:\n${_error ?? "Unknown error"}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _parseEpub();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final epub = _parsedEpub!;
    final currentChapter = epub.chapters[_currentChapterIndex];

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
                // Chapter navigation buttons
                if (epub.chapters.length > 1) ...[
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Previous Chapter',
                    onPressed: _currentChapterIndex > 0
                        ? () => _goToChapter(_currentChapterIndex - 1)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Next Chapter',
                    onPressed: _currentChapterIndex < epub.chapters.length - 1
                        ? () => _goToChapter(_currentChapterIndex + 1)
                        : null,
                  ),
                ],
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
      body: Stack(
        children: [
          // WebView Reader
          EpubWebViewReader(
            key: _readerKey,
            chapter: currentChapter,
            combinedCss: epub.combinedCss,
            backgroundColor: readerTheme.backgroundColor,
            textColor: readerTheme.textColor,
            fontSize: fontSize,
            fontFamily: fontFamily,
            onScrollProgress: _onScrollProgress,
            onTextSelected: _showDictionaryPopup,
            onTap: () {
              setState(() => _showControls = !_showControls);
            },
          ),

          // Progress bar
          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: _currentProgress,
                    backgroundColor: readerTheme.backgroundColor.withValues(
                      alpha: 0.5,
                    ),
                    color: theme.colorScheme.primary,
                    minHeight: 4,
                  ),
                  // Chapter indicator
                  Container(
                    color: readerTheme.backgroundColor.withValues(alpha: 0.85),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            currentChapter.title,
                            style: TextStyle(
                              color: readerTheme.textColor.withValues(
                                alpha: 0.6,
                              ),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${_currentChapterIndex + 1} / ${epub.chapters.length}',
                          style: TextStyle(
                            color: readerTheme.textColor.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
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
                currentChapterIndex: _currentChapterIndex,
                onChapterSelected: (ch) => _goToChapter(ch.index),
                onClose: () => setState(() => _showSidebar = false),
              ),
            ),
        ],
      ),
    );
  }

  void _onScrollProgress(double scrollPercent) {
    final epub = _parsedEpub;
    if (epub == null) return;

    final totalChapters = epub.chapters.length;
    final globalProgress =
        (_currentChapterIndex + scrollPercent) / totalChapters;

    setState(() {
      _currentProgress = globalProgress.clamp(0.0, 1.0);
    });

    _updateProgress(scrollPercent);
  }

  void _goToChapter(int index) {
    final epub = _parsedEpub;
    if (epub == null || index < 0 || index >= epub.chapters.length) return;

    setState(() {
      _currentChapterIndex = index;
      _showSidebar = false;
    });
  }

  void _toggleSidebar() {
    setState(() => _showSidebar = !_showSidebar);
  }

  void _showSettings() {
    final settingsAsync = ref.read(userSettingsProvider);
    final settings = settingsAsync.valueOrNull;
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

  void _showAddNoteSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddNoteSheet(bookId: widget.book.id),
    );
  }

  void _showDictionaryPopup(String selectedText) {
    if (selectedText.isEmpty) return;
    // Extract the first word if multiple words are selected
    final word = selectedText.trim().split(RegExp(r'\s+')).first;
    if (word.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DictionaryPopup(word: word, bookId: widget.book.id),
    );
  }

  void _updateProgress([double scrollPercent = 0.0]) {
    final service = ref.read(firebaseServiceProvider);
    final location =
        '$_currentChapterIndex:${scrollPercent.toStringAsFixed(4)}';

    service.updateBookProgress(
      widget.book.id,
      _currentProgress,
      lastLocation: location,
    );
  }
}
