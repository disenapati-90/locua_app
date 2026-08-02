// iap_service.dart
// Handles the Remove Ads one-time purchase via Google Play Billing.
//
// IMPORTANT: in_app_purchase has NO web support at all — even accessing
// InAppPurchase.instance crashes on Flutter Web. Every method here checks
// kIsWeb first and safely no-ops in that case. This will work correctly
// once we test on a real Android build.

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_purchase/in_app_purchase.dart';

class IapService {
  static const String removeAdsId = 'remove_ads';
  static StreamSubscription<List<PurchaseDetails>>? _subscription;

  static void initialize({required void Function() onRemoveAdsPurchased}) {
    if (kIsWeb) return; // not supported in web preview — skip entirely

    final iap = InAppPurchase.instance;
    _subscription = iap.purchaseStream.listen((purchases) {
      for (final purchase in purchases) {
        if (purchase.productID == removeAdsId &&
            purchase.status == PurchaseStatus.purchased) {
          onRemoveAdsPurchased();
          iap.completePurchase(purchase);
        }
      }
    });
  }

  static Future<void> buyRemoveAds() async {
    if (kIsWeb) return; // no Play Billing in a browser

    final iap = InAppPurchase.instance;
    final available = await iap.isAvailable();
    if (!available) return;

    final response = await iap.queryProductDetails({removeAdsId});
    if (response.productDetails.isEmpty) return;

    final purchaseParam = PurchaseParam(productDetails: response.productDetails.first);
    await iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  static Future<void> restorePurchases() async {
    if (kIsWeb) return;
    await InAppPurchase.instance.restorePurchases();
  }

  static void dispose() {
    _subscription?.cancel();
  }
}