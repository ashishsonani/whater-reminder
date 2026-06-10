import 'package:get/get.dart';
import 'package:water_intake/view/account/screen/preferences/binding/preferences_binding.dart';
import 'package:water_intake/view/account/screen/preferences/preferences_screen.dart';
import 'package:water_intake/view/account/screen/preferences/water_intake_goal/water_intake_goal_screen.dart';
import 'package:water_intake/view/account/screen/reminder/binding/drink_reminders_binding.dart';
import 'package:water_intake/view/account/screen/reminder/drink_reminders_screen.dart';
import 'package:water_intake/view/dashboard/binding/dashboard_binding.dart';
import 'package:water_intake/view/dashboard/screen/dashboard_screen.dart';
import 'package:water_intake/view/on_board/binding/on_board_binding.dart';
import 'package:water_intake/view/on_board/screen/on_board_screen.dart';
import 'package:water_intake/view/reminder/binding/reminder_binding.dart';
import 'package:water_intake/view/reminder/screen/add_reminder_screen.dart';
import 'package:water_intake/view/splash/binding/splash_binding.dart';
import 'package:water_intake/view/splash/screen/splash_screen.dart';
import 'package:water_intake/view/walkthrough/binding/walkthrough_binding.dart';
import 'package:water_intake/view/walkthrough/screen/goal_screen.dart';
import 'package:water_intake/view/walkthrough/screen/walkthrough_screen.dart';
import 'package:water_intake/view/account/screen/privacy_policy_screen.dart';
import 'package:water_intake/view/account/screen/terms_and_conditions_screen.dart';
import 'package:water_intake/view/home/screen/recommended_info_view.dart';
import 'package:water_intake/view/account/screen/premium_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String walkthrough = '/walkthrough';
  static const String goal = '/goal';
  static const String addReminder = '/addReminder';
  static const String drinkReminders = '/drinkReminders';
  static const String preferences = '/preferences';
  static const String waterIntakeGoal = '/waterIntakeGoal';
  static const String dashboard = '/dashboard';
  static const String privacyPolicy = '/privacyPolicy';
  static const String termsAndConditions = '/termsAndConditions';
  static const String intakeGoalInfo = '/intakeGoalInfo';
  static const String premium = '/premium';

  static List<GetPage> routes = [
    GetPage(name: splash, page: () => const SplashScreen(), binding: SplashBinding()),
    GetPage(name: onboarding, page: () => const OnBoardingScreen(), binding: OnBoardBinding()),
    GetPage(name: walkthrough, page: () => const WalkthroughScreen(), binding: WalkthroughBinding()),
    GetPage(name: goal, page: () => GoalScreen(), binding: WalkthroughBinding()),
    GetPage(name: addReminder, page: () => const AddReminderScreen(), binding: ReminderBinding()),
    GetPage(name: drinkReminders, page: () => const DrinkRemindersScreen(), binding: DrinkRemindersBinding()),
    GetPage(name: preferences, page: () => const PreferencesScreen(), binding: PreferencesBinding()),
    GetPage(name: waterIntakeGoal, page: () => const WaterIntakeGoalScreen(), binding: PreferencesBinding()),
    GetPage(name: dashboard, page: () =>  DashboardScreen(), binding: DashboardBinding()),
    GetPage(name: privacyPolicy, page: () => const PrivacyPolicyScreen()),
    GetPage(name: termsAndConditions, page: () => const TermsAndConditionsScreen()),
    GetPage(name: intakeGoalInfo, page: () => const RecommendedInfoView()),
    GetPage(name: premium, page: () => const PremiumScreen()),
  ];
}
