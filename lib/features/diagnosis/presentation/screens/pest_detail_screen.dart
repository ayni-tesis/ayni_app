import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/pest_type.dart';
import 'diagnosis_capture_screen.dart';

class PestDetailScreen extends StatelessWidget {
  final PestType pestType;

  const PestDetailScreen({super.key, required this.pestType});

  IconData _getPestIcon(PestType type) {
    switch (type) {
      case PestType.roya:
        return Icons.bug_report_rounded;
      case PestType.minador:
        return Icons.linear_scale_rounded;
      case PestType.phoma:
        return Icons.coronavirus_rounded;
      case PestType.redspider:
        return Icons.pest_control_rounded;
      case PestType.healthy:
        return Icons.eco_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = pestType.color;
    final isHealthy = pestType == PestType.healthy;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.black2),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          pestType.displayName,
          style: AppTextStyles.heading6.copyWith(color: AppColors.black2),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.s2),
                    // Hero Icon Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: color.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _getPestIcon(pestType),
                            color: color,
                            size: 72,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            pestType.displayName,
                            style: AppTextStyles.heading5.copyWith(
                              color: AppColors.black2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isHealthy
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isHealthy
                                  ? 'ESTADO SALUDABLE'
                                  : 'SEVERIDAD TÍPICA: ${pestType.severityDefault.displayName.toUpperCase()}',
                              style: AppTextStyles.smallTextBold.copyWith(
                                color: isHealthy ? AppColors.success : AppColors.error,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),

                    // Description
                    _buildSectionTitle('¿Qué es?'),
                    Text(
                      pestType.description,
                      style: AppTextStyles.bodyRegular.copyWith(
                        color: AppColors.gray1,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),

                    // Symptoms
                    _buildSectionTitle('Síntomas Visibles'),
                    ...pestType.symptoms.map((symptom) => _buildBulletPoint(symptom, color)),
                    const SizedBox(height: AppSpacing.s4),

                    // Treatment
                    _buildSectionTitle(isHealthy ? 'Consejos de Mantenimiento' : 'Control y Tratamiento'),
                    ...pestType.treatmentRecommendation.split('\n').map((rec) {
                      // Remove numeric indicators if present
                      final cleaned = rec.replaceFirst(RegExp(r'^\d+\.\s+'), '');
                      return _buildBulletPoint(cleaned, AppColors.primary);
                    }),
                    const SizedBox(height: AppSpacing.s4),

                    // Prevention
                    _buildSectionTitle('Medidas de Prevención'),
                    ...pestType.preventionTips.map((tip) => _buildBulletPoint(tip, AppColors.success)),
                    const SizedBox(height: AppSpacing.s5),
                  ],
                ),
              ),
            ),
            // Volver a diagnosticar CTA
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to the capture screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DiagnosisCaptureScreen(isOfflineMode: true),
                      ),
                    );
                  },
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: Text(
                    isHealthy ? 'Diagnosticar Planta' : 'Volver a Diagnosticar',
                    style: AppTextStyles.bodyBold.copyWith(color: AppColors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: AppTextStyles.bodyBold.copyWith(
          color: AppColors.black2,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text, Color bulletColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 4.0, right: 8.0),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: bulletColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyRegular.copyWith(
                color: AppColors.gray1,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
