import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_spacing.dart';
import 'core/network/navigation_notifier.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/connection_choice/presentation/screens/connection_choice_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/get_started_screen.dart';
import 'features/auth/presentation/screens/sign_up_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/diagnosis/presentation/providers/diagnosis_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPrefs = await SharedPreferences.getInstance();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const AyniApp(),
    ),
  );
}

class AyniApp extends ConsumerWidget {
  const AyniApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    if (mounted) {
      setState(() {
        _hasSeenOnboarding = hasSeenOnboarding;
        _currentScreen = AppScreen.splash;
      });
      // After splash delay, go to onboarding (or connection choice if already seen)
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          setState(() {
            _currentScreen = _hasSeenOnboarding ? AppScreen.connectionChoice : AppScreen.onboarding;
          });
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
          const Icon(
            Icons.eco_rounded,
            size: 64,
            color: AppColors.secondary,
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 24,
                color: AppColors.primary,
              ),
            ),
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
