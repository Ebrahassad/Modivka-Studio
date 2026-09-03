import 'package:flutter/material.dart';
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
