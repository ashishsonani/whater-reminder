import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static String get nativeAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/2247696110'; // Test Native Ad ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-7847141632916232/1136010934'; // Test Native Ad ID
    }
    //live
    // if (Platform.isAndroid) {
    //   return 'ca-app-pub-7847141632916232/7256808564'; // Test Native Ad ID
    // } else if (Platform.isIOS) {
    //   return 'ca-app-pub-7847141632916232/1136010934'; // Test Native Ad ID
    // }
    throw UnsupportedError('Unsupported platform');
  }

  static Future<void> init() async {
    await MobileAds.instance.initialize();
  }
}

class CommonNativeAd extends StatefulWidget {
  const CommonNativeAd({super.key});

  @override
  State<CommonNativeAd> createState() => _CommonNativeAdState();
}

class _CommonNativeAdState extends State<CommonNativeAd> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    // if (!IAPService.to.isPremium.value) {
    _loadAd();
    // }
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: AdService.nativeAdUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _nativeAd = null;
              _isLoaded = false;
            });
          }
          debugPrint('Native Ad failed to load: $error');
        },
      ),
      request: const AdRequest(),
      // Using templateType is the modern way to avoid complex native setup for simple layouts
      nativeTemplateStyle: NativeTemplateStyle(templateType: TemplateType.small, mainBackgroundColor: Colors.white, cornerRadius: 10.0),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: 110.h,
      alignment: Alignment.center,
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
