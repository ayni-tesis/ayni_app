import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/crop.dart';
import '../../domain/entities/parcel.dart';
import '../providers/crops_provider.dart';
import 'add_crop_screen.dart';
import 'edit_parcel_screen.dart';

class ParcelDetailScreen extends ConsumerStatefulWidget {
  final String parcelId;
  final bool isOfflineMode;

  const ParcelDetailScreen({
    super.key,
    required this.parcelId,
    this.isOfflineMode = false,
  });

  @override
  ConsumerState<ParcelDetailScreen> createState() => _ParcelDetailScreenState();
}

class _ParcelDetailScreenState extends ConsumerState<ParcelDetailScreen> {
  String _filter = 'Todas'; // Todas, Sanas, Con plaga

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedParcelIdProvider.notifier).state = widget.parcelId;
      ref.read(cropsProvider.notifier).loadCropsByParcel(widget.parcelId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final parcelAsync = ref.watch(selectedParcelProvider);
    final cropsAsync = ref.watch(cropsProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.black2),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: parcelAsync.when(
          data: (p) => Text(
            p?.name ?? 'Parcela',
            style: AppTextStyles.heading6.copyWith(color: AppColors.black2),
          ),
          loading: () => const Text('...'),
          error: (_, _) => const Text('Error'),
        ),
        actions: [
          parcelAsync.whenData((parcel) {
            if (parcel == null) return const SizedBox.shrink();
            return Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                  onPressed: () => _navigateToEditParcel(context, parcel),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  onPressed: () => _confirmDeleteParcel(context, parcel),
                ),
              ],
            );
          }).value ?? const SizedBox.shrink(),
        ],
      ),
      body: Column(
        children: [
          // ─── Parcel info card ───────────────────────────────────────────────
          parcelAsync.when(
            data: (parcel) {
              if (parcel == null) return const SizedBox.shrink();
              return _ParcelInfoCard(parcel: parcel);
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          // ─── Crops filter + list ──────────────────────────────────────────
          Expanded(
            child: cropsAsync.when(
              data: (crops) {
                final filtered = crops.where((c) {
                  if (_filter == 'Sanas') return c.status == PlantStatus.healthy;
                  if (_filter == 'Con plaga') return c.status != PlantStatus.healthy;
                  return true;
                }).toList();

                return Column(
                  children: [
                    // Filter chips
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s4,
                        vertical: AppSpacing.s2,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Plantas (${filtered.length})',
                            style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2),
                          ),
                          const Spacer(),
                          ...['Todas', 'Sanas', 'Con plaga'].map((f) {
                            final sel = _filter == f;
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: FilterChip(
                                label: Text(f),
                                selected: sel,
                                onSelected: (_) => setState(() => _filter = f),
                                selectedColor: AppColors.secondary,
                                checkmarkColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: sel ? AppColors.primary : AppColors.gray1,
                                ),
                                backgroundColor: AppColors.white,
                                shape: StadiumBorder(
                                  side: BorderSide(
                                    color: sel ? AppColors.primary : AppColors.gray4,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    // Crops list
                    Expanded(
                      child: filtered.isEmpty
                          ? _EmptyCropsState(
                              onAddCrop: () => _navigateToAddCrop(context),
                              hasCrops: crops.isNotEmpty,
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s4,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final crop = filtered[index];
                                return _CropCard(
                                  crop: crop,
                                  onDelete: () => _confirmDeleteCrop(context, crop),
                                  onDiagnose: () {
                                    // Navigate to diagnosis capture for this crop
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: parcelAsync.whenData((parcel) {
        if (parcel == null) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          onPressed: () => _navigateToAddCrop(context),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add_rounded, color: AppColors.white),
          label: Text(
            'Agregar planta',
            style: AppTextStyles.bodyBold.copyWith(color: AppColors.white),
          ),
        );
      }).value,
    );
  }

  void _navigateToAddCrop(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddCropScreen(
          parcelId: widget.parcelId,
          isOfflineMode: widget.isOfflineMode,
        ),
      ),
    );
  }

  void _navigateToEditParcel(BuildContext context, Parcel parcel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditParcelScreen(parcel: parcel),
      ),
    );
  }

  void _confirmDeleteParcel(BuildContext context, Parcel parcel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar parcela'),
        content: Text(
          '¿Eliminar "${parcel.name}" y todas sus plantas? No se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(parcelsProvider.notifier).deleteParcel(parcel.id);
              Navigator.of(context).pop();
            },
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCrop(BuildContext context, Crop crop) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar planta'),
        content: Text('¿Eliminar "${crop.name}"? No se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(cropsProvider.notifier).deleteCrop(crop.id);
              // reload parcels to update plant count
              ref.read(parcelsProvider.notifier).loadParcels();
            },
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ParcelInfoCard extends StatelessWidget {
  final Parcel parcel;

  const _ParcelInfoCard({required this.parcel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.s4),
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.s2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.grass_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parcel.farmName,
                      style: AppTextStyles.smallTextRegular.copyWith(
                        color: AppColors.gray2,
                      ),
                    ),
                    if (parcel.variety != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          parcel.variety!,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${parcel.sizeHectares} ha',
                    style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
                  ),
                  Text(
                    'Tamaño',
                    style: AppTextStyles.smallTextRegular.copyWith(
                      color: AppColors.gray3,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CropCard extends StatelessWidget {
  final Crop crop;
  final VoidCallback onDelete;
  final VoidCallback onDiagnose;

  const _CropCard({
    required this.crop,
    required this.onDelete,
    required this.onDiagnose,
  });

  Color get _statusColor {
    switch (crop.status) {
      case PlantStatus.healthy:
        return AppColors.success;
      case PlantStatus.withPest:
        return AppColors.error;
      case PlantStatus.needsAttention:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHealthy = crop.status == PlantStatus.healthy;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s2),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.gray5),
      ),
      child: InkWell(
        onTap: onDiagnose,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s3),
          child: Row(
            children: [
              // Status icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isHealthy
                      ? AppColors.secondary
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isHealthy ? Icons.eco_rounded : Icons.warning_amber_rounded,
                  color: isHealthy ? AppColors.primary : AppColors.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crop.name,
                      style: AppTextStyles.bodyBold.copyWith(
                        color: AppColors.black2,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${crop.variety.displayName} • ${crop.status.displayName}',
                      style: AppTextStyles.smallTextRegular.copyWith(
                        color: AppColors.gray2,
                        fontSize: 12,
                      ),
                    ),
                    if (crop.lastDiagnosisDaysAgo != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        crop.lastDiagnosisDaysAgo == 0
                            ? 'Diagnóstico hoy'
                            : 'Último diagnóstico hace ${crop.lastDiagnosisDaysAgo} días',
                        style: AppTextStyles.smallTextRegular.copyWith(
                          color: AppColors.gray3,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  crop.status.displayName,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCropsState extends StatelessWidget {
  final VoidCallback onAddCrop;
  final bool hasCrops;

  const _EmptyCropsState({required this.onAddCrop, required this.hasCrops});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasCrops ? Icons.filter_list_off_rounded : Icons.eco_outlined,
              size: 56,
              color: AppColors.gray4,
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              hasCrops ? 'Sin plantas con ese filtro' : 'Sin plantas en esta parcela',
              style: AppTextStyles.bodyBold.copyWith(color: AppColors.gray2),
            ),
            if (!hasCrops) ...[
              const SizedBox(height: 8),
              Text(
                'Agrega plantas para hacer seguimiento a tu parcela.',
                style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray3),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s3),
              ElevatedButton.icon(
                onPressed: onAddCrop,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Agregar planta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
