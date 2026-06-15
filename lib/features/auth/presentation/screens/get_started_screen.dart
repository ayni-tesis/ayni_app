import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class GetStartedScreen extends StatelessWidget {
  final VoidCallback onSignUpTap;
  final VoidCallback onLogInTap;
  final VoidCallback onSkip;

  const GetStartedScreen({
    super.key,
    required this.onSignUpTap,
    required this.onLogInTap,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: onSkip,
            child: Text(
              'Omitir',
              style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.s1),
        ],
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
                  child: const Icon(
                    Icons.eco_rounded,
                    size: 44,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              // Heading
              Text(
                'Let\'s Get Started!',
                style: AppTextStyles.heading4.copyWith(
                  color: AppColors.black2,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Let\'s dive in into your account',
                style: AppTextStyles.bodyRegular.copyWith(color: AppColors.gray2),
              ),
              const SizedBox(height: AppSpacing.s6),

              // Social logins stacked vertically (exactly like Figma)
              _buildSocialButton(
                icon: _googleIcon(),
                label: 'Continue with Google',
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.s3),
              _buildSocialButton(
                icon: const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 24),
                label: 'Continue with Facebook',
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.s3),
              _buildSocialButton(
                icon: const Icon(Icons.flutter_dash, color: Color(0xFF1DA1F2), size: 24), // Twitter representation
                label: 'Continue with Twitter',
                onTap: () {},
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
                    'Sign up',
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
                    'Log in',
                    style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s6),

              // Footer legal (No divider or 'and', exactly like Figma)
              Text(
                'Privacy Policy Terms of Service',
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

  Widget _buildSocialButton({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54, // Accessible > 48dp
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.black2,
          side: const BorderSide(color: AppColors.gray5, width: 1),
          shape: const StadiumBorder(), // Pill shape matching Figma
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Row(
          children: [
            icon,
            const Spacer(),
            Text(
              label,
              style: AppTextStyles.bodyBold.copyWith(
                color: AppColors.gray1,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _googleIcon() {
    return SizedBox(
      width: 22,
      height: 22,
      child: Stack(
        children: [
          Positioned(right: 0, top: 0, child: Container(width: 11, height: 11, decoration: const BoxDecoration(color: Color(0xFFEA4335), shape: BoxShape.circle))),
          Positioned(left: 0, top: 0, child: Container(width: 11, height: 11, decoration: const BoxDecoration(color: Color(0xFF4285F4), shape: BoxShape.circle))),
          Positioned(right: 0, bottom: 0, child: Container(width: 11, height: 11, decoration: const BoxDecoration(color: Color(0xFFFBBC05), shape: BoxShape.circle))),
          Positioned(left: 0, bottom: 0, child: Container(width: 11, height: 11, decoration: const BoxDecoration(color: Color(0xFF34A853), shape: BoxShape.circle))),
        ],
      ),
    );
  }
}
