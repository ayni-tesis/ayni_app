import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  final VoidCallback onSignUpSuccess;
  final VoidCallback onLogInTap;

  const SignUpScreen({
    super.key,
    required this.onSignUpSuccess,
    required this.onLogInTap,
  });

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(authNotifierProvider.notifier).signUp(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _nameController.text,
        );
    if (!mounted) return;

    if (ok) {
      await ref.read(profileNotifierProvider.notifier).ensureSeededFromAuth();
      // Register this device's FCM token now that we have a valid
      // session; bootstrap() alone can't do this on a fresh sign-up.
      await ref.read(notificationsProvider.notifier).registerFcmToken();
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 28),
              const SizedBox(width: 8),
              Text('¡Registro Exitoso!', style: AppTextStyles.mediumTextBold),
            ],
          ),
          content: Text(
            'Tu cuenta ha sido creada. Ya puedes empezar a usar Ayni.',
            style: AppTextStyles.bodyRegular.copyWith(color: AppColors.gray2),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.onSignUpSuccess();
              },
              child: Text(
                'Continuar',
                style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    } else {
      final error = ref.read(authNotifierProvider).error ??
          'No se pudo crear la cuenta. Inténtalo de nuevo.';
      messenger.showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);

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
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.s2),
                        Text(
                          'Únete a Ayni',
                          style: AppTextStyles.heading4.copyWith(
                            color: AppColors.black2,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Crea tu cuenta y empieza a proteger tu cafetal.',
                          style: AppTextStyles.bodyRegular
                              .copyWith(color: AppColors.gray2, fontSize: 14),
                        ),
                        const SizedBox(height: AppSpacing.s5),
                        _buildLabel('Nombre completo'),
                        const SizedBox(height: 8),
                        _buildField(
                          controller: _nameController,
                          hint: 'Juan Pérez',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        _buildLabel('Email'),
                        const SizedBox(height: 8),
                        _buildField(
                          controller: _emailController,
                          hint: 'tu@correo.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        _buildLabel('Contraseña'),
                        const SizedBox(height: 8),
                        _buildField(
                          controller: _passwordController,
                          hint: 'Mínimo 6 caracteres',
                          icon: Icons.lock_outlined,
                          obscure: _obscurePassword,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF94A3B8),
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        Center(
                          child: GestureDetector(
                            onTap: widget.onLogInTap,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              child: RichText(
                                text: TextSpan(
                                  style: AppTextStyles.bodyRegular.copyWith(
                                      color: AppColors.gray2, fontSize: 14),
                                  children: [
                                    const TextSpan(
                                        text: '¿Ya tienes cuenta? '),
                                    TextSpan(
                                      text: 'Inicia sesión',
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
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.s4),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.white),
                              ),
                            )
                          : Text(
                              'Crear cuenta',
                              style: AppTextStyles.bodyBold
                                  .copyWith(color: AppColors.white),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyRegular.copyWith(color: AppColors.black2),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}