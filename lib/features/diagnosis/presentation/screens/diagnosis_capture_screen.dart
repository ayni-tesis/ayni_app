import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/diagnosis_provider.dart';
import 'diagnosis_processing_screen.dart';

class DiagnosisCaptureScreen extends ConsumerStatefulWidget {
  final bool isOfflineMode;
  final bool preferGallery;

  const DiagnosisCaptureScreen({
    super.key,
    required this.isOfflineMode,
    this.preferGallery = false,
  });

  @override
  ConsumerState<DiagnosisCaptureScreen> createState() => _DiagnosisCaptureScreenState();
}

class _DiagnosisCaptureScreenState extends ConsumerState<DiagnosisCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.preferGallery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickImage(ImageSource.gallery);
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      ref.read(diagnosisNotifierProvider.notifier).setCapturedImage(
            image.path,
            widget.isOfflineMode,
          );

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Ask the user which detection mode to use before starting processing.
      await _showModeSelectionSheet(image.path);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar la imagen: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Shows a bottom sheet where the user picks offline (IA local) or online
  /// (server) detection. Navigates to processing with the chosen mode.
  Future<void> _showModeSelectionSheet(String imagePath) async {
    final bool? useOffline = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ModeSelectionSheet(imagePath: imagePath),
    );

    // null means the user dismissed the sheet without choosing — do nothing.
    if (useOffline == null || !mounted) return;

    // Update provider with the chosen mode before processing.
    ref.read(diagnosisNotifierProvider.notifier).setCapturedImage(
          imagePath,
          useOffline,
        );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DiagnosisProcessingScreen(
          imagePath: imagePath,
          isOfflineMode: useOffline,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.black2, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Diagnosticar Planta',
          style: AppTextStyles.heading6.copyWith(color: AppColors.black2),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppSpacing.s4),
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      size: 56,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  'Instrucciones de captura',
                  style: AppTextStyles.mediumTextBold.copyWith(color: AppColors.black2),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  'Para obtener un diagnóstico preciso con nuestra IA:',
                  style: AppTextStyles.bodyRegular.copyWith(color: AppColors.gray2),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s3),
                _buildGuideItem(
                  Icons.center_focus_strong_rounded,
                  'Centra las hojas en la cámara.',
                ),
                _buildGuideItem(
                  Icons.wb_sunny_rounded,
                  'Evita sombras fuertes o reflejos directos de luz.',
                ),
                _buildGuideItem(
                  Icons.photo_filter_rounded,
                  'Asegúrate de que la foto no esté borrosa.',
                ),
                const SizedBox(height: AppSpacing.s5),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_rounded, size: 24),
                        const SizedBox(width: AppSpacing.s1 + 4),
                        Text(
                          'Tomar Foto',
                          style: AppTextStyles.bodyBold.copyWith(color: AppColors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s2 + 4),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.photo_library_rounded, size: 22, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.s1 + 4),
                        Text(
                          'Cargar de la Galería',
                          style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.s4),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                      const SizedBox(height: AppSpacing.s2 + 4),
                      Text(
                        'Cargando imagen...',
                        style: AppTextStyles.bodyBold.copyWith(color: AppColors.gray2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGuideItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s1),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.s1 + 2),
            decoration: BoxDecoration(
              color: AppColors.gray5,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.gray2),
          ),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyRegular.copyWith(color: AppColors.gray1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet that lets the user pick between offline (IA local) and online
/// (server) detection modes after selecting a photo.
class _ModeSelectionSheet extends StatelessWidget {
  final String imagePath;

  const _ModeSelectionSheet({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s3,
        AppSpacing.s4,
        AppSpacing.s4 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gray4,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.s3),

          // Image thumbnail + title
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(imagePath),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Elige el modo de detección',
                      style: AppTextStyles.mediumTextBold.copyWith(color: AppColors.black2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '¿Cómo quieres analizar esta foto?',
                      style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),

          // Mode cards
          _ModeCard(
            icon: Icons.phone_android_rounded,
            title: 'IA Local',
            subtitle: 'Sin internet · Usa el modelo del dispositivo',
            badge: 'Siempre disponible',
            badgeColor: AppColors.success,
            borderColor: AppColors.success,
            onTap: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: AppSpacing.s2),
          _ModeCard(
            icon: Icons.cloud_done_rounded,
            title: 'Con Servidor',
            subtitle: 'Requiere internet · Mayor precisión y Grad-CAM',
            badge: 'Más preciso',
            badgeColor: AppColors.primary,
            borderColor: AppColors.primary,
            onTap: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.s3),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor.withValues(alpha: 0.4), width: 1.5),
            borderRadius: BorderRadius.circular(14),
            color: borderColor.withValues(alpha: 0.04),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.s2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: badgeColor, size: 26),
              ),
              const SizedBox(width: AppSpacing.s2 + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.gray4),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
