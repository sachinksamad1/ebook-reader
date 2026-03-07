import 'dart:convert';
import 'package:http/http.dart' as http;

class DictionaryResult {
  final String word;
  final String? phonetic;
  final List<DictionaryMeaning> meanings;

  DictionaryResult({required this.word, this.phonetic, required this.meanings});

  /// First definition text, for quick display
  String get shortDefinition {
    if (meanings.isEmpty || meanings.first.definitions.isEmpty) {
      return 'No definition found.';
    }
    return meanings.first.definitions.first.definition;
  }
}

class DictionaryMeaning {
  final String partOfSpeech;
  final List<DictionaryDefinition> definitions;

  DictionaryMeaning({required this.partOfSpeech, required this.definitions});
}

class DictionaryDefinition {
  final String definition;
  final String? example;

  DictionaryDefinition({required this.definition, this.example});
}

class DictionaryService {
  static const String _baseUrl =
      'https://api.dictionaryapi.dev/api/v2/entries/en';

  /// Look up a word and return parsed result
  Future<DictionaryResult?> lookup(String word) async {
    final cleanWord = word.trim().toLowerCase();
    if (cleanWord.isEmpty) return null;

    try {
      final response = await http.get(Uri.parse('$_baseUrl/$cleanWord'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isEmpty) return null;

        final entry = data[0] as Map<String, dynamic>;

        final meanings =
            (entry['meanings'] as List<dynamic>?)?.map((m) {
              final defs =
                  (m['definitions'] as List<dynamic>?)
                      ?.map(
                        (d) => DictionaryDefinition(
                          definition: d['definition'] ?? '',
                          example: d['example'],
                        ),
                      )
                      .toList() ??
                  [];
              return DictionaryMeaning(
                partOfSpeech: m['partOfSpeech'] ?? '',
                definitions: defs,
              );
            }).toList() ??
            [];

        return DictionaryResult(
          word: entry['word'] ?? cleanWord,
          phonetic: entry['phonetic'],
          meanings: meanings,
        );
      }
    } catch (_) {}

    return null;
  }
}
