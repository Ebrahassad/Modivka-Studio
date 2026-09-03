import os

# 1. إنشاء/تحديث ودجت إعلان البانر لـ Unity Ads
banner_widget_code = '''import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class SmartUnityBannerAd extends StatelessWidget {
  final String placementId;
  const SmartUnityBannerAd({super.key, required this.placementId});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      height: 50,
      child: UnityBannerAd(
        placementId: placementId,
        onLoad: (placementId) {},
        onFailed: (placementId, error, message) {},
        onClick: (placementId) {},
      ),
    );
  }
}
'''

# 2. إنشاء/تحديث منطق زر الحفظ وتنبيه عدم توفر الإعلان
save_helper_code = '''import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class SaveWithUnityAdManager {
  static void handleSavePressed({
    required BuildContext context,
    required String placementId,
    required VoidCallback onSaveSuccess,
    String? customNoAdMessage,
  }) {
    UnityAds.showVideoAd(
      placementId: placementId,
      onComplete: (placementId) {
        onSaveSuccess();
      },
      onFailed: (placementId, error, message) {
        _showNoAdSnackBar(context, customNoAdMessage);
      },
      onSkipped: (placementId) {
        _showNoAdSnackBar(context, customNoAdMessage);
      },
    );
  }

  static void _showNoAdSnackBar(BuildContext context, String? customMessage) {
    final String message = customMessage ??
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
  }
}
'''

# التأكد من المجلدات
os.makedirs('lib/widgets', exist_ok=True)
os.makedirs('lib/helpers', exist_ok=True)

# كتابة الملفات
with open('lib/widgets/smart_banner_ad_widget.dart', 'w', encoding='utf-8') as f:
    f.write(banner_widget_code)

with open('lib/helpers/save_with_ad_manager.dart', 'w', encoding='utf-8') as f:
    f.write(save_helper_code)

print("SUCCESS: Updated Unity Ads components successfully!")
