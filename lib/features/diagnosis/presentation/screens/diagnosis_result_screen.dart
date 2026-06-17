import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/pest_type.dart';
import '../providers/diagnosis_provider.dart';
import '../widgets/bounding_box_overlay.dart';
import '../widgets/severity_indicator.dart';

class DiagnosisResultScreen extends ConsumerStatefulWidget {
  final bool isOfflineMode;

  const DiagnosisResultScreen({super.key, required this.isOfflineMode});

  @override
  ConsumerState<DiagnosisResultScreen> createState() => _DiagnosisResultScreenState();
}

class _DiagnosisResultScreenState extends ConsumerState<DiagnosisResultScreen> {
  int _selectedLeafIndex = 0;
  bool _isSaving = false;

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.85) return AppColors.success;
    if (confidence >= 0.60) return AppColors.warning;
    return AppColors.error;
  }

  Color _getPestBadgeColor(PestType pest) {
    switch (pest) {
      case PestType.roya:
        return AppColors.error.withValues(alpha: 0.15);
      case PestType.minador:
        return AppColors.warning.withValues(alpha: 0.15);
      case PestType.phoma:
        return AppColors.gray2.withValues(alpha: 0.15);
      case PestType.healthy:
        return AppColors.success.withValues(alpha: 0.15);
      case PestType.redspider:
        return AppColors.error.withValues(alpha: 0.15);
    }
  }

  Color _getPestTextColor(PestType pest) {
    switch (pest) {
      case PestType.roya:
        return AppColors.error;
      case PestType.minador:
        return const Color(0xFFD48F00); // Dark warning yellow for text contrast
      case PestType.phoma:
        return AppColors.gray1;
      case PestType.healthy:
        return AppColors.success;
      case PestType.redspider:
        return AppColors.error;
    }
  }

  Future<void> _saveDiagnosis() async {
    setState(() => _isSaving = true);
    final success = await ref.read(diagnosisNotifierProvider.notifier).saveCompletedDiagnosis();
    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        // Show success sheet or alert
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                const SizedBox(width: 8),
                Text('¡Guardado!', style: AppTextStyles.mediumTextBold),
              ],
            ),
            content: Text(
              widget.isOfflineMode
                  ? 'Diagnóstico guardado localmente. Se sincronizará automáticamente cuando tengas señal.'
                  : 'Diagnóstico guardado y sincronizado con éxito.',
              style: AppTextStyles.bodyRegular.copyWith(color: AppColors.gray2),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss alert
                  Navigator.of(context).popUntil((route) => route.isFirst); // Go to Home
                },
                child: Text(
                  'Entendido',
                  style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        );
      } else {
        final state = ref.read(diagnosisNotifierProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error ?? 'Error al guardar el diagnóstico.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diagnosisNotifierProvider);
    final diagnosis = state.completedDiagnosis;

    if (diagnosis == null) {
      return const Scaffold(
        body: Center(child: Text('Error: No se encontró el diagnóstico.')),
      );
    }

    final hasInfection = diagnosis.hasInfection;
    final selectedLeaf = diagnosis.detectedLeaves[_selectedLeafIndex];
    final pest = selectedLeaf.diagnosedPest ?? PestType.healthy;
    final confidence = selectedLeaf.confidence ?? 1.0;
    final severity = selectedLeaf.severity ??
        (pest == PestType.healthy
            ? 0.0
            : confidence *
                (pest == PestType.roya
                    ? 0.95
                    : pest == PestType.phoma
                        ? 0.85
                        : pest == PestType.minador
                            ? 0.7
                            : pest == PestType.redspider
                                ? 0.6
                                : 0.5));

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Force them to finish or go back explicitly
        title: Text(
          'Resultado Diagnóstico',
          style: AppTextStyles.heading6.copyWith(color: AppColors.black2),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.s2),

                // ── Bounding Box Overlay (YOLOv8 + pest classification) ───────────
                BoundingBoxOverlay(
                  originalImagePath: diagnosis.originalImagePath,
                  detectedLeaves: diagnosis.detectedLeaves,
                  selectedIndex: _selectedLeafIndex,
                  onLeafTapped: (index) {
                    setState(() => _selectedLeafIndex = index);
                  },
                ),
                const SizedBox(height: AppSpacing.s2),

                // Instruction hint
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 14,
                      color: AppColors.gray3,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Toca una zona para ver el detalle',
                      style: AppTextStyles.smallTextRegular.copyWith(
                        color: AppColors.gray3,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s4),

                // General Health Banner Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.s3),
                  decoration: BoxDecoration(
                    color: hasInfection
                        ? AppColors.error.withValues(alpha: 0.08)
                        : AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hasInfection
                          ? AppColors.error.withValues(alpha: 0.2)
                          : AppColors.success.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.s1 + 2),
                        decoration: BoxDecoration(
                          color: hasInfection ? AppColors.error : AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          hasInfection ? Icons.warning_rounded : Icons.check_circle_rounded,
                          color: AppColors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s2 + 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasInfection ? '¡Problemas detectados!' : '¡Planta saludable!',
                              style: AppTextStyles.mediumTextBold.copyWith(
                                color: hasInfection ? AppColors.error : AppColors.success,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              diagnosis.overallStatusSummary,
                              style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s3 + 4),

                // Horizontal list of leaf crops
                Text(
                  'Selecciona una hoja para ver el detalle',
                  style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2),
                ),
                const SizedBox(height: AppSpacing.s1 + 4),
                SizedBox(
                  height: 96,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: diagnosis.detectedLeaves.length,
                    itemBuilder: (context, index) {
                      final leaf = diagnosis.detectedLeaves[index];
                      final isSelected = index == _selectedLeafIndex;
                      final leafPest = leaf.diagnosedPest ?? PestType.healthy;
                      final isLeafHealthy = leafPest == PestType.healthy;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedLeafIndex = index),
                        child: Container(
                          width: 86,
                          margin: const EdgeInsets.only(right: AppSpacing.s2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.gray4,
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.file(
                                  File(leaf.croppedImagePath),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Icon(
                                  isLeafHealthy ? Icons.check_circle : Icons.error_rounded,
                                  color: isLeafHealthy ? AppColors.success : AppColors.error,
                                  size: 16,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Hoja ${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),

                // Selected Leaf Detail Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.s3 + 4),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gray5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Detalle: Hoja ${_selectedLeafIndex + 1}',
                            style: AppTextStyles.mediumTextBold.copyWith(color: AppColors.black2),
                          ),
                          // Pest Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPestBadgeColor(pest),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              pest.displayName.toUpperCase(),
                              style: AppTextStyles.smallTextBold.copyWith(
                                color: _getPestTextColor(pest),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s3),
                      // Confidence score bar
                      Row(
                        children: [
                          Text(
                            'Confianza del diagnóstico:',
                            style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray2),
                          ),
                          const Spacer(),
                          Text(
                            '${(confidence * 100).toStringAsFixed(1)}%',
                            style: AppTextStyles.smallTextBold.copyWith(
                              color: _getConfidenceColor(confidence),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Progress bar matching DESIGN.md requirements
                      Container(
                        width: double.infinity,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.gray5,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: (confidence * 100).toInt(),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _getConfidenceColor(confidence),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: (100 - (confidence * 100)).toInt(),
                              child: const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                      if (pest != PestType.healthy) ...[
                        const SizedBox(height: AppSpacing.s3),
                        SeverityIndicator(severity: severity),
                      ],
                      const SizedBox(height: AppSpacing.s3 + 4),
                      // Diagnosis description
                      Text(
                        'Descripción de la Plaga',
                        style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pest.description,
                        style: AppTextStyles.bodyRegular.copyWith(color: AppColors.gray1, height: 1.4),
                      ),
                      const SizedBox(height: AppSpacing.s3 + 4),
                      // Actions / Recommendations
                      Text(
                        'Tratamiento y Recomendaciones',
                        style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2),
                      ),
                      const SizedBox(height: 6),
                      // Split recommendation lines and show bullet list
                      ...pest.treatmentRecommendation.split('\n').map((line) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                                Expanded(
                                  child: Text(
                                    line.replaceFirst(RegExp(r'^\d+\.\s+'), ''), // Strip numeric prefixes if any
                                    style: AppTextStyles.bodyRegular.copyWith(color: AppColors.gray1, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s5),

                // Save Action
                SizedBox(
                  width: double.infinity,
                  height: 56, // Accessible > 48dp
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveDiagnosis,
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
                        const Icon(Icons.save_rounded, size: 22),
                        const SizedBox(width: AppSpacing.s1 + 4),
                        Text(
                          'Guardar Diagnóstico',
                          style: AppTextStyles.bodyBold.copyWith(color: AppColors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s6),
              ],
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
