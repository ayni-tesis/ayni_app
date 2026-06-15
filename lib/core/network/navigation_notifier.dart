import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppScreen { splash, onboarding, connectionChoice, getStarted, signUp, login, home }

final navigationProvider = StateNotifierProvider<NavigationNotifier, AppScreen>((ref) {
  return NavigationNotifier();
});

class NavigationNotifier extends StateNotifier<AppScreen> {
  NavigationNotifier() : super(AppScreen.splash);

  void goToOnboarding() => state = AppScreen.onboarding;
  void goToConnectionChoice() => state = AppScreen.connectionChoice;
  void goToGetStarted() => state = AppScreen.getStarted;
  void goToSignUp() => state = AppScreen.signUp;
  void goToLogin() => state = AppScreen.login;
  void goToHome() => state = AppScreen.home;
}
