import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class UpdateDialog extends StatelessWidget {
  final String minimumVersion;
  final String updateUrl;
  final bool forceUpdate;

  const UpdateDialog({
    super.key,
    required this.minimumVersion,
    required this.updateUrl,
    required this.forceUpdate,
  });

  Future<void> _launchUrl() async {
    final uri = Uri.parse(updateUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !forceUpdate,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.system_update_rounded, color: AppColors.primary, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                forceUpdate ? 'Actualización obligatoria' : 'Actualización disponible',
                style: AppTextStyles.mediumTextBold.copyWith(color: AppColors.black2),
              ),
            ),
          ],
        ),
        content: Text(
          forceUpdate
              ? 'Para seguir usando Ayni, debes actualizar la aplicación a la versión mínima compatible ($minimumVersion).'
              : 'Hay una nueva versión disponible ($minimumVersion). Te recomendamos actualizar para disfrutar de las últimas mejoras.',
          style: AppTextStyles.bodyRegular.copyWith(color: AppColors.gray1),
        ),
        actions: [
          if (!forceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Más tarde',
                style: AppTextStyles.bodyBold.copyWith(color: AppColors.gray2),
              ),
            ),
          ElevatedButton(
            onPressed: _launchUrl,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }
}

class VersionCard extends StatefulWidget {
  const VersionCard({super.key});

  @override
  State<VersionCard> createState() => _VersionCardState();
}

class _VersionCardState extends State<VersionCard> {
  String _version = '1.0.2';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = packageInfo.version;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray5.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(AppSpacing.s3),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 24),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Versión de la aplicación',
                  style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2),
                ),
                Text(
                  'Versión actual: $_version',
                  style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray2),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Al día',
              style: AppTextStyles.smallTextBold.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
