import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback onSignUpTap;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    required this.onSignUpTap,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa correo y contraseña.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() => _isLoading = false);
      widget.onLoginSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black2, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Login Form
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.s2),
                        // Title row (left title/subtitle, right avatar silhouette)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome Back! 👋',
                                    style: AppTextStyles.heading4.copyWith(
                                      color: AppColors.black2,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Let's Continue Your Green Journey",
                                    style: AppTextStyles.bodyRegular.copyWith(
                                      color: AppColors.gray2,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Avatar silhouette icon matching Figma
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 36,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s5),

                        // Email Field
                        _buildLabel('Email'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: AppTextStyles.bodyRegular.copyWith(color: AppColors.black2),
                          decoration: InputDecoration(
                            hintText: 'Email',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF94A3B8), size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s3),

                        // Password Field
                        _buildLabel('Password'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: AppTextStyles.bodyRegular.copyWith(color: AppColors.black2),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                            prefixIcon: const Icon(Icons.lock_outlined, color: Color(0xFF94A3B8), size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: const Color(0xFF94A3B8),
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s2),

                        // Remember me + Forgot Password (under fields)
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _rememberMe = !_rememberMe),
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: _rememberMe ? AppColors.primary : AppColors.white,
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: _rememberMe ? AppColors.primary : AppColors.gray4,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: _rememberMe
                                          ? const Icon(Icons.check, size: 14, color: AppColors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Remember me',
                                      style: AppTextStyles.smallTextRegular.copyWith(
                                        color: AppColors.gray1,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Forgot Password?',
                                style: AppTextStyles.smallTextBold.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s3),

                        // Divider: —— or ——
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppColors.gray5, thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
                              child: Text(
                                'or',
                                style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray3),
                              ),
                            ),
                            const Expanded(child: Divider(color: AppColors.gray5, thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s3 + 4),

                        // Social buttons stacked vertically (exactly like Figma)
                        _buildSocialButton(
                          icon: _googleIcon(),
                          label: 'Continue with Google',
                          onTap: () {},
                        ),
                        const SizedBox(height: AppSpacing.s2),
                        _buildSocialButton(
                          icon: const Icon(Icons.apple, color: AppColors.black2, size: 24),
                          label: 'Continue with Apple',
                          onTap: () {},
                        ),
                        const SizedBox(height: AppSpacing.s2),
                        _buildSocialButton(
                          icon: const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 24),
                          label: 'Continue with Facebook',
                          onTap: () {},
                        ),
                        const SizedBox(height: AppSpacing.s4),

                        // Toggle Register Link
                        Center(
                          child: GestureDetector(
                            onTap: widget.onSignUpTap,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: RichText(
                                text: TextSpan(
                                  style: AppTextStyles.bodyRegular.copyWith(color: AppColors.gray2, fontSize: 14),
                                  children: [
                                    const TextSpan(text: "Don't have an account? "),
                                    TextSpan(
                                      text: 'Sign up',
                                      style: AppTextStyles.bodyBold.copyWith(
                                        color: AppColors.primary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                      ],
                    ),
                  ),
                ),
                // Log in button at the very bottom
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.s4),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56, // Accessible > 48dp
                    child: ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: const StadiumBorder(), // Pill shape matching Figma
                        elevation: 0,
                      ),
                      child: Text(
                        'Log in',
                        style: AppTextStyles.bodyBold.copyWith(color: AppColors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.smallTextBold.copyWith(
        color: AppColors.black2,
        fontWeight: FontWeight.w700,
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

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5, vertical: AppSpacing.s4),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 4.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.s3),
              Text(
                'Logging in...',
                style: AppTextStyles.bodyBold.copyWith(
                  color: AppColors.gray1,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
