import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/diagnosis_provider.dart';
import 'diagnosis_result_screen.dart';

class LeafSelectionScreen extends ConsumerStatefulWidget {
  final bool isOfflineMode;

  const LeafSelectionScreen({super.key, required this.isOfflineMode});

  @override
  ConsumerState<LeafSelectionScreen> createState() => _LeafSelectionScreenState();
}

class _LeafSelectionScreenState extends ConsumerState<LeafSelectionScreen> {
  bool _isLoading = false;

  Future<void> _runClassification() async {
    setState(() => _isLoading = true);

    // Run Stage 2: Pest classification on all detected leaves
    final success = await ref.read(diagnosisNotifierProvider.notifier).runPestClassification();

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DiagnosisResultScreen(isOfflineMode: widget.isOfflineMode),
          ),
        );
      } else {
        final state = ref.read(diagnosisNotifierProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error ?? 'Error al clasificar plagas.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diagnosisNotifierProvider);
    final originalImageFile = state.capturedImagePath != null ? File(state.capturedImagePath!) : null;

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
          'Detección de Hojas',
          style: AppTextStyles.heading6.copyWith(color: AppColors.black2),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Original Image with Bounding Boxes
              if (originalImageFile != null)
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                    decoration: BoxDecoration(
                      color: AppColors.gray5,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              originalImageFile,
                              fit: BoxFit.cover,
                            ),
                            // Render Bounding Boxes
                            ...state.detectedLeaves.map((leaf) {
                              return Positioned(
                                left: leaf.boxX * constraints.maxWidth,
                                top: leaf.boxY * constraints.maxHeight,
                                width: leaf.boxWidth * constraints.maxWidth,
                                height: leaf.boxHeight * constraints.maxHeight,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 2.5,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: Container(
                                      color: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      child: const Text(
                                        'Hoja de Café',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.s3),
              // Crop previews and action
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hojas detectadas (${state.detectedLeaves.length})',
                        style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'YOLO ha segmentado las hojas detectadas en la foto. Verifícalas abajo:',
                        style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray2),
                      ),
                      const SizedBox(height: AppSpacing.s2),
                      // Horizontal Crops list
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: state.detectedLeaves.length,
                          itemBuilder: (context, index) {
                            final leaf = state.detectedLeaves[index];
                            return Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: AppSpacing.s2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.gray4),
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
                                    bottom: 4,
                                    right: 4,
                                    child: CircleAvatar(
                                      radius: 10,
                                      backgroundColor: AppColors.primary,
                                      child: Text(
                                        '${index + 1}',
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
                            );
                          },
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 56, // Accessible > 48dp
                        child: ElevatedButton(
                          onPressed: _isLoading || state.detectedLeaves.isEmpty ? null : _runClassification,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Iniciar Diagnóstico de Plagas',
                            style: AppTextStyles.bodyBold.copyWith(color: AppColors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s3),
                    ],
                  ),
                ),
              ),
            ],
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
                        'Analizando plagas con el clasificador...',
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
}
