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

      // Set image in state
      ref.read(diagnosisNotifierProvider.notifier).setCapturedImage(
            image.path,
            widget.isOfflineMode,
          );

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DiagnosisProcessingScreen(
              imagePath: image.path,
              isOfflineMode: widget.isOfflineMode,
            ),
          ),
        );
      }
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
                // Icon / Mascot guide
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
                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 56, // Accessible > 48dp
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
                  height: 56, // Accessible > 48dp
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
                        'Detectando hojas con YOLO...',
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
