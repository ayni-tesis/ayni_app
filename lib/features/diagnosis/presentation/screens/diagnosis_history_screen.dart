import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/animation_utils.dart';
import '../../domain/entities/pest_type.dart';
import '../../domain/entities/diagnosis.dart';
import '../providers/diagnosis_provider.dart';

class DiagnosisHistoryScreen extends ConsumerWidget {
  const DiagnosisHistoryScreen({super.key});

  Color _getPestTextColor(PestType pest) {
    switch (pest) {
      case PestType.roya:
        return AppColors.error;
      case PestType.minador:
        return const Color(0xFFD48F00);
      case PestType.phoma:
        return AppColors.gray1;
      case PestType.healthy:
        return AppColors.success;
      case PestType.redspider:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(diagnosisHistoryProvider);

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
          'Historial Diagnósticos',
          style: AppTextStyles.heading6.copyWith(color: AppColors.black2),
        ),
        centerTitle: true,
      ),
      body: historyAsync.when(
        data: (history) {
          if (history.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history_toggle_off_rounded,
                        size: 44,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'Sin diagnósticos aún',
                      style: AppTextStyles.mediumTextBold.copyWith(color: AppColors.black2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toma fotos de tus plantas de café en campo para detectar plagas a tiempo.',
                      style: AppTextStyles.bodyRegular.copyWith(color: AppColors.gray2),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.s4),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final diagnosis = history[index];
              final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(diagnosis.dateTime);
              final isOriginalFileExists = File(diagnosis.originalImagePath).existsSync();

              return StaggeredSlideFade(
                index: index,
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.s3),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gray5),
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  children: [
                    // Image thumbnail
                    Container(
                      width: 100,
                      height: 100,
                      color: AppColors.gray5,
                      child: isOriginalFileExists
                          ? Image.file(
                              File(diagnosis.originalImagePath),
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.broken_image_rounded, color: AppColors.gray4),
                    ),
                    const SizedBox(width: AppSpacing.s2 + 4),
                    // Diagnostic details
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedDate,
                              style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray3),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              diagnosis.hasInfection
                                  ? 'Enfermedades Detectadas'
                                  : 'Planta Sana',
                              style: AppTextStyles.bodyBold.copyWith(
                                color: diagnosis.hasInfection ? AppColors.error : AppColors.success,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              diagnosis.overallStatusSummary,
                              style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray1),
                            ),
                            const SizedBox(height: 6),
                            // Badges for offline/online and sync
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: diagnosis.isOffline
                                        ? AppColors.warning.withValues(alpha: 0.12)
                                        : AppColors.success.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        diagnosis.isOffline
                                            ? Icons.cloud_off_rounded
                                            : Icons.wifi_rounded,
                                        size: 10,
                                        color: diagnosis.isOffline
                                            ? const Color(0xFFD48F00)
                                            : AppColors.success,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        diagnosis.isOffline ? 'Offline' : 'Online',
                                        style: TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: diagnosis.isOffline
                                              ? const Color(0xFFD48F00)
                                              : AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (diagnosis.isOffline)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: diagnosis.isSynced
                                          ? AppColors.success.withValues(alpha: 0.12)
                                          : AppColors.warning.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          diagnosis.isSynced
                                              ? Icons.check_circle_rounded
                                              : Icons.sync_problem_rounded,
                                          size: 10,
                                          color: diagnosis.isSynced
                                              ? AppColors.success
                                              : const Color(0xFFD48F00),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          diagnosis.isSynced ? 'Sincronizado' : 'Pendiente',
                                          style: TextStyle(
                                            fontFamily: 'Nunito',
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: diagnosis.isSynced
                                                ? AppColors.success
                                                : const Color(0xFFD48F00),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.gray3),
                      onPressed: () {
                        // View read-only diagnosis detail sheet
                        _showDiagnosisDetail(context, diagnosis);
                      },
                    ),
                  ],
                ),
              ));
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        error: (error, _) => Center(
          child: Text('Error al cargar historial: $error', style: AppTextStyles.bodyRegular.copyWith(color: AppColors.error)),
        ),
      ),
    );
  }

  void _showDiagnosisDetail(BuildContext context, Diagnosis diagnosis) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.gray4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  Text(
                    'Detalle del Diagnóstico',
                    style: AppTextStyles.heading5.copyWith(color: AppColors.black2),
                  ),
                  Text(
                    DateFormat('dd MMMM yyyy, hh:mm a').format(diagnosis.dateTime),
                    style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray3),
                  ),
                  const SizedBox(height: AppSpacing.s4),

                  // Image section
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.gray5,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: File(diagnosis.originalImagePath).existsSync()
                        ? Image.file(File(diagnosis.originalImagePath), fit: BoxFit.cover)
                        : const Icon(Icons.broken_image_rounded, size: 64, color: AppColors.gray4),
                  ),
                  const SizedBox(height: AppSpacing.s4),

                  Text(
                    'Hojas analizadas (${diagnosis.detectedLeaves.length})',
                    style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2),
                  ),
                  const SizedBox(height: AppSpacing.s2),

                  ...diagnosis.detectedLeaves.map((leaf) {
                    final leafPest = leaf.diagnosedPest ?? PestType.healthy;
                    final leafConf = leaf.confidence ?? 1.0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.s2 + 4),
                      padding: const EdgeInsets.all(AppSpacing.s2 + 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.gray5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: AppColors.gray5,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: File(leaf.croppedImagePath).existsSync()
                                ? Image.file(File(leaf.croppedImagePath), fit: BoxFit.cover)
                                : const Icon(Icons.broken_image_rounded),
                          ),
                          const SizedBox(width: AppSpacing.s2 + 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  leafPest.displayName,
                                  style: AppTextStyles.bodyBold.copyWith(
                                    color: _getPestTextColor(leafPest),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Confianza: ${(leafConf * 100).toStringAsFixed(1)}%',
                                  style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.s6),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
