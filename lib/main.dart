import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/version_check_service.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_spacing.dart';
import 'core/network/navigation_notifier.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/connection_choice/presentation/screens/connection_choice_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/get_started_screen.dart';
import 'features/auth/presentation/screens/sign_up_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/notifications/presentation/providers/notifications_provider.dart';
import 'features/profile/presentation/providers/profile_provider.dart';
import 'features/profile/presentation/widgets/version_widgets.dart';
import 'firebase_options.dart';
import 'shared/widgets/ayni_logo.dart';

/// Background FCM handler. Must be a top-level function (not a method)
/// so it survives the app being terminated by the OS. When the user
/// taps a notification on the lock screen, this is the entry point.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPrefs = await SharedPreferences.getInstance();

  // Initialize Firebase BEFORE any feature tries to read an FCM token.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Pass all uncaught errors from the framework to Crashlytics.
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics.
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Register the background handler BEFORE runApp so the OS can invoke
  // it while the app is terminated.
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPrefs),
    ],
  );

  // Restore any persisted session BEFORE the first frame so the user
  // never sees a flash of the login screen if they were already
  // authenticated.
  await container.read(authNotifierProvider.notifier).bootstrap();
  // Touch the profile notifier so it starts loading the stored
  // profile; the home screen reads it asynchronously and is fine
  // with a brief loading state.
  container.read(profileNotifierProvider);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AyniApp(),
    ),
  );
}

class AyniApp extends ConsumerWidget {
  const AyniApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Touch the notifications provider so FCM bootstraps early. We
    // intentionally do not `await` here — the notifier's own
    // `_bootstrap()` is fire-and-forget.
    ref.watch(notificationsProvider);

    return MaterialApp(
      title: 'Ayni',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppNavigator(),
    );
  }
}

class AppNavigator extends ConsumerStatefulWidget {
  const AppNavigator({super.key});

  @override
  ConsumerState<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends ConsumerState<AppNavigator> {
  AppScreen _currentScreen = AppScreen.splash;
  bool _hasSeenOnboarding = false;
  bool _isOfflineMode = false;

  @override
  void initState() {
    super.initState();
    _loadInitialScreen();
  }

  Future<void> _loadInitialScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    final isAuthenticated = ref.read(isAuthenticatedProvider);

    if (mounted) {
      setState(() {
        _hasSeenOnboarding = hasSeenOnboarding;
        _currentScreen = AppScreen.splash;
      });
    }

    // Run version check.
    final versionResult = await ref.read(versionCheckServiceProvider).checkAppVersion();

    if (versionResult != null) {
      if (versionResult.forceUpdate) {
        // Block startup and show dialog.
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => UpdateDialog(
              minimumVersion: versionResult.minimumVersion,
              updateUrl: versionResult.updateUrl,
              forceUpdate: true,
            ),
          );
        }
        return; // Halt further routing.
      } else {
        // Optional update: show dialog but proceed with routing.
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => UpdateDialog(
              minimumVersion: versionResult.minimumVersion,
              updateUrl: versionResult.updateUrl,
              forceUpdate: false,
            ),
          );
        }
      }
    }

    // After splash delay, route based on auth state.
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      setState(() {
        if (isAuthenticated) {
          _currentScreen = AppScreen.home;
        } else if (_hasSeenOnboarding) {
          _currentScreen = AppScreen.connectionChoice;
        } else {
          _currentScreen = AppScreen.onboarding;
        }
      });
    }
  }

  void _onOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      setState(() {
        _currentScreen = AppScreen.connectionChoice;
      });
    }
  }

  void _onOnlineSelected() {
    if (mounted) {
      setState(() {
        _isOfflineMode = false;
        _currentScreen = AppScreen.getStarted;
      });
    }
  }

  void _onOfflineSelected() {
    if (mounted) {
      setState(() {
        _isOfflineMode = true;
        _currentScreen = AppScreen.home;
      });
    }
  }

  void _onSignUpSelected() {
    if (mounted) {
      setState(() {
        _currentScreen = AppScreen.signUp;
      });
    }
  }

  void _onSignUpComplete() {
    if (mounted) {
      setState(() {
        _currentScreen = AppScreen.login;
      });
    }
  }

  void _onLoginSelected() {
    if (mounted) {
      setState(() {
        _currentScreen = AppScreen.login;
      });
    }
  }

  void _onGetStartedSkip() {
    if (mounted) {
      setState(() {
        _currentScreen = AppScreen.home;
      });
    }
  }

  void _onLoginComplete() {
    if (mounted) {
      setState(() {
        _currentScreen = AppScreen.home;
      });
    }
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case AppScreen.splash:
        return _SplashWidget();
      case AppScreen.onboarding:
        return OnboardingScreen(onComplete: _onOnboardingComplete);
      case AppScreen.connectionChoice:
        return ConnectionChoiceScreen(
          onOnlineSelected: _onOnlineSelected,
          onOfflineSelected: _onOfflineSelected,
        );
      case AppScreen.getStarted:
        return GetStartedScreen(
          onSignUpTap: _onSignUpSelected,
          onLogInTap: _onLoginSelected,
          onSkip: _onGetStartedSkip,
        );
      case AppScreen.signUp:
        return SignUpScreen(
          onSignUpSuccess: _onSignUpComplete,
          onLogInTap: _onLoginSelected,
        );
      case AppScreen.login:
        return LoginScreen(
          onLoginSuccess: _onLoginComplete,
          onSignUpTap: _onSignUpSelected,
        );
      case AppScreen.home:
        return HomeScreen(
          isOfflineMode: _isOfflineMode,
          onConnectionModeChange: () {
            setState(() {
              _currentScreen = AppScreen.connectionChoice;
            });
          },
          onLogout: () {
            setState(() {
              _currentScreen = AppScreen.getStarted;
            });
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _buildCurrentScreen(),
    );
  }
}

class _SplashWidget extends StatefulWidget {
  @override
  State<_SplashWidget> createState() => _SplashWidgetState();
}

class _SplashWidgetState extends State<_SplashWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                _buildLogo(),
                const SizedBox(height: AppSpacing.s3),
                _buildBrandName(),
                const Spacer(flex: 2),
                _buildLoadingIndicator(),
                const SizedBox(height: AppSpacing.s10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
          const AyniLogo(
            size: 64,
            fill: AppColors.white,
            veinColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildBrandName() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Ayn',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 56,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1B5E20),
            height: 1.1,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco, size: 8, color: AppColors.white),
            ),
            Container(
              width: 12,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF1B5E20),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 32,
      height: 32,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(
          AppColors.white.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}