import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../diagnosis/domain/entities/diagnosis.dart';
import '../../../diagnosis/domain/entities/pest_type.dart';
import '../../../diagnosis/presentation/providers/diagnosis_provider.dart';
import '../../domain/entities/sync_status.dart';
import '../providers/sync_provider.dart';

class SyncStatusScreen extends ConsumerStatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  ConsumerState<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends ConsumerState<SyncStatusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Backfill: diagnósticos offline guardados antes de que existiera la
      // cola de sync (o por cualquier otra razón no encolados) no aparecen
      // en sync_queue. Los reconciliamos aquí para que no queden huérfanos.
      await _reconcilePendingDiagnoses();
      if (!mounted) return;
      await ref.read(syncNotifierProvider.notifier).refresh();
      ref.invalidate(pendingDiagnosesProvider);
    });
  }

  Future<void> _reconcilePendingDiagnoses() async {
    final historyResult = await ref.read(getDiagnosisHistoryUseCaseProvider)();
    final history = historyResult.fold((_) => <Diagnosis>[], (h) => h);
    final unsyncedOffline = history.where((d) => d.isOffline && !d.isSynced);

    final syncRepo = ref.read(syncRepositoryProvider);
    for (final diagnosis in unsyncedOffline) {
      await syncRepo.savePendingDiagnosis(diagnosis);
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncStatus = ref.watch(syncNotifierProvider);
    final pendingAsync = ref.watch(pendingDiagnosesProvider);

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
          'Sincronización',
          style: AppTextStyles.heading6.copyWith(color: AppColors.black2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () => ref.read(syncNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Status card ────────────────────────────────────────────────────
          _SyncStatusCard(syncStatus: syncStatus),
          // ─── Sync button ────────────────────────────────────────────────────
          if (syncStatus.hasPending && !syncStatus.isSyncing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _triggerSync(context),
                  icon: const Icon(Icons.cloud_upload_rounded),
                  label: Text(
                    'Sincronizar ahora (${syncStatus.pendingCount})',
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
          if (syncStatus.isSyncing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: null,
                  icon: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  ),
                  label: Text(
                    'Sincronizando...',
                    style: AppTextStyles.bodyBold.copyWith(color: AppColors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.7),
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.s3),
          // ─── Pending list ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: Row(
              children: [
                Text(
                  'Pendientes de sincronizar',
                  style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2),
                ),
                const Spacer(),
                pendingAsync.whenData((list) => Text(
                  '${list.length}',
                  style: AppTextStyles.bodyBold.copyWith(color: AppColors.gray2),
                )).value ?? const SizedBox.shrink(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Expanded(
            child: pendingAsync.when(
              data: (diagnoses) {
                if (diagnoses.isEmpty) {
                  return _AllSyncedState();
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                  itemCount: diagnoses.length,
                  itemBuilder: (context, index) {
                    final diagnosis = diagnoses[index];
                    return _PendingDiagnosisCard(diagnosis: diagnosis);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error: $e'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerSync(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(syncNotifierProvider.notifier).syncPending();
    if (!mounted) return;

    if (result > 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('$result diagnóstico(s) sincronizado(s)'),
          backgroundColor: AppColors.success,
        ),
      );
      // Refresh pending list
      ref.invalidate(pendingDiagnosesProvider);
    } else {
      final status = ref.read(syncNotifierProvider);
      if (status.errorMessage != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(status.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _SyncStatusCard extends StatelessWidget {
  final SyncStatus syncStatus;

  const _SyncStatusCard({required this.syncStatus});

  @override
  Widget build(BuildContext context) {
    late final Color statusColor;
    late final IconData statusIcon;
    late final String statusText;

    switch (syncStatus.state) {
      case SyncState.syncing:
        statusColor = AppColors.primary;
        statusIcon = Icons.sync_rounded;
        statusText = 'Sincronizando...';
      case SyncState.success:
        statusColor = syncStatus.hasPending ? AppColors.warning : AppColors.success;
        statusIcon = syncStatus.hasPending ? Icons.cloud_upload_rounded : Icons.cloud_done_rounded;
        statusText = syncStatus.hasPending
            ? '${syncStatus.pendingCount} pendientes'
            : 'Todo sincronizado';
      case SyncState.error:
        statusColor = AppColors.error;
        statusIcon = Icons.cloud_off_rounded;
        statusText = 'Error de sincronización';
      case SyncState.idle:
        statusColor = syncStatus.hasPending ? AppColors.warning : AppColors.success;
        statusIcon = syncStatus.hasPending ? Icons.cloud_upload_rounded : Icons.cloud_done_rounded;
        statusText = syncStatus.hasPending
            ? '${syncStatus.pendingCount} pendientes'
            : 'Todo sincronizado';
    }

    return Container(
      margin: const EdgeInsets.all(AppSpacing.s4),
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.s2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 28),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: AppTextStyles.bodyBold.copyWith(color: statusColor),
                ),
                const SizedBox(height: 4),
                if (syncStatus.lastSyncAt != null)
                  Text(
                    'Última sincronización: ${_formatDate(syncStatus.lastSyncAt!)}',
                    style: AppTextStyles.smallTextRegular.copyWith(
                      color: AppColors.gray2,
                      fontSize: 12,
                    ),
                  )
                else
                  Text(
                    'Nunca se ha sincronizado',
                    style: AppTextStyles.smallTextRegular.copyWith(
                      color: AppColors.gray3,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (syncStatus.state == SyncState.error && syncStatus.errorMessage != null)
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: AppColors.error),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(syncStatus.errorMessage!),
                    backgroundColor: AppColors.error,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }
}

class _PendingDiagnosisCard extends StatelessWidget {
  final Diagnosis diagnosis;

  const _PendingDiagnosisCard({required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    final hasInfection = diagnosis.hasInfection;
    final primaryPest = diagnosis.detectedLeaves
        .where((l) => l.diagnosedPest != null && l.diagnosedPest != PestType.healthy)
        .firstOrNull
        ?.diagnosedPest;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s2),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.gray5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s2 + 4),
        child: Row(
          children: [
            // Pest icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hasInfection
                    ? AppColors.error.withValues(alpha: 0.08)
                    : AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasInfection ? Icons.warning_amber_rounded : Icons.eco_rounded,
                color: hasInfection ? AppColors.error : AppColors.success,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.s2),
            // Info
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
                  const SizedBox(height: 2),
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
            // Pending badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    size: 12,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Pendiente',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

class _AllSyncedState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.s3),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_done_rounded,
                size: 56,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
            Text(
              'Todo sincronizado',
              style: AppTextStyles.heading6.copyWith(color: AppColors.black2),
            ),
            const SizedBox(height: 8),
            Text(
              'No tienes diagnósticos pendientes por sincronizar.',
              style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray2),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
