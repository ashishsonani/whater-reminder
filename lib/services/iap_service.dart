// import 'dart:async';
//
// import 'package:flutter/foundation.dart';
// import 'package:get/get.dart';
// import 'package:in_app_purchase/in_app_purchase.dart';
// import 'package:water_intake/services/firebase_service.dart';
//
// class IAPService extends GetxService {
//   static IAPService get to => Get.find();
//
//   final InAppPurchase _iap = InAppPurchase.instance;
//   late StreamSubscription<List<PurchaseDetails>> _subscription;
//
//   final RxList<ProductDetails> products = <ProductDetails>[].obs;
//   final RxBool isPremium = false.obs;
//   final RxBool isLoading = true.obs;
//
//   static const Set<String> _kIds = {'water_premium_weekly', 'water_premium_monthly', 'water_premium_yearly'};
//
//   static Future<void> init() async {
//     final service = Get.put(IAPService(), permanent: true);
//     await service._initialize();
//   }
//
//   Future<void> _initialize() async {
//     final bool available = await _iap.isAvailable();
//     if (!available) {
//       if (kDebugMode) print("IAP Error: Store not available");
//       isLoading.value = false;
//       return;
//     }
//
//     final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
//     _subscription = purchaseUpdated.listen(
//       (purchaseDetailsList) {
//         _listenToPurchaseUpdated(purchaseDetailsList);
//       },
//       onDone: () {
//         _subscription.cancel();
//       },
//       onError: (error) {
//         if (kDebugMode) print("IAP Error: $error");
//       },
//     );
//
//     await loadProducts();
//     await checkPremiumStatus();
//     isLoading.value = false;
//   }
//
//   Future<void> loadProducts() async {
//     try {
//       final ProductDetailsResponse response = await _iap.queryProductDetails(_kIds);
//       if (response.notFoundIDs.isNotEmpty) {
//         if (kDebugMode) print("IAP Warning: Products not found: ${response.notFoundIDs}");
//       }
//
//       products.value = response.productDetails;
//
//       if (kDebugMode) {
//         print("IAP Success: Found ${products.length} products");
//         for (var p in products) {
//           print("IAP Product: ${p.id} - ${p.price}");
//         }
//       }
//     } catch (e) {
//       if (kDebugMode) print("IAP Error loading products: $e");
//     }
//   }
//
//   /// Use this for testing UI logic only
//   Future<void> simulatePurchase() async {
//     if (kDebugMode) {
//       print("IAP: Simulating successful purchase...");
//       await FirebaseService().setPremiumStatus(true);
//       isPremium.value = true;
//       Get.snackbar("Test Mode", "Premium features unlocked (Simulated)", snackPosition: SnackPosition.BOTTOM);
//     }
//   }
//
//   Future<void> buyProduct(ProductDetails product) async {
//     final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
//     await _iap.buyNonConsumable(purchaseParam: purchaseParam);
//   }
//
//   Future<void> restorePurchases() async {
//     try {
//       await _iap.restorePurchases();
//     } catch (e) {
//       print("Error restoring purchases: $e");
//     }
//   }
//
//   void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
//     purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
//       if (purchaseDetails.status == PurchaseStatus.pending) {
//         // Purchase is pending
//       } else {
//         if (purchaseDetails.status == PurchaseStatus.error) {
//           print("Purchase error: ${purchaseDetails.error}");
//         } else if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) {
//           await _verifyPurchase(purchaseDetails);
//         }
//
//         if (purchaseDetails.pendingCompletePurchase) {
//           await _iap.completePurchase(purchaseDetails);
//         }
//       }
//     });
//   }
//
//   Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
//     // In a production app, verify the purchase on a server.
//     // Here we update Firebase directly as requested.
//     await FirebaseService().setPremiumStatus(true);
//     isPremium.value = true;
//
//     Get.snackbar("Success", "Thank you for your purchase! Premium features are now unlocked.", snackPosition: SnackPosition.BOTTOM);
//   }
//
//   Future<void> checkPremiumStatus() async {
//     try {
//       String? uid = await FirebaseService().getUserId();
//       if (uid != null) {
//         var userDoc = await FirebaseService().firestore.collection('users').doc(uid).get();
//         if (userDoc.exists) {
//           isPremium.value = userDoc.data()?['isPremium'] ?? false;
//         }
//       }
//     } catch (e) {
//       print("Error checking premium status: $e");
//     }
//   }
//
//   @override
//   void onClose() {
//     _subscription.cancel();
//     super.onClose();
//   }
// }
