import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_intake/theme/rewarded_theme.dart';
import 'package:water_intake/services/iap_service.dart';

class AdService {
  // Remote Config State
  static bool adsEnabled = false; // Fallback to false
  static bool bannerEnabled = false;
  static bool interstitialEnabled = false;
  static bool appOpenEnabled = false;
  static bool rewardedEnabled = true;
  static InterstitialAd? _interstitialAd;
  static DateTime? _interstitialLoadedAt;
  static DateTime? _lastFailedInterstitialRequest;
  static bool _isInterstitialLoading = false;
  static bool _isInterstitialShowing = false;
  static bool _isRewardedInProgress = false;
  static String? _rewardedIdAndroid;
  static String? _rewardedIdIos;
  static final _placementRevision = ValueNotifier<int>(0);
  static ValueListenable<int> get placementRevision => _placementRevision;
  static final privacyOptionsRequired = ValueNotifier<bool>(false);
  static const _lastInterstitialImpressionKey = 'lastMilestoneAdImpression';
  static Duration interstitialCooldown = Duration.zero;
  static const _waterLogCountKey = 'waterLogsSinceAdOpportunity';
  static int waterLogsPerAdOpportunity = 5;

  static String bannerIdAndroid = '';
  static String interstitialIdAndroid = '';
  static String appOpenIdAndroid = '';
  static String bannerIdIos = '';
  static String interstitialIdIos = '';
  static String appOpenIdIos = '';

  static String get bannerAdUnitId =>
      Platform.isAndroid ? bannerIdAndroid : bannerIdIos;

  static String get interstitialAdUnitId =>
      Platform.isAndroid ? interstitialIdAndroid : interstitialIdIos;

  static String get appOpenAdUnitId =>
      Platform.isAndroid ? appOpenIdAndroid : appOpenIdIos;

  static final appOpenAdManager = AppOpenAdManager();

  static bool _observesPremium = false;
  static bool _consentAllowsAds = false;
  static bool _mobileAdsInitialized = false;
  static bool _isInitializingMobileAds = false;
  static bool _privacyFormOpen = false;
  static bool get _canLoadAds =>
      _consentAllowsAds &&
      _mobileAdsInitialized &&
      !_privacyFormOpen &&
      !IAPService.instance.isPremium &&
      adsEnabled;
  static bool get canLoadBanner =>
      _canLoadAds && bannerEnabled && bannerAdUnitId.isNotEmpty;
  static bool get canLoadAppOpen =>
      _canLoadAds && appOpenEnabled && appOpenAdUnitId.isNotEmpty;

  static String? get _rewardedAdUnitId =>
      Platform.isAndroid ? _rewardedIdAndroid : _rewardedIdIos;

  static bool get canOfferThemeReward =>
      _canLoadAds &&
      rewardedEnabled &&
      _rewardedAdUnitId != null &&
      _rewardedAdUnitId!.isNotEmpty;

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
          request: const AdRequest(nonPersonalizedAds: true),
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
    if (!_observesPremium) {
      _observesPremium = true;
      IAPService.instance.premiumAccess.addListener(_refreshPlacements);
    }
    if (IAPService.instance.isPremium) return;
    final debugSettings = ConsentDebugSettings(
      testIdentifiers: const ['5F1801239EDBFBDAC66414D585F378C9'],
    );
    final consent = ConsentInformation.instance;
    final updated = Completer<bool>();
    try {
      consent.requestConsentInfoUpdate(
        ConsentRequestParameters(consentDebugSettings: debugSettings),
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
    await _refreshConsent();
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

  static Future<void> _refreshConsent() async {
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
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: const [
            '5F1801239EDBFBDAC66414D585F378C9', // Samsung SM-G973U test device
          ],
        ),
      );
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
    _lastFailedInterstitialRequest = null;
    _placementRevision.value++;
    _loadInterstitial();
    if (canLoadAppOpen) {
      appOpenAdManager.loadAd();
    }
  }

  static const String _configCacheKey = 'cached_ads_config_json';
  static const String _remoteConfigUrlApi =
      'https://api.github.com/repos/ashishsonani/whater-reminder/contents/config.json';
  static const String _remoteConfigUrlRaw =
      'https://raw.githubusercontent.com/ashishsonani/whater-reminder/main/config.json';

  static Future<void> fetchRemoteConfig() async {
    final cached = await _loadCachedConfig();
    if (cached != null) {
      _applyConfig(cached);
    } else {
      try {
        final local = await rootBundle.loadString('config.json');
        final decoded = json.decode(local) as Map<String, dynamic>;
        _applyConfig(decoded);
      } catch (_) {}
    }

    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    final String? body =
        await _fetchConfigBody(
          _remoteConfigUrlApi,
          headers: {
            'Accept': 'application/vnd.github.v3.raw',
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          },
        ) ??
        await _fetchConfigBody(
          '$_remoteConfigUrlRaw?t=$cacheBuster',
          headers: {
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          },
        );

    if (body == null) return;
    try {
      final decoded = json.decode(body) as Map<String, dynamic>;
      _applyConfig(decoded);
      unawaited(_cacheConfig(body));
      debugPrint('Remote ad config applied from GitHub: $decoded');
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

  static (bool, bool, bool, bool, bool, int, int, String, String, String, String?) get _activeConfig => (
    adsEnabled,
    bannerEnabled,
    interstitialEnabled,
    appOpenEnabled,
    rewardedEnabled,
    waterLogsPerAdOpportunity,
    interstitialCooldown.inMinutes,
    bannerAdUnitId,
    interstitialAdUnitId,
    appOpenAdUnitId,
    _rewardedAdUnitId,
  );

  static void _applyConfig(Map<String, dynamic> data) {
    final previous = _activeConfig;
    if (data.containsKey('ads_enabled')) {
      adsEnabled = data['ads_enabled'] == true;
    }
    if (data.containsKey('banner')) {
      bannerEnabled = data['banner'] == true;
    }
    if (data.containsKey('interstitial')) {
      interstitialEnabled = data['interstitial'] == true;
    }
    if (data.containsKey('app_open')) {
      appOpenEnabled = data['app_open'] == true;
    }
    if (data.containsKey('rewarded')) {
      rewardedEnabled = data['rewarded'] != false;
    }

    final interval = data['interstitial_interval'] ?? data['click_count'];
    if (interval is int && interval > 0) {
      waterLogsPerAdOpportunity = interval;
    } else if (interval is String && int.tryParse(interval) != null) {
      waterLogsPerAdOpportunity = int.parse(interval);
    }

    final cooldownMin = data['interstitial_cooldown_minutes'];
    if (cooldownMin is int && cooldownMin >= 0) {
      interstitialCooldown = Duration(minutes: cooldownMin);
    } else if (cooldownMin is String && int.tryParse(cooldownMin) != null) {
      interstitialCooldown = Duration(minutes: int.parse(cooldownMin));
    }

    if (data['banner_id_android'] != null) {
      bannerIdAndroid = _readUnitId(data['banner_id_android']);
    }
    if (data['interstitial_id_android'] != null) {
      interstitialIdAndroid = _readUnitId(data['interstitial_id_android']);
    }
    if (data['app_open_id_android'] != null) {
      appOpenIdAndroid = _readUnitId(data['app_open_id_android']);
    }
    if (data['banner_id_ios'] != null) {
      bannerIdIos = _readUnitId(data['banner_id_ios']);
    }
    if (data['interstitial_id_ios'] != null) {
      interstitialIdIos = _readUnitId(data['interstitial_id_ios']);
    }
    if (data['app_open_id_ios'] != null) {
      appOpenIdIos = _readUnitId(data['app_open_id_ios']);
    }

    final androidReward = data['rewarded_id_android'];
    if (androidReward != null) {
      _rewardedIdAndroid = androidReward is String && androidReward.trim().isNotEmpty
          ? androidReward.trim()
          : null;
    }
    final iosReward = data['rewarded_id_ios'];
    if (iosReward != null) {
      _rewardedIdIos = iosReward is String && iosReward.trim().isNotEmpty
          ? iosReward.trim()
          : null;
    }

    if (_activeConfig != previous) _refreshPlacements();
  }

  static String _readUnitId(Object? value) =>
      value is String ? value.trim() : '';

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
        interstitialAdUnitId.isEmpty ||
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
    final lastFailed = _lastFailedInterstitialRequest;
    if (lastFailed != null &&
        now.difference(lastFailed) < const Duration(seconds: 15)) {
      return;
    }
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialLoading = true;
    final revision = _placementRevision.value;
    unawaited(
      InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(nonPersonalizedAds: true),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _isInterstitialLoading = false;
            _lastFailedInterstitialRequest = null;
            if (revision != _placementRevision.value) {
              ad.dispose();
              _loadInterstitial();
              return;
            }
            _interstitialAd = ad;
            _interstitialLoadedAt = DateTime.now();
            debugPrint('Interstitial loaded successfully');
          },
          onAdFailedToLoad: (error) {
            _isInterstitialLoading = false;
            _lastFailedInterstitialRequest = DateTime.now();
            if (revision != _placementRevision.value) _loadInterstitial();
            debugPrint('Interstitial failed to load: $error');
          },
        ),
      ).catchError((Object error) {
        _isInterstitialLoading = false;
        _lastFailedInterstitialRequest = DateTime.now();
        debugPrint('Interstitial request failed: $error');
      }),
    );
  }

  static Future<void> onWaterLogged({required bool completedGoal}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = (prefs.getInt(_waterLogCountKey) ?? 0) + 1;
      final reachedInterval = count >= waterLogsPerAdOpportunity;
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
        _isRewardedInProgress ||
        appOpenAdManager.isShowingAd) {
      return;
    }
    _isInterstitialShowing = true;
    bool handedToSdk = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final previous = prefs.getInt(_lastInterstitialImpressionKey);
      if (interstitialCooldown > Duration.zero && previous != null) {
        final elapsed = now.difference(DateTime.fromMillisecondsSinceEpoch(previous));
        if (elapsed < interstitialCooldown) {
          debugPrint('Interstitial suppressed by cooldown: remaining ${interstitialCooldown - elapsed}');
          return;
        }
      }

      // If ad is not ready yet, load on-demand and wait briefly
      if (_interstitialAd == null ||
          (_interstitialLoadedAt != null &&
              now.difference(_interstitialLoadedAt!) >= const Duration(hours: 1))) {
        _interstitialAd?.dispose();
        _interstitialAd = null;
        _lastFailedInterstitialRequest = null;
        _loadInterstitial();

        final waitStart = DateTime.now();
        while (_isInterstitialLoading && _interstitialAd == null) {
          await Future.delayed(const Duration(milliseconds: 100));
          if (DateTime.now().difference(waitStart) > const Duration(seconds: 4)) {
            break;
          }
        }
      }

      final ad = _interstitialAd;
      if (ad == null) {
        debugPrint('Interstitial ad not ready to show');
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
        appOpenAdManager.markAdDismissed();
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
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('Interstitial failed to show: $error');
          finish(ad);
        },
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
  DateTime? _lastConfigCheck;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AdService._loadInterstitial();
      if (AdService.canLoadAppOpen) {
        AdService.appOpenAdManager.showAdIfAvailable();
      }
      final now = DateTime.now();
      if (_lastConfigCheck == null ||
          now.difference(_lastConfigCheck!) > const Duration(minutes: 5)) {
        _lastConfigCheck = now;
        unawaited(AdService.fetchRemoteConfig());
      }
    }
  }
}

/// App Open Ad Manager
class AppOpenAdManager {
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  bool _isLoading = false;
  DateTime? _appOpenLoadTime;
  DateTime? _lastDismissedAt;
  Completer<bool>? _pendingLoad;

  bool get isShowingAd => _isShowingAd;

  void markAdDismissed() {
    _lastDismissedAt = DateTime.now();
  }

  bool get isAdAvailable =>
      _appOpenAd != null &&
      _appOpenLoadTime != null &&
      DateTime.now().difference(_appOpenLoadTime!) < const Duration(hours: 4);

  Future<bool> loadAd() async {
    if (!AdService.canLoadAppOpen || _isLoading) {
      if (_isLoading && _pendingLoad != null) {
        return _pendingLoad!.future;
      }
      return isAdAvailable;
    }

    if (isAdAvailable) return true;

    _isLoading = true;
    final completer = Completer<bool>();
    _pendingLoad = completer;

    try {
      await AppOpenAd.load(
        adUnitId: AdService.appOpenAdUnitId,
        request: const AdRequest(nonPersonalizedAds: true),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenLoadTime = DateTime.now();
            _appOpenAd = ad;
            _isLoading = false;
            if (!completer.isCompleted) completer.complete(true);
            debugPrint('AppOpenAd loaded successfully');
          },
          onAdFailedToLoad: (error) {
            _isLoading = false;
            _appOpenAd = null;
            if (!completer.isCompleted) completer.complete(false);
            debugPrint('AppOpenAd failed to load: $error');
          },
        ),
      );
    } catch (e) {
      _isLoading = false;
      if (!completer.isCompleted) completer.complete(false);
      debugPrint('AppOpenAd load error: $e');
    }

    return completer.future;
  }

  Future<void> showAdIfAvailable({Duration? timeout}) async {
    if (!AdService.canLoadAppOpen) return;
    if (_isShowingAd ||
        AdService._isInterstitialShowing ||
        AdService._isRewardedInProgress) {
      return;
    }

    final now = DateTime.now();
    if (_lastDismissedAt != null &&
        now.difference(_lastDismissedAt!) < const Duration(seconds: 15)) {
      return;
    }

    if (!isAdAvailable) {
      if (timeout != null && timeout > Duration.zero) {
        final loaded = await loadAd().timeout(timeout, onTimeout: () => false);
        if (!loaded || !isAdAvailable) return;
      } else {
        unawaited(loadAd());
        return;
      }
    }

    if (_isShowingAd ||
        AdService._isInterstitialShowing ||
        AdService._isRewardedInProgress) {
      return;
    }

    final ad = _appOpenAd;
    if (ad == null) return;

    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        _lastDismissedAt = DateTime.now();
        ad.dispose();
        _appOpenAd = null;
        if (!completer.isCompleted) completer.complete();
        loadAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        _lastDismissedAt = DateTime.now();
        ad.dispose();
        _appOpenAd = null;
        if (!completer.isCompleted) completer.complete();
        loadAd();
      },
    );

    try {
      _appOpenAd = null; // Hand over reference
      await ad.show();
      await completer.future;
    } catch (e) {
      _isShowingAd = false;
      _lastDismissedAt = DateTime.now();
      ad.dispose();
      _appOpenAd = null;
      loadAd();
    }
  }

  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
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
        request: const AdRequest(nonPersonalizedAds: true),
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
