import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;

class AdService {
  // Remote Config State
  static bool adsEnabled = false; // Fallback to false
  static bool bannerEnabled = false;
  static bool interstitialEnabled = false;
  static bool appOpenEnabled = false;
  static int clickCountInterval = 3;
  static int _currentClickCount = 0;

  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialLoading = false;
  
  static final AppOpenAdManager appOpenAdManager = AppOpenAdManager();

  static String bannerIdAndroid = 'ca-app-pub-8708457885343434/3322994452';
  static String appOpenIdAndroid = 'ca-app-pub-8708457885343434/2009912786';
  static String interstitialIdAndroid = 'ca-app-pub-8708457885343434/7603694829';

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return bannerIdAndroid;
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // Test Banner Ad ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get appOpenAdUnitId {
    if (Platform.isAndroid) {
      return appOpenIdAndroid;
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/5575463023'; // Test App Open Ad ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return interstitialIdAndroid;
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Test Interstitial Ad ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  static Future<void> init() async {
    await MobileAds.instance.initialize();
  }

  /// Fetch Ads Configuration from GitHub JSON
  static Future<void> fetchRemoteConfig() async {
    try {
      // Use GitHub API for instant updates (bypasses the 5-minute CDN cache)
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/ashishsonani/whater-reminder/contents/config.json'),
        headers: {
          'Accept': 'application/vnd.github.v3.raw',
          'Cache-Control': 'no-cache',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Remote Ads Config raw JSON: ${response.body}');
        adsEnabled = data['ads_enabled'] ?? false;
        bannerEnabled = data['banner'] ?? false;
        interstitialEnabled = data['interstitial'] ?? false;
        appOpenEnabled = data['app_open'] ?? false;
        clickCountInterval = data['click_count'] ?? 3;
        
        bannerIdAndroid = data['banner_id_android'] ?? bannerIdAndroid;
        appOpenIdAndroid = data['app_open_id_android'] ?? appOpenIdAndroid;
        interstitialIdAndroid = data['interstitial_id_android'] ?? interstitialIdAndroid;
        
        debugPrint('Remote Ads Config loaded: adsEnabled=$adsEnabled, banner=$bannerEnabled, interstitial=$interstitialEnabled, appOpen=$appOpenEnabled, clickCount=$clickCountInterval');

        // Preload interstitial if enabled
        if (adsEnabled && interstitialEnabled) {
          loadInterstitialAd();
        }
        
        // Preload App Open Ad if enabled
        if (adsEnabled && appOpenEnabled) {
          appOpenAdManager.loadAd();
        }
      } else {
        debugPrint('Failed to load remote config, status code: ${response.statusCode}');
        _setFallbackConfig();
      }
    } catch (e) {
      debugPrint('Error fetching remote config: $e');
      _setFallbackConfig();
    }
  }

  static void _setFallbackConfig() {
    adsEnabled = false;
    bannerEnabled = false;
    interstitialEnabled = false;
    appOpenEnabled = false;
  }

  /// Load Interstitial Ad
  static void loadInterstitialAd() {
    if (!adsEnabled || !interstitialEnabled || _isInterstitialLoading || _interstitialAd != null) {
      return;
    }
    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _isInterstitialLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Called on user actions to show Interstitial Ad if click count reached
  static void showInterstitialAdIfReached() {
    if (!adsEnabled || !interstitialEnabled) return;

    _currentClickCount++;
    debugPrint('Ad click count: $_currentClickCount / $clickCountInterval');

    if (_currentClickCount >= clickCountInterval) {
      _currentClickCount = 0; // Reset counter
      if (_interstitialAd != null) {
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _interstitialAd = null;
            loadInterstitialAd(); // Reload for next time
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _interstitialAd = null;
            loadInterstitialAd();
          },
        );
        _interstitialAd!.show();
      } else {
        // If not loaded yet, try loading it for next time
        loadInterstitialAd();
      }
    }
  }
}

/// App Open Ad Manager
class AppOpenAdManager {
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  DateTime? _appOpenLoadTime;

  /// Load an AppOpenAd.
  void loadAd() {
    if (!AdService.adsEnabled || !AdService.appOpenEnabled) return;

    AppOpenAd.load(
      adUnitId: AdService.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenLoadTime = DateTime.now();
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('AppOpenAd failed to load: $error');
        },
      ),
    );
  }

  /// Whether an ad is available to be shown.
  bool get isAdAvailable {
    return _appOpenAd != null;
  }

  /// Shows the ad, if one exists and is not already being shown.
  void showAdIfAvailable() {
    if (!AdService.adsEnabled || !AdService.appOpenEnabled) return;

    if (!isAdAvailable) {
      loadAd();
      return;
    }
    if (_isShowingAd) {
      return;
    }
    if (DateTime.now().subtract(const Duration(hours: 4)).isAfter(_appOpenLoadTime!)) {
      _appOpenAd!.dispose();
      _appOpenAd = null;
      loadAd();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
    );
    _appOpenAd!.show();
  }
}

/// AppLifecycleReactor to show App Open Ads on app resume.
class AppLifecycleReactor extends WidgetsBindingObserver {
  final AppOpenAdManager appOpenAdManager;

  AppLifecycleReactor({required this.appOpenAdManager});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      appOpenAdManager.showAdIfAvailable();
    }
  }
}

/// Common Banner Ad Widget
class CommonBannerAd extends StatefulWidget {
  const CommonBannerAd({super.key});

  @override
  State<CommonBannerAd> createState() => _CommonBannerAdState();
}

class _CommonBannerAdState extends State<CommonBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    if (AdService.adsEnabled && AdService.bannerEnabled) {
      _loadAd();
    }
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
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
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isLoaded = false;
            });
          }
          debugPrint('Banner Ad failed to load: $error');
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
    if (!AdService.adsEnabled || !AdService.bannerEnabled || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
