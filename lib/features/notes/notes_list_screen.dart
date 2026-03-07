import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/note.dart';
import '../library/library_provider.dart';

/// Stream all notes across all books
final allNotesStreamProvider = StreamProvider<List<Note>>((ref) {
  final service = ref.watch(firebaseServiceProvider);
  // Stream all notes (no book filter)
  return service.streamAllNotes();
});

class NotesListScreen extends ConsumerWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(allNotesStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 80,
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notes yet',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add notes while reading to see them here',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final note = notes[index];
              return _NoteCard(note: note);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  final Note note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateStr = DateFormat.yMMMd().add_jm().format(note.createdAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 28,
                  width: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    icon: Icon(
                      Icons.edit_outlined,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    onPressed: () => _editNote(context, ref),
                  ),
                ),
                SizedBox(
                  height: 28,
                  width: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error.withValues(alpha: 0.6),
                    ),
                    onPressed: () => _deleteNote(ref),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(note.noteText, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  void _editNote(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: note.noteText);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Note'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Enter your note...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final service = ref.read(firebaseServiceProvider);
      await service.updateNote(note.id, result);
    }
  }

  void _deleteNote(WidgetRef ref) async {
    final service = ref.read(firebaseServiceProvider);
    await service.deleteNote(note.id);
  }
}
