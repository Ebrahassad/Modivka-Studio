#!/usr/bin/env python3
import sys, shutil, os

ADS = "lib/services/ads_service.dart"
STRINGS = "lib/utils/app_strings.dart"
HOME = "lib/screens/home_screen.dart"

FILES = [ADS, STRINGS, HOME]
for p in FILES:
    if not os.path.isfile(p):
        print(f"File not found: {p}")
        sys.exit(1)

def backup(path):
    b = path + ".bak_gate"
    shutil.copy(path, b)
    print(f"Backup created: {b}")

for p in FILES:
    backup(p)

def load(p):
    with open(p, "r", encoding="utf-8") as f:
        return f.read()

def save(p, s):
    with open(p, "w", encoding="utf-8") as f:
        f.write(s)

def patch_one(src, old, new, label):
    count = src.count(old)
    if count != 1:
        print(f"[ABORT] {label}: found {count} times, expected 1.")
        sys.exit(1)
    return src.replace(old, new, 1)

a = load(ADS)
old_marker = "  /// Shows the rewarded ad if one is loaded."
new_method = '''  /// Shows the interstitial and calls [onReady] once it's done being
  /// shown (whether the user watched it fully, skipped it, or it failed
  /// mid-playback) — used to gate an action behind watching an ad.
  /// If no ad is available at all (offline, not loaded yet, etc.),
  /// calls [onUnavailable] instead and never calls [onReady].
  static void showInterstitialThen({
    required VoidCallback onReady,
    required VoidCallback onUnavailable,
  }) {
    if (!_supported) {
      onReady();
      return;
    }

    if (!_initialized || !_interstitialReady) {
      _loadInterstitial();
      onUnavailable();
      return;
    }

    _interstitialReady = false;
    try {
      UnityAds.showVideoAd(
        placementId: interstitialPlacementId,
        onComplete: (placementId) {
          _loadInterstitial();
          onReady();
        },
        onSkipped: (placementId) {
          _loadInterstitial();
          onReady();
        },
        onFailed: (placementId, error, message) {
          _loadInterstitial();
          onReady();
        },
      );
    } catch (_) {
      _loadInterstitial();
      onReady();
    }
  }

  /// Shows the rewarded ad if one is loaded.'''
a = patch_one(a, old_marker, new_method, "ads_service.dart gating method")
save(ADS, a)
print("[ads_service.dart] patched.")

s = load(STRINGS)
old_ar = "      'pleaseSelect': 'حدد الصور والشعار أولاً',\n"
new_ar = (
    "      'pleaseSelect': 'حدد الصور والشعار أولاً',\n"
    "      'adUnavailable': 'الإعلان غير متاح حالياً، حاول لاحقاً',\n"
)
s = patch_one(s, old_ar, new_ar, "app_strings.dart ar key")

old_en = "      'pleaseSelect': 'Please select images and a logo first',\n"
new_en = (
    "      'pleaseSelect': 'Please select images and a logo first',\n"
    "      'adUnavailable': 'Ad not available right now, please try again later',\n"
)
s = patch_one(s, old_en, new_en, "app_strings.dart en key")
save(STRINGS, s)
print("[app_strings.dart] patched.")

h = load(HOME)

old_button = "onPressed:\n                                        _isProcessing ? null : _processImages,"
new_button = "onPressed:\n                                        _isProcessing ? null : _onSavePressed,"
h = patch_one(h, old_button, new_button, "save button onPressed")

old_marker2 = "  Future<void> _processImages() async {"
new_method2 = '''  void _onSavePressed() {
    AdsService.showInterstitialThen(
      onReady: _processImages,
      onUnavailable: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.get(context, 'adUnavailable'))),
        );
      },
    );
  }

  Future<void> _processImages() async {'''
h = patch_one(h, old_marker2, new_method2, "home_screen.dart _onSavePressed method")

save(HOME, h)
print("[home_screen.dart] patched.")

print("\nAll patches applied successfully.")
print("\nNow run:")
print(f"  dart format {ADS} {STRINGS} {HOME}")
print(f"  flutter analyze {ADS} {STRINGS} {HOME}")
