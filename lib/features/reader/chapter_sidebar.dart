import 'dart:async';
import 'package:flutter/material.dart';

/// A single entry in the chapter sidebar.
class ChapterEntry {
  final String title;
  final int index;
  final bool isSubChapter;

  const ChapterEntry({
    required this.title,
    required this.index,
    this.isSubChapter = false,
  });
}

/// An animated sidebar that slides in from the left showing a list of chapters.
/// Auto-hides after [autoHideDuration] of inactivity.
class ChapterSidebar extends StatefulWidget {
  final List<ChapterEntry> chapters;
  final int? currentChapterIndex;
  final ValueChanged<ChapterEntry> onChapterSelected;
  final VoidCallback onClose;
  final Duration autoHideDuration;

  const ChapterSidebar({
    super.key,
    required this.chapters,
    required this.onChapterSelected,
    required this.onClose,
    this.currentChapterIndex,
    this.autoHideDuration = const Duration(seconds: 5),
  });

  @override
  State<ChapterSidebar> createState() => _ChapterSidebarState();
}

class _ChapterSidebarState extends State<ChapterSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  Timer? _autoHideTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
    _resetAutoHideTimer();
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _resetAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(widget.autoHideDuration, _closeSidebar);
  }

  Future<void> _closeSidebar() async {
    await _animController.reverse();
    if (mounted) {
      widget.onClose();
    }
  }

  void _onChapterTap(ChapterEntry chapter) {
    widget.onChapterSelected(chapter);
    _closeSidebar();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = screenWidth * 0.75;

    return Stack(
      children: [
        // Scrim overlay — tapping it dismisses sidebar
        GestureDetector(
          onTap: _closeSidebar,
          child: FadeTransition(
            opacity: _animController,
            child: Container(color: Colors.black54),
          ),
        ),

        // Sidebar
        SlideTransition(
          position: _slideAnimation,
          child: GestureDetector(
            // Reset timer when user interacts with sidebar
            onPanDown: (_) => _resetAutoHideTimer(),
            child: Material(
              elevation: 16,
              child: Container(
                width: sidebarWidth,
                height: double.infinity,
                color: theme.scaffoldBackgroundColor,
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                        child: Row(
                          children: [
                            Icon(Icons.toc, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Chapters',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: _closeSidebar,
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Chapter list
                      Expanded(
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (_) {
                            _resetAutoHideTimer();
                            return false;
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: widget.chapters.length,
                            itemBuilder: (context, index) {
                              final chapter = widget.chapters[index];
                              final isActive =
                                  widget.currentChapterIndex == chapter.index;

                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.only(
                                  left: chapter.isSubChapter ? 40 : 16,
                                  right: 16,
                                ),
                                selected: isActive,
                                selectedTileColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                leading: isActive
                                    ? Icon(
                                        Icons.chevron_right,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      )
                                    : null,
                                title: Text(
                                  chapter.title,
                                  style: TextStyle(
                                    fontSize: chapter.isSubChapter ? 13 : 14,
                                    fontWeight: isActive
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isActive
                                        ? theme.colorScheme.primary
                                        : null,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => _onChapterTap(chapter),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
