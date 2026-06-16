import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/diagnosis.dart';
import '../../domain/entities/pest_type.dart';
import '../providers/diagnosis_provider.dart';
import 'diagnosis_capture_screen.dart';
import 'diagnosis_history_screen.dart';

class DiagnosisHomeScreen extends ConsumerWidget {
  final bool isOfflineMode;

  const DiagnosisHomeScreen({super.key, this.isOfflineMode = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(diagnosisHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Mode indicator ─────────────────────────────────────────────
            _ModeBanner(isOfflineMode: isOfflineMode),
            const SizedBox(height: AppSpacing.s4),

            // ─── Primary action: take photo ───────────────────────────────────
            _TakePhotoCard(isOfflineMode: isOfflineMode),
            const SizedBox(height: AppSpacing.s3),

            // ─── Quick options ───────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _QuickOptionCard(
                    icon: Icons.photo_library_outlined,
                    label: 'Desde galería',
                    onTap: () => _openCapture(context, fromGallery: true),
                  ),
                ),
                const SizedBox(width: AppSpacing.s2),
                Expanded(
                  child: _QuickOptionCard(
                    icon: Icons.history_rounded,
                    label: 'Último resultado',
                    onTap: () {
                      historyAsync.whenData((history) {
                        if (history.isNotEmpty) {
                          _openResult(context, history.first);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),

            // ─── Recent diagnoses ───────────────────────────────────────────────
            Text(
              'Diagnósticos recientes',
              style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2),
            ),
            const SizedBox(height: AppSpacing.s2),
            historyAsync.when(
              data: (history) {
                if (history.isEmpty) {
                  return _EmptyHistoryState();
                }
                return Column(
                  children: history
                      .take(5)
                      .map((d) => _RecentDiagnosisTile(
                            diagnosis: d,
                            onTap: () => _openResult(context, d),
                          ))
                      .toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.s4),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: Text('Error al cargar historial: $e'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCapture(BuildContext context, {bool fromGallery = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DiagnosisCaptureScreen(
          isOfflineMode: isOfflineMode,
          preferGallery: fromGallery,
        ),
      ),
    );
  }

  void _openResult(BuildContext context, Diagnosis diagnosis) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DiagnosisHistoryScreen(),
      ),
    );
  }
}

class _ModeBanner extends StatelessWidget {
  final bool isOfflineMode;

  const _ModeBanner({required this.isOfflineMode});

  @override
  Widget build(BuildContext context) {
    if (!isOfflineMode) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s2,
        vertical: AppSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 16, color: AppColors.warning),
          const SizedBox(width: AppSpacing.s1),
          Expanded(
            child: Text(
              'Modo sin conexión — diagnóstico con IA local',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.gray1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TakePhotoCard extends StatelessWidget {
  final bool isOfflineMode;

  const _TakePhotoCard({required this.isOfflineMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF04A033), Color(0xFF066F24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.s2),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 32, color: AppColors.white),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOfflineMode ? Icons.cloud_off : Icons.wifi,
                      size: 14,
                      color: AppColors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOfflineMode ? 'IA local' : 'IA activa',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          const Text(
            'Diagnosticar planta',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Toma una foto de la hoja de café para detectar Roya, Minador, Phoma u otras plagas.',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: AppColors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DiagnosisCaptureScreen(
                      isOfflineMode: isOfflineMode,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Tomar foto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickOptionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2 + 4),
        decoration: BoxDecoration(
          color: AppColors.gray5.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray4),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.black2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentDiagnosisTile extends StatelessWidget {
  final Diagnosis diagnosis;
  final VoidCallback onTap;

  const _RecentDiagnosisTile({required this.diagnosis, required this.onTap});

  Color get _statusColor {
    if (!diagnosis.hasInfection) return AppColors.success;
    if (diagnosis.detectedLeaves.any((l) =>
        l.diagnosedPest == PestType.roya ||
        l.diagnosedPest == PestType.redspider)) {
      return AppColors.error;
    }
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final primaryPest = diagnosis.detectedLeaves
        .where((l) => l.diagnosedPest != null && l.diagnosedPest != PestType.healthy)
        .firstOrNull
        ?.diagnosedPest;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s1 + 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.gray5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s2 + 4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  diagnosis.hasInfection
                      ? Icons.warning_amber_rounded
                      : Icons.eco_rounded,
                  color: _statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primaryPest?.displayName ?? 'Hoja sana',
                      style: AppTextStyles.smallTextBold.copyWith(
                        color: AppColors.black2,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${diagnosis.detectedLeaves.length} hojas • ${_formatDate(diagnosis.dateTime)}',
                      style: AppTextStyles.smallTextRegular.copyWith(
                        color: AppColors.gray3,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!diagnosis.isSynced)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.cloud_upload_outlined,
                    size: 12,
                    color: AppColors.warning,
                  ),
                ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: AppColors.gray4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return DateFormat('dd/MM/yyyy').format(dt);
  }
}

class _EmptyHistoryState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.gray5.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray5),
      ),
      child: Column(
        children: [
          const Icon(Icons.history_rounded, size: 40, color: AppColors.gray4),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Sin diagnósticos aún',
            style: AppTextStyles.smallTextBold.copyWith(color: AppColors.gray2),
          ),
          const SizedBox(height: 4),
          Text(
            'Toma tu primera foto para comenzar.',
            style: AppTextStyles.smallTextRegular.copyWith(
              color: AppColors.gray3,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
