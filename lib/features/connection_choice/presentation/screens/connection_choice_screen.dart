import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../shared/widgets/ayni_logo.dart';

class ConnectionChoiceScreen extends ConsumerWidget {
  final VoidCallback onOnlineSelected;
  final VoidCallback onOfflineSelected;

  const ConnectionChoiceScreen({
    super.key,
    required this.onOnlineSelected,
    required this.onOfflineSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: AyniLogo(
                    size: 38,
                    fill: AppColors.primary,
                    veinColor: AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              // Title
              Text(
                '¿Cómo quieres usar Ayni?',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                'Puedes cambiar esto en cualquier momento\ndesde Configuración',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: AppColors.gray2,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 1),
              // Online option
              _ConnectionOption(
                icon: Icons.wifi_rounded,
                iconColor: AppColors.success,
                title: 'En línea',
                description: 'Diagnóstico con IA en tiempo real, sincronización automática',
                buttonLabel: 'Continuar en línea',
                buttonColor: AppColors.primary,
                buttonFg: AppColors.white,
                onTap: onOnlineSelected,
              ),
              const SizedBox(height: AppSpacing.s3),
              // Offline option — always enabled (user can choose offline mode)
              connectivityAsync.when(
                data: (isOnline) => _ConnectionOption(
                  icon: Icons.cloud_off_rounded,
                  iconColor: AppColors.warning,
                  title: 'Sin conexión',
                  description: 'Diagnósticos locales, sincroniza cuando tengas señal',
                  buttonLabel: 'Continuar sin conexión',
                  buttonColor: AppColors.gray5,
                  buttonFg: AppColors.primary,
                  subtitle: isOnline ? null : 'Sin conexión detectada',
                  onTap: onOfflineSelected,
                ),
                loading: () => _ConnectionOption(
                  icon: Icons.cloud_off_rounded,
                  iconColor: AppColors.warning,
                  title: 'Sin conexión',
                  description: 'Diagnósticos locales, sincroniza cuando tengas señal',
                  buttonLabel: 'Continuar sin conexión',
                  buttonColor: AppColors.gray5,
                  buttonFg: AppColors.gray3,
                  subtitle: 'Verificando...',
                  onTap: onOfflineSelected,
                ),
                error: (_, _) => _ConnectionOption(
                  icon: Icons.cloud_off_rounded,
                  iconColor: AppColors.warning,
                  title: 'Sin conexión',
                  description: 'Diagnósticos locales, sincroniza cuando tengas señal',
                  buttonLabel: 'Continuar sin conexión',
                  buttonColor: AppColors.gray5,
                  buttonFg: AppColors.primary,
                  onTap: onOfflineSelected,
                ),
              ),
              const Spacer(flex: 2),
              // Legal
              Text(
                'Al continuar, aceptas nuestra Política de Privacidad\ny Términos de Servicio',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: AppColors.gray3,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s10),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String buttonLabel;
  final Color buttonColor;
  final Color buttonFg;
  final String? subtitle;
  final VoidCallback? onTap;

  const _ConnectionOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.buttonColor,
    required this.buttonFg,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray5, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.s2),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.s2 + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black2,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(width: AppSpacing.s1),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              subtitle!,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        color: AppColors.gray2,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: buttonFg,
                disabledBackgroundColor: buttonColor,
                disabledForegroundColor: buttonFg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                buttonLabel,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
