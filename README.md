# water_intake

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
flutter sdk:3.38.2
generate assets:dart run build_runner build
fluttergen -c pubspec.yaml

## Hydration Plus billing

Open **Account → Hydration Plus** in debug or profile builds. The paywall is
visible by default in those builds and shows unavailable plans until the store
returns purchasable products. Release builds require
`--dart-define=HYDRATION_PLUS_ENABLED=true`. Enable the release flag after
the products and sandbox purchases work. Prices and trial eligibility come
from the stores.

| Billing period | App Store product ID | Play base plan ID | Suggested India price |
| --- | --- | --- | --- |
| 1 month | `water_premium_monthly` | `monthly` | ₹49 |
| 3 months | `water_premium_quarterly` | `three-months` | ₹119 |
| 6 months | `water_premium_half_yearly` | `six-months` | ₹199 |

Use the closest supported storefront price points. The suggestions above are
totals billed per period.

- **App Store Connect.** Create one Hydration Plus subscription group with
  the three auto-renewable products at the same service level. Set a one-week
  free introductory offer on each and test eligibility with a sandbox account.
- **Google Play Console.** Create the subscription `water_premium` for
  `com.sarang.waterreminder` and add the three auto-renewing base plans.
  Add a single seven-day free phase to each using new-customer eligibility
  that applies across the subscription. Use Play license testers and an
  internal testing build.
- **Play verification.** Enable the Google Play Developer API in the
  Firebase project, grant its Functions runtime service account access to
  this app in Play Console, and deploy `verifyHydrationSubscription`.
  Set `PLAY_BILLING_ENABLED=true` in the Functions deployment environment
  once the service account is configured. Deploy this function by name
  when you want to leave other Functions deployments untouched.
- Test trial and returning-customer prices, canceling a checkout, pending
  transactions, restoration on another device using the same store account,
  and entitlement removal after expiry. The Android server checks purchase
  tokens through Google Play. iOS reads verified StoreKit entitlements.
