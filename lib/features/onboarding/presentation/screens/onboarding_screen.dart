import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Diagnóstico instantáneo',
      description:
          'Toma una foto de la hoja de tu cafeto y en segundos conoces la plaga que la afecta.',
      icon: Icons.camera_alt_rounded,
      secondaryIcon: Icons.eco_rounded,
    ),
    OnboardingPage(
      title: 'Funciona sin internet',
      description:
          'El análisis funciona en cualquier lugar, aun sin conexión. Sincroniza después.',
      icon: Icons.cloud_off_rounded,
      secondaryIcon: Icons.wifi_off_rounded,
    ),
    OnboardingPage(
      title: 'Recomendaciones expertas',
      description:
          'Recibe indicaciones claras de tratamiento según el tipo de plaga detectada.',
      icon: Icons.lightbulb_outline_rounded,
      secondaryIcon: Icons.agriculture_rounded,
    ),
    OnboardingPage(
      title: 'Cuida tu plantación',
      description:
          'Historial de diagnósticos para que sigas la salud de tu cafetal en el tiempo.',
      icon: Icons.history_rounded,
      secondaryIcon: Icons.analytics_outlined,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s3,
                vertical: AppSpacing.s2,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onComplete,
                  child: Text(
                    'Omitir',
                    style: AppTextStyles.bodyBold.copyWith(
                      color: AppColors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            ),
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _OnboardingPageWidget(page: _pages[index]);
                },
              ),
            ),
            // Dots and buttons
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: Column(
                children: [
                  // Dots
                  _buildDots(),
                  const SizedBox(height: AppSpacing.s4),
                  // Buttons
                  _buildButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppColors.white
                : AppColors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        // Skip button
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onComplete,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.white,
              side: BorderSide(
                color: AppColors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
              backgroundColor: AppColors.white.withValues(alpha: 0.1),
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Omitir',
              style: AppTextStyles.bodyBold.copyWith(color: AppColors.white),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s2),
        // Next/Continue button
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.primary,
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _currentPage == _pages.length - 1 ? 'Comenzar' : 'Continuar',
              style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final IconData secondaryIcon;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.secondaryIcon,
  });
}

class _OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;

  const _OnboardingPageWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon illustration
          _buildIconSection(),
          const SizedBox(height: AppSpacing.s7),
          // Title
          Text(
            page.title,
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.white,
              fontSize: 32,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s3),
          // Description
          Text(
            page.description,
            style: AppTextStyles.bodyRegular.copyWith(
              color: AppColors.white.withValues(alpha: 0.85),
              fontSize: 17,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIconSection() {
    return SizedBox(
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background glow
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
          ),
          // Secondary icon (background)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                page.secondaryIcon,
                size: 28,
                color: AppColors.secondary,
              ),
            ),
          ),
          // Primary icon (foreground)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 56,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
