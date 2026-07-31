// word.dart
// Represents a single vocabulary word loaded from word_bank.json (static content).
// This is read-only reference data — actual learning progress lives separately
// in progress.dart, so we never mix "what the word is" with "how well I know it."

class Word {
  final String word;
  final String theme;
  final int storyEpisode;
  final String sentence;
  final String definition;
  final List<String> synonyms;
  final List<String> antonyms;
  final String level; // "easy" | "medium" | "hard"

  Word({
    required this.word,
    required this.theme,
    required this.storyEpisode,
    required this.sentence,
    required this.definition,
    required this.synonyms,
    required this.antonyms,
    required this.level,
  });

  // Converts a raw JSON map (from word_bank.json) into a Word object.
  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      word: json['word'],
      theme: json['theme'],
      storyEpisode: json['storyEpisode'],
      sentence: json['sentence'],
      definition: json['definition'],
      synonyms: List<String>.from(json['synonyms']),
      antonyms: List<String>.from(json['antonyms']),
      level: json['level'],
    );
  }
}