import Flutter
import GoogleMobileAds
import StoreKit
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var subscriptions: StoreKitSubscriptions?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GADMobileAds.sharedInstance().requestConfiguration.setPublisherFirstPartyIDEnabled(false)
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    subscriptions = StoreKitSubscriptions(messenger: engineBridge.applicationRegistrar.messenger())
  }
}

@MainActor
private final class StoreKitSubscriptions {
  private static let durations = [
    "water_premium_monthly": 1,
    "water_premium_quarterly": 3,
    "water_premium_half_yearly": 6
  ]
  private let channel: FlutterMethodChannel
  private var updates: Task<Void, Never>?
  private var products: [String: Product] = [:]

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "water_reminder/subscriptions", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      Task { @MainActor in
        guard let self else { return result(FlutterMethodNotImplemented) }
        do {
          switch call.method {
          case "plans":
            result(try await self.loadPlans())
          case "entitlement":
            result(await self.activeExpiration())
          case "restore":
            try await AppStore.sync()
            result(await self.activeExpiration())
          case "purchase":
            guard let id = call.arguments as? String, let product = self.products[id] else {
              return result(FlutterError(code: "product_unavailable", message: nil, details: nil))
            }
            switch try await product.purchase() {
            case .success(.verified(let transaction)):
              await transaction.finish()
              result(["state": "purchased", "expiresAt": await self.activeExpiration()])
            case .success(.unverified):
              result(FlutterError(code: "unverified_transaction", message: nil, details: nil))
            case .pending:
              result(["state": "pending"])
            case .userCancelled:
              result(["state": "canceled"])
            @unknown default:
              result(FlutterError(code: "unknown_purchase", message: nil, details: nil))
            }
          default:
            result(FlutterMethodNotImplemented)
          }
        } catch {
          result(FlutterError(code: "store_error", message: nil, details: nil))
        }
      }
    }
    updates = Task { [weak self] in
      for await transaction in Transaction.updates {
        guard case .verified(let verified) = transaction,
              Self.durations[verified.productID] != nil else { continue }
        await verified.finish()
        self?.channel.invokeMethod("entitlementChanged", arguments: nil)
      }
    }
  }

  deinit {
    updates?.cancel()
  }

  private func loadPlans() async throws -> [[String: Any]] {
    let fetched = try await Product.products(for: Self.durations.keys)
    products = [:]
    var plans: [[String: Any]] = []
    for product in fetched {
      guard let months = Self.durations[product.id],
            let info = product.subscription,
            info.subscriptionPeriod.unit == .month,
            info.subscriptionPeriod.value == months else { continue }
      products[product.id] = product
      var trial = false
      if let offer = info.introductoryOffer, offer.paymentMode == .freeTrial, offer.periodCount == 1 {
        let oneWeek = (offer.period.unit == .week && offer.period.value == 1)
          || (offer.period.unit == .day && offer.period.value == 7)
        if oneWeek { trial = await info.isEligibleForIntroOffer }
      }
      plans.append(["id": product.id, "months": months, "price": product.displayPrice, "trial": trial])
    }
    return plans
  }

  private func activeExpiration() async -> Int64 {
    var latest: Date?
    for await transaction in Transaction.currentEntitlements {
      guard case .verified(let verified) = transaction,
            Self.durations[verified.productID] != nil,
            verified.revocationDate == nil,
            !verified.isUpgraded,
            var expiry = verified.expirationDate else { continue }
      if expiry <= Date(),
         let statuses = try? await Product.SubscriptionInfo.status(for: verified.subscriptionGroupID ?? ""),
         let status = statuses.first(where: { entry in
           guard entry.state == .inGracePeriod, case .verified(let item) = entry.transaction else { return false }
           return item.id == verified.id
         }),
         case .verified(let renewal) = status.renewalInfo,
         let graceEnd = renewal.gracePeriodExpirationDate {
        expiry = graceEnd
      }
      if expiry > Date() && (latest == nil || expiry > latest!) { latest = expiry }
    }
    return latest.map { Int64($0.timeIntervalSince1970 * 1000) } ?? 0
  }
}
