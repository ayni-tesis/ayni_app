import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/diagnosis_provider.dart';
import 'leaf_selection_screen.dart';

class DiagnosisProcessingScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final bool isOfflineMode;

  const DiagnosisProcessingScreen({
    super.key,
    required this.imagePath,
    required this.isOfflineMode,
  });

  @override
  ConsumerState<DiagnosisProcessingScreen> createState() => _DiagnosisProcessingScreenState();
}

class _DiagnosisProcessingScreenState extends ConsumerState<DiagnosisProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  bool _detectionFinished = false;
  bool _detectionSuccess = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    )..addListener(() {
        setState(() {});
      });

    // Start animation immediately
    _progressController.forward();

    // Defer detection start to after the first frame — avoids modifying
    // a provider while the widget tree is still building (Riverpod rule).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDetection();
    });
  }

  Future<void> _startDetection() async {
    try {
      final success = await ref.read(diagnosisNotifierProvider.notifier).runLeafDetection();
      if (!mounted) return;
      setState(() {
        _detectionFinished = true;
        _detectionSuccess = success;
        if (!success) {
          final state = ref.read(diagnosisNotifierProvider);
          _errorMessage = state.error ?? 'Error al procesar la imagen.';
        }
      });
      _onDetectionComplete();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detectionFinished = true;
        _detectionSuccess = false;
        _errorMessage = e.toString();
      });
      _onDetectionComplete();
    }
  }

  void _onDetectionComplete() {
    // Wait for animation to also complete before navigating
    if (_detectionFinished) {
      if (_detectionSuccess) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => LeafSelectionScreen(isOfflineMode: widget.isOfflineMode),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Error al procesar la imagen.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = (_progressAnimation.value * 100).toInt();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.file(
            File(widget.imagePath),
            fit: BoxFit.cover,
          ),
          // Dark overlay to guarantee contrast
          Container(
            color: Colors.black.withValues(alpha: 0.35),
          ),
          // Top bar with close button and title
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s2,
                  vertical: AppSpacing.s1,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      'Diagnostica',
                      style: AppTextStyles.heading6.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 48), // Spacer to center the title
                  ],
                ),
              ),
            ),
          ),
          // Centered glassmorphic card
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.s4),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.s2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: AppColors.primary,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        Text(
                          'Diagnosticando tu planta...',
                          style: AppTextStyles.bodyBold.copyWith(
                            color: AppColors.white,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nuestra IA está analizando las hojas de café',
                          style: AppTextStyles.smallTextRegular.copyWith(
                            color: AppColors.white.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Stack(
                          children: [
                            Container(
                              height: 10,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: _progressAnimation.value,
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      Color(0xFF27AE60),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s2),
                        Text(
                          '$progressPercent%',
                          style: AppTextStyles.heading5.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (_detectionFinished && !_detectionSuccess) ...[
                          const SizedBox(height: AppSpacing.s2),
                          Text(
                            _errorMessage ?? 'Error en la detección.',
                            style: AppTextStyles.smallTextRegular.copyWith(
                              color: AppColors.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.s2),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _detectionFinished = false;
                                _errorMessage = null;
                              });
                              _progressController.reset();
                              _progressController.forward();
                              _startDetection();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
