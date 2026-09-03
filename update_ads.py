import os

# 1. إنشاء/تحديث ملف أداة إعلان البانر (Banner Ad Widget)
banner_widget_code = '''import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SmartBannerAdWidget extends StatefulWidget {
  final String adUnitId;
  const SmartBannerAdWidget({Key? key, required this.adUnitId}) : super(key: key);

  @override
  State<SmartBannerAdWidget> createState() => _SmartBannerAdWidgetState();
}

class _SmartBannerAdWidgetState extends State<SmartBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: widget.adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
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
    if (_isLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox.shrink();
  }
}
'''

# 2. إنشاء/تحديث منطق الحفظ وعرض الرسالة والمكافأة (Save Helper)
save_helper_code = '''import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SaveWithAdManager {
  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;

  void loadRewardedAd(String adUnitId) {
    if (_isAdLoading) return;
    _isAdLoading = true;

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isAdLoading = false;
        },
      ),
    );
  }

  void handleSavePressed({
    required BuildContext context,
    required String adUnitId,
    required VoidCallback onSaveSuccess,
    String? customNoAdMessage,
  }) {
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          loadRewardedAd(adUnitId);
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedAd = null;
          loadRewardedAd(adUnitId);
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          onSaveSuccess();
        },
      );
    } else {
      // رسالة تنبيه مترجمة عند عدم توفر الإعلان
      final String message = customNoAdMessage ?? 
          (Localizations.localeOf(context).languageCode == 'ar'
              ? 'لا يوجد إعلان حالياً للاستمرار، يرجى المحاولة لاحقاً'
              : 'No ad available at the moment, please try again later.');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // إعادة محاولة تحميل الإعلان في الخلفية
      loadRewardedAd(adUnitId);
    }
  }
}
'''

os.makedirs('lib/widgets', exist_ok=True)
os.makedirs('lib/helpers', exist_ok=True)

with open('lib/widgets/smart_banner_ad_widget.dart', 'w', encoding='utf-8') as f:
    f.write(banner_widget_code)

with open('lib/helpers/save_with_ad_manager.dart', 'w', encoding='utf-8') as f:
    f.write(save_helper_code)

print("SUCCESS: Files created successfully!")
