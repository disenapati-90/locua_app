// native_banner_ad.dart
// Wraps a real AdMob BannerAd inside a themed card (gold border, small
// "Sponsored" label) so it visually matches Locua's design instead of
// looking like a bolted-on default ad box.

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NativeBannerAd extends StatefulWidget {
  const NativeBannerAd({super.key});

  @override
  State<NativeBannerAd> createState() => _NativeBannerAdState();
}

class _NativeBannerAdState extends State<NativeBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // Google's official Android test banner ad unit ID — safe for development.
  static const String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _testBannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose(); // avoid a broken/half-loaded ad taking up space
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'SPONSORED',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 10,
                    letterSpacing: 1,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        ],
      ),
    );
  }
}