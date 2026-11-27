import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_intake/theme/rewarded_theme.dart';

class AdService {
  // Remote Config State
  static bool adsEnabled = false; // Fallback to false
  static bool bannerEnabled = false;
  static bool interstitialEnabled = false;
  static InterstitialAd? _interstitialAd;
  static DateTime? _interstitialLoadedAt;
  static DateTime? _lastInterstitialRequest;
  static bool _isInterstitialLoading = false;
  static bool _isInterstitialShowing = false;
  static bool _isRewardedInProgress = false;
  static String? _rewardedIdAndroid;
  static String? _rewardedIdIos;
  static final _placementRevision = ValueNotifier<int>(0);
  static ValueListenable<int> get placementRevision => _placementRevision;
  static final privacyOptionsRequired = ValueNotifier<bool>(false);
  static const _lastInterstitialImpressionKey = 'lastMilestoneAdImpression';
  static const _interstitialCooldown = Duration(hours: 3);
  static const _waterLogCountKey = 'waterLogsSinceAdOpportunity';
  static const _waterLogsPerAdOpportunity = 5;

  static String bannerIdAndroid = 'ca-app-pub-8708457885343434/2858546284';
  static String interstitialIdAndroid =
      'ca-app-pub-8708457885343434/6940014680';

  static String bannerIdIos = 'ca-app-pub-8708457885343434/3980056269';
  static String interstitialIdIos = 'ca-app-pub-8708457885343434/1663637270';

  static String get bannerAdUnitId => !kReleaseMode
      ? (Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/9214589741'
            : 'ca-app-pub-3940256099942544/2435281174')
      : (Platform.isAndroid ? bannerIdAndroid : bannerIdIos);

  static String get interstitialAdUnitId => !kReleaseMode
      ? (Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/1033173712'
            : 'ca-app-pub-3940256099942544/4411468910')
      : (Platform.isAndroid ? interstitialIdAndroid : interstitialIdIos);

  static bool _consentAllowsAds = false;
  static bool _mobileAdsInitialized = false;
  static bool _isInitializingMobileAds = false;
  static bool _privacyFormOpen = false;
  static bool get _canLoadAds =>
      _consentAllowsAds &&
      _mobileAdsInitialized &&
      !_privacyFormOpen &&
      adsEnabled;
  static bool get canLoadBanner => _canLoadAds && bannerEnabled;

  static String? get _rewardedAdUnitId => kReleaseMode
      ? (Platform.isAndroid ? _rewardedIdAndroid : _rewardedIdIos)
      : (Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/5224354917'
            : 'ca-app-pub-3940256099942544/1712485313');

  static bool get canOfferThemeReward =>
      _canLoadAds && _rewardedAdUnitId != null;

  static Future<bool> watchThemeReward({
    required bool Function() canPresent,
  }) async {
    final adUnitId = _rewardedAdUnitId;
    if (!canOfferThemeReward ||
        adUnitId == null ||
        _isRewardedInProgress ||
        _isInterstitialShowing) {
      return false;
    }

    _isRewardedInProgress = true;
    RewardedAd? loadedAd;
    try {
      final revision = _placementRevision.value;
      final pending = Completer<RewardedAd?>();
      unawaited(
        RewardedAd.load(
          adUnitId: adUnitId,
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              if (pending.isCompleted) {
                ad.dispose();
              } else {
                pending.complete(ad);
              }
            },
            onAdFailedToLoad: (error) {
              debugPrint('Rewarded ad failed to load: $error');
              if (!pending.isCompleted) pending.complete(null);
            },
          ),
        ).catchError((Object error) {
          debugPrint('Rewarded ad request failed: $error');
          if (!pending.isCompleted) pending.complete(null);
        }),
      );
      final timeout = Timer(const Duration(seconds: 12), () {
        if (!pending.isCompleted) pending.complete(null);
      });
      final ad = await pending.future;
      timeout.cancel();
      loadedAd = ad;
      if (ad == null ||
          revision != _placementRevision.value ||
          !canOfferThemeReward ||
          !canPresent() ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return false;
      }

      final closed = Completer<bool>();
      Future<void>? reward;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (_) => closed.complete(true),
        onAdFailedToShowFullScreenContent: (_, error) {
          debugPrint('Rewarded ad failed to show: $error');
          closed.complete(false);
        },
      );
      await ad.show(
        onUserEarnedReward: (_, _) {
          reward ??= ThemeReward.instance.grant().catchError((Object error) {
            debugPrint('Could not save rewarded theme: $error');
          });
        },
      );
      final presented = await closed.future;
      await reward;
      return presented;
    } catch (error) {
      debugPrint('Rewarded ad failed: $error');
      return false;
    } finally {
      loadedAd?.dispose();
      _isRewardedInProgress = false;
    }
  }

  static Future<void> gatherConsentAndInit() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    final consent = ConsentInformation.instance;
    final updated = Completer<bool>();
    try {
      consent.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () => updated.complete(true),
        (error) {
          debugPrint('UMP consent update failed: ${error.message}');
          updated.complete(false);
        },
      );
      if (await updated.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () => false,
      )) {
        await ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (error != null) {
            debugPrint('UMP consent form failed: ${error.message}');
          }
        });
      }
    } catch (error) {
      debugPrint('Error gathering ad consent: $error');
    }
    await _refreshConsent(requestTracking: true);
  }

  static Future<void> showPrivacyOptions() async {
    if (_privacyFormOpen || !privacyOptionsRequired.value) return;
    _privacyFormOpen = true;
    _refreshPlacements();
    try {
      await ConsentForm.showPrivacyOptionsForm((error) {
        if (error != null) {
          debugPrint('Ad privacy options failed: ${error.message}');
        }
      });
    } catch (error) {
      debugPrint('Error opening ad privacy options: $error');
    } finally {
      _privacyFormOpen = false;
      await _refreshConsent();
    }
  }

  static Future<void> _refreshConsent({bool requestTracking = false}) async {
    final consent = ConsentInformation.instance;
    try {
      privacyOptionsRequired.value =
          await consent.getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } catch (error) {
      debugPrint('Error reading ad privacy status: $error');
    }
    try {
      _consentAllowsAds = await consent.canRequestAds();
      if (_consentAllowsAds && !_mobileAdsInitialized) {
        if (requestTracking && Platform.isIOS) {
          try {
            if (await AppTrackingTransparency.trackingAuthorizationStatus ==
                TrackingStatus.notDetermined) {
              await AppTrackingTransparency.requestTrackingAuthorization();
            }
          } catch (error) {
            debugPrint('ATT request failed: $error');
          }
        }
        unawaited(_initializeMobileAds());
      }
    } catch (error) {
      _consentAllowsAds = false;
      debugPrint('Error checking ad consent: $error');
    } finally {
      _refreshPlacements();
    }
  }

  static Future<void> _initializeMobileAds() async {
    if (_isInitializingMobileAds || _mobileAdsInitialized) return;
    _isInitializingMobileAds = true;
    try {
      await MobileAds.instance.initialize();
      _mobileAdsInitialized = true;
      WidgetsBinding.instance.addObserver(_InterstitialPreloader());
      _refreshPlacements();
    } catch (error) {
      debugPrint('Mobile Ads SDK initialization failed: $error');
    } finally {
      _isInitializingMobileAds = false;
    }
  }

  static void _refreshPlacements() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _lastInterstitialRequest = null;
    _placementRevision.value++;
    _loadInterstitial();
  }

  static const String _configCacheKey = 'cached_ads_config_json';

  static Future<void> fetchRemoteConfig() async {
    final cached = await _loadCachedConfig();
    if (cached != null) _applyConfig(cached);

    final String? body =
        await _fetchConfigBody(
          'https://api.github.com/repos/ashishsonani/whater-reminder/contents/config.json',
          headers: {
            'Accept': 'application/vnd.github.v3.raw',
            'Cache-Control': 'no-cache',
          },
        ) ??
        await _fetchConfigBody(
          'https://raw.githubusercontent.com/ashishsonani/whater-reminder/main/config.json',
        );

    if (body == null) return;
    try {
      _applyConfig(json.decode(body) as Map<String, dynamic>);
      unawaited(_cacheConfig(body));
    } catch (error) {
      debugPrint('Remote ad config is invalid: $error');
    }
  }

  static Future<String?> _fetchConfigBody(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) return response.body;
      debugPrint('Config fetch $url failed, status: ${response.statusCode}');
    } catch (e) {
      debugPrint('Config fetch $url error: $e');
    }
    return null;
  }

  static (bool, bool, bool, String, String, String?) get _activeConfig => (
    adsEnabled,
    bannerEnabled,
    interstitialEnabled,
    bannerAdUnitId,
    interstitialAdUnitId,
    _rewardedAdUnitId,
  );

  static void _applyConfig(Map<String, dynamic> data) {
    final previous = _activeConfig;
    adsEnabled = data['ads_enabled'] == true;
    bannerEnabled = data['banner'] == true;
    interstitialEnabled = data['interstitial'] == true;

    bannerIdAndroid = _readUnitId(data['banner_id_android'], bannerIdAndroid);
    interstitialIdAndroid = _readUnitId(
      data['interstitial_id_android'],
      interstitialIdAndroid,
    );
    bannerIdIos = _readUnitId(data['banner_id_ios'], bannerIdIos);
    interstitialIdIos = _readUnitId(
      data['interstitial_id_ios'],
      interstitialIdIos,
    );

    final androidReward = data['rewarded_id_android'];
    _rewardedIdAndroid = androidReward is String && androidReward.isNotEmpty
        ? androidReward
        : null;
    final iosReward = data['rewarded_id_ios'];
    _rewardedIdIos = iosReward is String && iosReward.isNotEmpty
        ? iosReward
        : null;

    if (_activeConfig != previous) _refreshPlacements();
  }

  static String _readUnitId(Object? value, String fallback) =>
      value is String && value.isNotEmpty ? value : fallback;

  static Future<void> _cacheConfig(String body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_configCacheKey, body);
    } catch (e) {
      debugPrint('Failed to cache ads config: $e');
    }
  }

  static Future<Map<String, dynamic>?> _loadCachedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final body = prefs.getString(_configCacheKey);
      if (body != null) return json.decode(body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Failed to read cached ads config: $e');
    }
    return null;
  }

  static void _loadInterstitial() {
    if (!_canLoadAds ||
        !interstitialEnabled ||
        _isInterstitialLoading ||
        _isInterstitialShowing) {
      return;
    }

    final now = DateTime.now();
    final loadedAt = _interstitialLoadedAt;
    if (_interstitialAd != null &&
        loadedAt != null &&
        now.difference(loadedAt) < const Duration(hours: 1)) {
      return;
    }
    final lastRequest = _lastInterstitialRequest;
    if (lastRequest != null &&
        now.difference(lastRequest) < const Duration(minutes: 1)) {
      return;
    }
    _lastInterstitialRequest = now;
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialLoading = true;
    final revision = _placementRevision.value;
    unawaited(
      InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _isInterstitialLoading = false;
            if (revision != _placementRevision.value) {
              ad.dispose();
              _loadInterstitial();
              return;
            }
            _interstitialAd = ad;
            _interstitialLoadedAt = DateTime.now();
          },
          onAdFailedToLoad: (error) {
            _isInterstitialLoading = false;
            if (revision != _placementRevision.value) _loadInterstitial();
            debugPrint('Interstitial failed to load: $error');
          },
        ),
      ).catchError((Object error) {
        _isInterstitialLoading = false;
        debugPrint('Interstitial request failed: $error');
      }),
    );
  }

  static Future<void> onWaterLogged({required bool completedGoal}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = (prefs.getInt(_waterLogCountKey) ?? 0) + 1;
      final reachedInterval = count >= _waterLogsPerAdOpportunity;
      final saved = await prefs.setInt(
        _waterLogCountKey,
        reachedInterval ? 0 : count,
      );
      // On a goal-completing log, use the celebration's existing ad opportunity.
      if (saved && reachedInterval && !completedGoal) {
        await showInterstitialAtBreak();
      }
    } catch (error) {
      debugPrint('Could not update the water-log ad counter: $error');
    }
  }

  static Future<void> showInterstitialAtBreak() async {
    if (!_canLoadAds ||
        !interstitialEnabled ||
        _isInterstitialShowing ||
        _isRewardedInProgress) {
      return;
    }
    _isInterstitialShowing = true;
    bool handedToSdk = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final previous = prefs.getInt(_lastInterstitialImpressionKey);
      if (previous != null &&
          now.difference(DateTime.fromMillisecondsSinceEpoch(previous)) <
              _interstitialCooldown) {
        return;
      }

      final ad = _interstitialAd;
      if (ad == null ||
          now.difference(_interstitialLoadedAt!) >= const Duration(hours: 1)) {
        ad?.dispose();
        _interstitialAd = null;
        return;
      }
      if (!_canLoadAds ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return;
      }
      _interstitialAd = null;

      void finish(InterstitialAd ad) {
        ad.dispose();
        _isInterstitialShowing = false;
        _loadInterstitial();
      }

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (_) {
          unawaited(
            prefs.setInt(
              _lastInterstitialImpressionKey,
              DateTime.now().millisecondsSinceEpoch,
            ),
          );
        },
        onAdDismissedFullScreenContent: finish,
        onAdFailedToShowFullScreenContent: (ad, _) => finish(ad),
      );
      try {
        await ad.show();
        handedToSdk = true;
      } catch (error) {
        ad.dispose();
        rethrow;
      }
    } catch (error) {
      debugPrint('Interstitial failed to show: $error');
    } finally {
      if (!handedToSdk) {
        _isInterstitialShowing = false;
        _loadInterstitial();
      }
    }
  }
}

class _InterstitialPreloader with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) AdService._loadInterstitial();
  }
}

class DashboardBannerAd extends StatelessWidget {
  const DashboardBannerAd({super.key});

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.orientationOf(context);
    return ValueListenableBuilder<int>(
      valueListenable: AdService.placementRevision,
      builder: (context, revision, _) {
        if (!AdService.canLoadBanner) return const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.floor();
            if (width < 200) return const SizedBox.shrink();
            return _AdaptiveBanner(
              key: ValueKey((revision, orientation, width)),
              width: width,
            );
          },
        );
      },
    );
  }
}

class _AdaptiveBanner extends StatefulWidget {
  const _AdaptiveBanner({super.key, required this.width});

  final int width;

  @override
  State<_AdaptiveBanner> createState() => _AdaptiveBannerState();
}

class _AdaptiveBannerState extends State<_AdaptiveBanner> {
  BannerAd? _bannerAd;
  Timer? _retry;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!AdService.canLoadBanner) return;
    final revision = AdService.placementRevision.value;
    try {
      final size =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            widget.width,
          );
      if (!mounted ||
          revision != AdService.placementRevision.value ||
          !AdService.canLoadBanner) {
        return;
      }
      if (size == null || size.width > widget.width) return;
      final ad = BannerAd(
        adUnitId: AdService.bannerAdUnitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (mounted) setState(() => _loaded = true);
          },
          onAdFailedToLoad: (failedAd, error) {
            if (!mounted || _bannerAd != failedAd) return;
            debugPrint('Banner failed to load: $error');
            _retryLoad();
          },
        ),
      );
      _bannerAd = ad;
      await ad.load();
    } catch (error) {
      debugPrint('Banner request failed: $error');
      if (mounted) _retryLoad();
    }
  }

  void _retryLoad() {
    final failed = _bannerAd;
    setState(() {
      _loaded = false;
      _bannerAd = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => failed?.dispose());
    _retry?.cancel();
    _retry = Timer(const Duration(minutes: 1), _load);
  }

  @override
  void dispose() {
    _retry?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        heightFactor: 1,
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
