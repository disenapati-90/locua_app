// ad_provider.dart
// Central place deciding WHEN to show a banner ad — banner after every
// 5th question (Q5, Q10, Q15...), capped at 3 impressions per session.
// This is a separate concern from SRS scheduling (progress_provider.dart) —
// ad timing is about session pacing, not learning science.

import 'package:flutter/material.dart';

class AdProvider extends ChangeNotifier {
  int _questionCount = 0;
  int _adsShownThisSession = 0;
  static const int _maxAdsPerSession = 3;
  static const int _questionsPerAd = 5;

  bool isAdFree = false; // flips to true once Remove Ads IAP is purchased (Day 12)

  // Call this every time a question is answered (Practice screen).
  // Returns true if a banner should be shown right now.
  bool registerAnsweredQuestion() {
    if (isAdFree) return false;

    _questionCount++;
    if (_questionCount % _questionsPerAd == 0 &&
        _adsShownThisSession < _maxAdsPerSession) {
      _adsShownThisSession++;
      notifyListeners();
      return true;
    }
    return false;
  }

  void resetSession() {
    _questionCount = 0;
    _adsShownThisSession = 0;
    notifyListeners();
  }
  // Called when Remove Ads purchase completes (or is restored).
  void setAdFree(bool value) {
    isAdFree = value;
    notifyListeners();
  }
}