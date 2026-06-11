import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_intake/firebase_options.dart';
import 'package:water_intake/route/route.dart';
import 'package:water_intake/services/ad_service.dart';
import 'package:water_intake/services/notification_service.dart';
import 'package:water_intake/utils/app_translations.dart';
import 'package:water_intake/utils/local_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await LocalStorage.init();

  // Initialize Firebase Messaging background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  final notificationService = NotificationService();
  await notificationService.init();
  FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  await AdService.init();
  final appLifecycleReactor = AppLifecycleReactor(appOpenAdManager: AdService.appOpenAdManager);
  WidgetsBinding.instance.addObserver(appLifecycleReactor);
  // await IAPService.init();
  // await initializeDateFormatting('en_US', null);
  await initializeDateFormatting('tr_TR', null);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      // systemNavigationBarColor: Colors.blue, // navigation bar color
      statusBarColor: Colors.white, //
      statusBarIconBrightness: Brightness.dark, // For Android (dark icons)
      // status bar color
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  String? savedLang = prefs.getString('selected_language');
  Locale initialLocale;
  if (savedLang == 'Turkish' || savedLang == 'Türkçe') {
    initialLocale = const Locale('tr', 'TR');
  } else if (savedLang == 'Spanish' || savedLang == 'Español') {
    initialLocale = const Locale('es', 'ES');
  } else if (savedLang == 'German' || savedLang == 'Deutsch') {
    initialLocale = const Locale('de', 'DE');
  } else if (savedLang == 'Français' || savedLang == 'French') {
    initialLocale = const Locale('fr', 'FR');
  } else if (savedLang == 'हिन्दी' || savedLang == 'Hindi') {
    initialLocale = const Locale('hi', 'IN');
  } else if (savedLang == 'فارسی' || savedLang == 'Persian') {
    initialLocale = const Locale('fa', 'IR');
  } else if (savedLang == 'العربية' || savedLang == 'Arabic') {
    initialLocale = const Locale('ar', 'SA');
  } else if (savedLang == 'اردو' || savedLang == 'Urdu') {
    initialLocale = const Locale('ur', 'PK');
  } else if (savedLang == 'English' || savedLang == 'English (United States)') {
    initialLocale = const Locale('en', 'US');
  } else {
    final locale = PlatformDispatcher.instance.locale;

    switch (locale.languageCode) {
      case 'tr':
        initialLocale = const Locale('tr', 'TR');
        break;
      case 'es':
        initialLocale = const Locale('es', 'ES');
        break;
      case 'de':
        initialLocale = const Locale('de', 'DE');
        break;
      case 'fr':
        initialLocale = const Locale('fr', 'FR');
        break;
      case 'hi':
        initialLocale = const Locale('hi', 'IN');
        break;
      case 'fa':
        initialLocale = const Locale('fa', 'IR');
        break;
      case 'ar':
        initialLocale = const Locale('ar', 'SA');
        break;
      case 'ur':
        initialLocale = const Locale('ur', 'PK');
        break;
      case 'en':
        initialLocale = const Locale('en', 'US');
        break;
      default:
        initialLocale = const Locale('en', 'US'); // fallback
    }
  }

  runApp(MyApp(initialLocale: initialLocale));
}

class MyApp extends StatelessWidget {
  final Locale initialLocale;
  const MyApp({super.key, required this.initialLocale});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          initialRoute: AppRoutes.splash,
          getPages: AppRoutes.routes,
          translations: AppTranslations(),
          locale: initialLocale,
          fallbackLocale: const Locale('en', 'US'),
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('tr', 'TR'),
            Locale('es', 'ES'),
            Locale('de', 'DE'),
            Locale('fr', 'FR'),
            Locale('hi', 'IN'),
            Locale('fa', 'IR'),
            Locale('ar', 'SA'),
            Locale('ur', 'PK'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale?.languageCode) {
                return supportedLocale;
              }
            }
            return const Locale('en', 'US');
          },
        );
      },
    );
  }
}
