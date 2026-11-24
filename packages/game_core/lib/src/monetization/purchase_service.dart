import 'package:flutter/foundation.dart';

import '../storage/key_value_store.dart';

enum PurchaseResult { purchased, cancelled, failed }

/// In-app purchases. For now the only product is "Remove Ads".
///
/// Like [AdService], the app only uses this interface; a real store-backed
/// implementation (e.g. with the `in_app_purchase` package) can replace
/// [FakePurchaseService] later.
abstract class PurchaseService extends ChangeNotifier {
  Future<void> initialize();

  /// True once "Remove Ads" has been bought (or restored).
  bool get adsRemoved;

  /// Text for the buy button, e.g. "\$2.99". Real stores provide this.
  String get removeAdsPrice;

  Future<PurchaseResult> buyRemoveAds();

  /// Re-applies purchases made earlier (e.g. after reinstalling).
  Future<void> restorePurchases();
}

/// Pretend store: buying always succeeds instantly and is remembered on the
/// device. Nothing is charged and no store account is involved.
class FakePurchaseService extends PurchaseService {
  FakePurchaseService(this._store);

  static const _key = 'purchases.removeAds';

  final KeyValueStore _store;
  bool _adsRemoved = false;

  @override
  Future<void> initialize() async {
    _adsRemoved = _store.getString(_key) == 'true';
  }

  @override
  bool get adsRemoved => _adsRemoved;

  @override
  String get removeAdsPrice => 'Free (test)';

  @override
  Future<PurchaseResult> buyRemoveAds() async {
    _adsRemoved = true;
    await _store.setString(_key, 'true');
    notifyListeners();
    return PurchaseResult.purchased;
  }

  @override
  Future<void> restorePurchases() async {
    await initialize();
    notifyListeners();
  }

  /// Development helper to bring ads back.
  Future<void> resetForTesting() async {
    _adsRemoved = false;
    await _store.remove(_key);
    notifyListeners();
  }
}
