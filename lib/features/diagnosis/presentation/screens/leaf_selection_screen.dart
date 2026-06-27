import 'dart:io';
import 'dart:math' show min;
import 'dart:ui' as ui;
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

  // Natural pixel size of the captured image, needed to compute the
  // letterbox rect when displaying with BoxFit.contain.
  Size? _imageNaturalSize;

  @override
  void initState() {
    super.initState();
    _loadImageNaturalSize();
  }

  Future<void> _loadImageNaturalSize() async {
    final path = ref.read(diagnosisNotifierProvider).capturedImagePath;
    if (path == null) return;
    try {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _imageNaturalSize = Size(
            frame.image.width.toDouble(),
            frame.image.height.toDouble(),
          );
        });
      }
    } catch (_) {
      // Falls back to full-container mapping if size can't be read.
    }
  }

  /// Computes the rect (in container-local pixels) where BoxFit.contain
  /// actually draws the image. Bounding box coords must be mapped to this
  /// rect, not to the full container, to stay aligned with the visible image.
  Rect _imageDisplayRect(Size container) {
    final natural = _imageNaturalSize;
    if (natural == null || natural.width == 0 || natural.height == 0) {
      return Offset.zero & container;
    }
    final scale = min(
      container.width / natural.width,
      container.height / natural.height,
    );
    final displayW = natural.width * scale;
    final displayH = natural.height * scale;
    final offsetX = (container.width - displayW) / 2;
    final offsetY = (container.height - displayH) / 2;
    return Rect.fromLTWH(offsetX, offsetY, displayW, displayH);
  }

  Future<void> _runClassification() async {
    setState(() => _isLoading = true);

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
    final originalImageFile =
        state.capturedImagePath != null ? File(state.capturedImagePath!) : null;

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
              // ── Image + bounding boxes ──────────────────────────────────────
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
                        final containerSize = constraints.biggest;
                        final imageRect = _imageDisplayRect(containerSize);

                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            // Full image — contain keeps every pixel visible.
                            Image.file(
                              originalImageFile,
                              fit: BoxFit.contain,
                            ),

                            // Bounding boxes mapped to the letterboxed image rect.
                            ...state.detectedLeaves.map((leaf) {
                              return Positioned(
                                left: imageRect.left + leaf.boxX * imageRect.width,
                                top: imageRect.top + leaf.boxY * imageRect.height,
                                width: leaf.boxWidth * imageRect.width,
                                height: leaf.boxHeight * imageRect.height,
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 2),
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

              // ── Crops + action button ───────────────────────────────────────
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
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading || state.detectedLeaves.isEmpty
                              ? null
                              : _runClassification,
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

          // ── Loading overlay ─────────────────────────────────────────────────
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
