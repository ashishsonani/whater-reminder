import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_service.dart';

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.months,
    required this.price,
    required this.hasSevenDayTrial,
    this.androidProduct,
  });

  final String id;
  final int months;
  final String price;
  final bool hasSevenDayTrial;
  final GooglePlayProductDetails? androidProduct;
}

enum BillingNotice {
  unavailable,
  pending,
  purchaseFailed,
  restored,
  noSubscription,
  verificationUnavailable,
}

class IAPService extends ChangeNotifier with WidgetsBindingObserver {
  IAPService._();
  static final instance = IAPService._();
  static const enabled = bool.fromEnvironment(
    'HYDRATION_PLUS_ENABLED',
    defaultValue: true,
  );
  static const _androidId = 'water_premium';
  static const _androidPlans = {
    'monthly': 1,
    'three-months': 3,
    'six-months': 6,
  };
  static const _expiryKey = 'verifiedHydrationPlusExpiry';
  static const _apple = MethodChannel('water_reminder/subscriptions');

  final premiumAccess = ValueNotifier<bool>(false);
  List<SubscriptionPlan> plans = const [];
  BillingNotice? notice;
  bool loading = false;
  bool busy = false;
  bool pending = false;
  bool _started = false;
  Future<void> _verificationQueue = Future.value();
  Timer? _expiryTimer;
  Timer? _purchaseTimeout;
  Timer? _refreshTimer;
  DateTime? _expiry;

  bool get isPremium => _expiry?.isAfter(DateTime.now()) ?? false;

  Future<void> init() async {
    if (!enabled || _started || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }
    _started = true;
    final prefs = await SharedPreferences.getInstance();
    _updateExpiry(prefs.getInt(_expiryKey) ?? 0);
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isAndroid) {
      InAppPurchase.instance.purchaseStream.listen(
        (purchases) =>
            unawaited(_serialize(() => _handlePlayUpdates(purchases))),
        onError: (Object _) => _finish(BillingNotice.purchaseFailed),
      );
    } else {
      _apple.setMethodCallHandler((call) async {
        if (call.method == 'entitlementChanged') await refreshEntitlement();
      });
    }
    _startRefreshTimer();
    unawaited(refreshEntitlement());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startRefreshTimer();
      unawaited(refreshEntitlement());
    } else if (state == AppLifecycleState.paused) {
      _refreshTimer?.cancel();
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      if (isPremium || pending) unawaited(refreshEntitlement());
    });
  }

  void _updateExpiry(int milliseconds) {
    _expiryTimer?.cancel();
    _expiry = milliseconds > 0
        ? DateTime.fromMillisecondsSinceEpoch(milliseconds)
        : null;
    final remaining = _expiry?.difference(DateTime.now());
    if (remaining != null && remaining > Duration.zero) {
      _expiryTimer = Timer(remaining, () {
        premiumAccess.value = false;
        notifyListeners();
        if (WidgetsBinding.instance.lifecycleState ==
            AppLifecycleState.resumed) {
          unawaited(refreshEntitlement());
        }
      });
    }
    premiumAccess.value = isPremium;
    notifyListeners();
  }

  Future<void> _saveExpiry(int milliseconds) async {
    _updateExpiry(milliseconds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_expiryKey, milliseconds);
  }

  Future<void> _serialize(Future<void> Function() operation) {
    final result = _verificationQueue.then((_) => operation());
    _verificationQueue = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<bool> _playReady() async {
    await FirebaseService().authenticate();
    final result = await FirebaseFunctions.instance
        .httpsCallable(
          'verifyHydrationSubscription',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
        )
        .call<Map<String, dynamic>>({'checkOnly': true});
    return result.data['ready'] == true;
  }

  Future<void> loadPlans() async {
    if (!enabled || loading) return;
    loading = true;
    notice = null;
    notifyListeners();
    try {
      final fetched = switch (Platform.operatingSystem) {
        'ios' => await _loadApplePlans(),
        'android' => await _loadPlayPlans(),
        _ => <SubscriptionPlan>[],
      };
      fetched.sort((a, b) => a.months.compareTo(b.months));
      plans = List.unmodifiable(fetched);
      if (plans.isEmpty) notice = BillingNotice.unavailable;
    } catch (_) {
      plans = const [];
      notice = BillingNotice.unavailable;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<List<SubscriptionPlan>> _loadApplePlans() async {
    final response =
        await _apple.invokeListMethod<Map<Object?, Object?>>('plans') ?? [];
    return [
      for (final product in response)
        SubscriptionPlan(
          id: product['id'] as String,
          months: product['months'] as int,
          price: product['price'] as String,
          hasSevenDayTrial: product['trial'] == true,
        ),
    ];
  }

  Future<List<SubscriptionPlan>> _loadPlayPlans() async {
    final billing = InAppPurchase.instance;
    if (!await billing.isAvailable() || !await _playReady()) return [];
    final response = await billing.queryProductDetails({_androidId});
    final plansByPeriod = <int, SubscriptionPlan>{};
    for (final product
        in response.productDetails.whereType<GooglePlayProductDetails>()) {
      final index = product.subscriptionIndex;
      final offers = product.productDetails.subscriptionOfferDetails;
      if (index == null || offers == null) continue;
      final offer = offers[index];
      final months = _androidPlans[offer.basePlanId];
      final phases = offer.pricingPhases;
      if (months == null ||
          phases.isEmpty ||
          offer.installmentPlanDetails != null) {
        continue;
      }
      final renewal = phases.last;
      if (renewal.billingPeriod != 'P${months}M' ||
          renewal.recurrenceMode != RecurrenceMode.infiniteRecurring ||
          renewal.priceAmountMicros <= 0) {
        continue;
      }
      final first = phases.first;
      final trial =
          phases.length == 2 &&
          first.priceAmountMicros == 0 &&
          (first.billingPeriod == 'P7D' || first.billingPeriod == 'P1W') &&
          first.billingCycleCount == 1;
      if (!(offer.offerId == null && phases.length == 1) && !trial) continue;
      if (plansByPeriod[months]?.hasSevenDayTrial == true) continue;
      plansByPeriod[months] = SubscriptionPlan(
        id: offer.basePlanId,
        months: months,
        price: renewal.formattedPrice,
        hasSevenDayTrial: trial,
        androidProduct: product,
      );
    }
    return plansByPeriod.values.toList();
  }

  Future<void> purchase(SubscriptionPlan plan) async {
    if (!enabled || isPremium || busy || pending || !plans.contains(plan)) {
      return;
    }
    busy = true;
    notice = null;
    notifyListeners();
    try {
      if (Platform.isIOS) {
        final result = await _apple.invokeMapMethod<String, dynamic>(
          'purchase',
          plan.id,
        );
        switch (result?['state']) {
          case 'purchased':
            await _serialize(
              () => _saveExpiry(result?['expiresAt'] as int? ?? 0),
            );
            _finish(isPremium ? null : BillingNotice.verificationUnavailable);
          case 'pending':
            pending = true;
            _finish(BillingNotice.pending);
          case 'canceled':
            _finish(null);
          default:
            _finish(BillingNotice.purchaseFailed);
        }
        return;
      }

      final product = plan.androidProduct;
      if (product == null || !await _playReady()) {
        _finish(BillingNotice.unavailable);
        return;
      }
      final started = await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: GooglePlayPurchaseParam(
          productDetails: product,
          offerToken: product.offerToken,
        ),
      );
      if (!started) {
        _finish(BillingNotice.purchaseFailed);
      } else if (busy) {
        _purchaseTimeout?.cancel();
        _purchaseTimeout = Timer(
          const Duration(seconds: 90),
          () => _finish(null),
        );
      }
    } catch (_) {
      _finish(BillingNotice.purchaseFailed);
    }
  }

  Future<void> restore() async {
    if (!enabled || busy) return;
    busy = true;
    notice = null;
    notifyListeners();
    try {
      await _serialize(() async {
        if (Platform.isIOS) {
          await _saveExpiry(await _apple.invokeMethod<int>('restore') ?? 0);
          if (isPremium) pending = false;
        } else {
          await _refreshPlayEntitlement();
        }
      });
      _finish(
        isPremium
            ? BillingNotice.restored
            : pending
            ? BillingNotice.pending
            : BillingNotice.noSubscription,
      );
    } catch (_) {
      _finish(BillingNotice.verificationUnavailable);
    }
  }

  Future<void> refreshEntitlement() async {
    if (!_started) return;
    try {
      await _serialize(() async {
        if (Platform.isIOS) {
          await _saveExpiry(await _apple.invokeMethod<int>('entitlement') ?? 0);
          if (isPremium && pending) {
            pending = false;
            notice = null;
            notifyListeners();
          }
        } else {
          await _refreshPlayEntitlement();
        }
      });
    } catch (_) {
      // Keep a previously verified entitlement only until its verified expiry.
    }
  }

  Future<int> _verifyPlay(PurchaseDetails purchase) async {
    await FirebaseService().authenticate();
    final result = await FirebaseFunctions.instance
        .httpsCallable(
          'verifyHydrationSubscription',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
        )
        .call<Map<String, dynamic>>({
          'purchaseToken': purchase.verificationData.serverVerificationData,
        });
    return (result.data['expiresAt'] as num?)?.toInt() ?? 0;
  }

  Future<void> _refreshPlayEntitlement() async {
    final billing = InAppPurchase.instance;
    if (!await billing.isAvailable()) {
      throw StateError('Play Billing unavailable');
    }
    final addition = billing
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final response = await addition.queryPastPurchases();
    if (response.error != null) {
      throw StateError('Could not query Play purchases');
    }
    var latest = 0;
    final matches = response.pastPurchases.where(
      (purchase) => purchase.productID == _androidId,
    );
    final wasPending = pending;
    try {
      for (final purchase in matches) {
        if (purchase.status == PurchaseStatus.pending) continue;
        final expiry = await _verifyPlay(purchase);
        if (expiry > latest) latest = expiry;
        if (expiry > 0 && purchase.pendingCompletePurchase) {
          await billing.completePurchase(purchase);
        }
      }
    } catch (_) {
      pending = true;
      notice = BillingNotice.verificationUnavailable;
      notifyListeners();
      rethrow;
    }
    pending = matches.any(
      (purchase) => purchase.status == PurchaseStatus.pending,
    );
    await _saveExpiry(latest);
    if (wasPending &&
        !pending &&
        (notice == BillingNotice.pending ||
            notice == BillingNotice.verificationUnavailable)) {
      notice = null;
      notifyListeners();
    }
  }

  Future<void> _handlePlayUpdates(List<PurchaseDetails> purchases) async {
    final billing = InAppPurchase.instance;
    for (final purchase in purchases) {
      if (purchase.productID != _androidId) {
        if (busy && purchase.productID.isEmpty) {
          if (purchase.status == PurchaseStatus.canceled) _finish(null);
          if (purchase.status == PurchaseStatus.error) {
            _finish(BillingNotice.purchaseFailed);
          }
        }
        continue;
      }
      switch (purchase.status) {
        case PurchaseStatus.pending:
          pending = true;
          _finish(BillingNotice.pending);
        case PurchaseStatus.canceled:
          pending = false;
          _finish(null);
        case PurchaseStatus.error:
          pending = false;
          _finish(BillingNotice.purchaseFailed);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          try {
            final expiry = await _verifyPlay(purchase);
            if (expiry > 0) {
              if (purchase.pendingCompletePurchase) {
                await billing.completePurchase(purchase);
              }
              await _saveExpiry(expiry);
              pending = false;
              _finish(null);
            } else {
              pending = false;
              _finish(BillingNotice.verificationUnavailable);
            }
          } catch (_) {
            pending = true;
            _finish(BillingNotice.verificationUnavailable);
          }
      }
    }
  }

  void _finish(BillingNotice? next) {
    _purchaseTimeout?.cancel();
    busy = false;
    notice = next;
    notifyListeners();
  }
}
