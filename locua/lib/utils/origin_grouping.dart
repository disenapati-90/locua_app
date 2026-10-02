// origin_grouping.dart
// Shared language-grouping/flag logic, extracted from origins_screen.dart
// so home_screen.dart can group/display origin words identically without
// duplicating this — both screens must agree on the same grouping.

import 'package:flutter/material.dart';

const List<String> africanKeywords = [
  'african', 'bantu', 'swahili', 'congo', 'congolese', 'yoruba', 'zulu',
  'xhosa', 'igbo', 'hausa', 'amharic', 'ethiopian', 'akan', 'wolof',
];

const String africanDisplayName = 'African';

String displayGroupFor(String originLanguage) {
  final lower = originLanguage.toLowerCase();
  for (final kw in africanKeywords) {
    if (lower.contains(kw)) return africanDisplayName;
  }
  return originLanguage;
}

String? flagCodeFor(String displayGroup) {
  final key = displayGroup.toLowerCase();
  const map = {
    'french': 'fr', 'spanish': 'es', 'arabic': 'sa', 'persian': 'ir',
    'iranian': 'ir', 'indian': 'in', 'japanese': 'jp', 'korean': 'kr',
    'chinese': 'cn', 'african': 'za', 'italian': 'it', 'german': 'de',
    'portuguese': 'pt', 'dutch': 'nl', 'russian': 'ru', 'turkish': 'tr',
    'greek': 'gr', 'hebrew': 'il',
  };
  return map[key];
}

const List<Color> originTileAccentColors = [
  Color(0xFFE0A233), Color(0xFF4F8FE0), Color(0xFF4FAE7C),
  Color(0xFFD1568C), Color(0xFF3FB6B0), Color(0xFFD1594F), Color(0xFF8B6FD1),
];