import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/ayni_logo.dart';

class GetStartedScreen extends StatelessWidget {
  final VoidCallback onSignUpTap;
  final VoidCallback onLogInTap;
  final VoidCallback onBack;

  const GetStartedScreen({
    super.key,
    required this.onSignUpTap,
    required this.onLogInTap,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.black2,
            size: 24,
          ),
          onPressed: onBack,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.s2),
              // Brand Logo
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: AyniLogo(
                      size: 44,
                      background: null,
                      faceColor: AppColors.primary,
                      featureColor: AppColors.secondary,
                      veinColor: AppColors.secondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              // Heading
              Text(
                '¡Comencemos!',
                style: AppTextStyles.heading4.copyWith(
                  color: AppColors.black2,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Crea tu cuenta o inicia sesión para detectar plagas en tus hojas de café.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyRegular.copyWith(color: AppColors.gray2),
              ),
              const SizedBox(height: AppSpacing.s6),

              // Action buttons (Sign up and Log in)
              SizedBox(
                width: double.infinity,
                height: 56, // Accessible > 48dp
                child: ElevatedButton(
                  onPressed: onSignUpTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: const StadiumBorder(), // Pill shape matching Figma
                    elevation: 0,
                  ),
                  child: Text(
                    'Crear cuenta',
                    style: AppTextStyles.bodyBold.copyWith(color: AppColors.white),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s2 + 4),
              SizedBox(
                width: double.infinity,
                height: 56, // Accessible > 48dp
                child: ElevatedButton(
                  onPressed: onLogInTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.primary,
                    shape: const StadiumBorder(), // Pill shape matching Figma
                    elevation: 0,
                  ),
                  child: Text(
                    'Iniciar sesión',
                    style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s6),

              // Footer legal
              Text(
                'Política de privacidad · Términos del servicio',
                style: AppTextStyles.smallTextRegular.copyWith(
                  color: AppColors.gray3,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
            ],
          ),
        ),
      ),
    );
  }
}