import 'package:flutter/material.dart';
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
