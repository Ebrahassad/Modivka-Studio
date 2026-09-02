import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

/// Thin wrapper around Unity Ads.
///
/// Every public method here is safe to call at any time, from any
/// platform, whether or not the SDK has initialized or an ad has
/// loaded. Nothing in this file ever throws out to the caller — a
/// missing/failed ad is always a silent no-op, never a crash or a
/// visible error. The rest of the app never needs to check "is this
/// ready" before calling these methods.
class AdsService {
  AdsService._();

  static const String _gameId = '800365850';

  static const String interstitialPlacementId = 'Interstitial_Android';
  static const String rewardedPlacementId = 'Rewarded_Android';
  static const String bannerPlacementId = 'Banner_Android';

  // Set this to false before a real production release. While true,
  // Unity serves test creatives that always fill, which is useful for
  // verifying the whole pipeline (init -> load -> show) end to end
  // before switching to live ads.
  static const bool _testMode = true;

  static bool _initialized = false;
  static bool _interstitialReady = false;
  static bool _rewardedReady = false;

  /// Whether the banner should currently be shown. Starts true (so it
  /// attempts to load); the banner widget flips this to false on
  /// failure and simply disappears — no broken placeholder, no error
  /// shown to the user.
  static final ValueNotifier<bool> bannerAvailable = ValueNotifier<bool>(
    true,
  );

  /// True only on platforms Unity Ads actually supports. Every other
  /// method below checks this first, so calling them on web/desktop
  /// (or any future platform) is always a harmless no-op instead of a
  /// MissingPluginException.
  static bool get _supported {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  /// Call once, early in main(). Never throws, never awaited by the
  /// caller — ad setup happens in the background and never blocks or
  /// delays app startup.
  static void init() {
    if (!_supported) return;

    try {
      UnityAds.init(
        gameId: _gameId,
        testMode: _testMode,
        onComplete: () {
          _initialized = true;
          _loadInterstitial();
          _loadRewarded();
        },
        onFailed: (error, message) {
          _initialized = false;
        },
      );
    } catch (_) {
      // SDK unavailable for any reason — the app keeps working ad-free.
    }
  }

  static void _loadInterstitial() {
    if (!_supported || !_initialized) return;
    try {
      UnityAds.load(
        placementId: interstitialPlacementId,
        onComplete: (placementId) => _interstitialReady = true,
        onFailed: (placementId, error, message) =>
            _interstitialReady = false,
      );
    } catch (_) {
      _interstitialReady = false;
    }
  }

  static void _loadRewarded() {
    if (!_supported || !_initialized) return;
    try {
      UnityAds.load(
        placementId: rewardedPlacementId,
        onComplete: (placementId) => _rewardedReady = true,
        onFailed: (placementId, error, message) => _rewardedReady = false,
      );
    } catch (_) {
      _rewardedReady = false;
    }
  }

  /// Shows the interstitial if (and only if) one is already loaded.
  /// Otherwise does nothing at all — no error, no delay, no retry loop
  /// blocking the caller. A fresh ad is queued up for next time either
  /// way.
  static void showInterstitial() {
    if (!_supported || !_initialized || !_interstitialReady) {
      // Not ready yet — try to have one ready for next time, but don't
      // make the current action wait on it.
      _loadInterstitial();
      return;
    }

    _interstitialReady = false;
    try {
      UnityAds.showVideoAd(
        placementId: interstitialPlacementId,
        onComplete: (placementId) => _loadInterstitial(),
        onFailed: (placementId, error, message) => _loadInterstitial(),
        onSkipped: (placementId) => _loadInterstitial(),
      );
    } catch (_) {
      _loadInterstitial();
    }
  }

  /// Shows the rewarded ad if one is loaded. [onReward] is called only
  /// if the ad actually played to completion. If no ad is available,
  /// this silently does nothing — it never blocks or fakes the reward.
  static void showRewarded({VoidCallback? onReward}) {
    if (!_supported || !_initialized || !_rewardedReady) {
      _loadRewarded();
      return;
    }

    _rewardedReady = false;
    try {
      UnityAds.showVideoAd(
        placementId: rewardedPlacementId,
        onComplete: (placementId) {
          onReward?.call();
          _loadRewarded();
        },
        onFailed: (placementId, error, message) => _loadRewarded(),
        onSkipped: (placementId) => _loadRewarded(),
      );
    } catch (_) {
      _loadRewarded();
    }
  }
}
