import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/dictionary_service.dart';
import '../../models/vocabulary.dart';
import '../library/library_provider.dart';

/// Provider for dictionary lookups
final dictionaryServiceProvider = Provider<DictionaryService>((ref) {
  return DictionaryService();
});

class DictionaryPopup extends ConsumerStatefulWidget {
  final String word;
  final String bookId;

  const DictionaryPopup({super.key, required this.word, required this.bookId});

  @override
  ConsumerState<DictionaryPopup> createState() => _DictionaryPopupState();
}

class _DictionaryPopupState extends ConsumerState<DictionaryPopup> {
  DictionaryResult? _result;
  bool _isLoading = true;
  String? _error;
  bool _savedToVocab = false;

  @override
  void initState() {
    super.initState();
    _lookupWord();
  }

  Future<void> _lookupWord() async {
    try {
      final service = ref.read(dictionaryServiceProvider);
      final result = await service.lookup(widget.word);
      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
          if (result == null) _error = 'Word not found';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to look up word';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Word
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.word,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              if (_result?.phonetic != null)
                Text(
                  _result!.phonetic!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Content
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_result != null)
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meanings
                    for (final meaning in _result!.meanings) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          meaning.partOfSpeech,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (
                        var i = 0;
                        i < meaning.definitions.length && i < 3;
                        i++
                      ) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${i + 1}. ',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(meaning.definitions[i].definition),
                                  if (meaning.definitions[i].example != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '"${meaning.definitions[i].example}"',
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _savedToVocab ? null : _saveToVocabulary,
                  icon: Icon(_savedToVocab ? Icons.check : Icons.bookmark_add),
                  label: Text(_savedToVocab ? 'Saved' : 'Save Word'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveToVocabulary() async {
    if (_result == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Must be logged in to save words')),
        );
      }
      return;
    }

    final service = ref.read(firebaseServiceProvider);
    await service.addVocabularyWord(
      VocabularyWord(
        id: '',
        userId: user.uid,
        word: widget.word,
        meaning: _result!.shortDefinition,
        bookId: widget.bookId,
      ),
    );

    if (mounted) {
      setState(() => _savedToVocab = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${widget.word}" saved to vocabulary')),
      );
    }
  }
}
