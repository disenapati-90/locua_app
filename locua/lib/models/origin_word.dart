// origin_word.dart
// Represents a single foreign-origin word from origin_words.json.
// Kept separate from word.dart since Origins content has different
// fields (originLanguage, originSpelling, pronunciationLocale, funFact)
// and no story/episode structure.

class OriginWord {
  final String word;
  final String originLanguage;
  final String originSpelling;
  final String pronunciationLocale; // BCP-47 code, e.g. "fa-IR"
  final String meaning;
  final String funFact;
  final String level;

  OriginWord({
    required this.word,
    required this.originLanguage,
    required this.originSpelling,
    required this.pronunciationLocale,
    required this.meaning,
    required this.funFact,
    required this.level,
  });

  factory OriginWord.fromJson(Map<String, dynamic> json) {
    return OriginWord(
      word: json['word'],
      originLanguage: json['originLanguage'],
      originSpelling: json['originSpelling'],
      pronunciationLocale: json['pronunciationLocale'],
      meaning: json['meaning'],
      funFact: json['funFact'],
      level: json['level'],
    );
  }
}