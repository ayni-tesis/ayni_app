import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/parcel.dart';
import '../providers/crops_provider.dart';
import 'parcel_detail_screen.dart';
import 'add_parcel_screen.dart';

class CropsScreen extends ConsumerStatefulWidget {
  final bool isOfflineMode;

  const CropsScreen({super.key, this.isOfflineMode = false});

  @override
  ConsumerState<CropsScreen> createState() => _CropsScreenState();
}

class _CropsScreenState extends ConsumerState<CropsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final parcelsAsync = ref.watch(parcelsProvider);
    final stats = ref.watch(parcelStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mis Cultivos',
                            style: AppTextStyles.heading4.copyWith(
                              color: AppColors.black2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${stats.total} plantas registradas',
                            style: AppTextStyles.smallTextRegular.copyWith(
                              color: AppColors.gray2,
                            ),
                          ),
                        ],
                      ),
                      _AddButton(
                        onAddParcel: () => _navigateToAddParcel(context),
                        onAddCrop: stats.total > 0
                            ? null
                            : null, // only via parcel detail
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  // ─── Search bar ────────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.gray5.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.gray5),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                      decoration: const InputDecoration(
                        hintText: 'Buscar parcela o variedad...',
                        prefixIcon: Icon(Icons.search_rounded, color: AppColors.gray3),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ─── Stats row ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              child: Row(
                children: [
                  _StatChip(
                    label: 'Sanas',
                    count: stats.healthy,
                    color: AppColors.success,
                    icon: Icons.eco_rounded,
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  _StatChip(
                    label: 'Con plaga',
                    count: stats.withPest,
                    color: AppColors.error,
                    icon: Icons.warning_amber_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
            // ─── Parcels list ─────────────────────────────────────────────────
            Expanded(
              child: parcelsAsync.when(
                data: (parcels) {
                  final filtered = parcels.where((p) {
                    if (_searchQuery.isEmpty) return true;
                    final q = _searchQuery.toLowerCase();
                    return p.name.toLowerCase().contains(q) ||
                        p.farmName.toLowerCase().contains(q) ||
                        (p.variety?.toLowerCase().contains(q) ?? false);
                  }).toList();

                  if (filtered.isEmpty && parcels.isEmpty) {
                    return _EmptyState(onAddParcel: () => _navigateToAddParcel(context));
                  }
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'No se encontraron parcelas',
                        style: AppTextStyles.bodyBold.copyWith(color: AppColors.gray3),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final parcel = filtered[index];
                      return _ParcelCard(
                        parcel: parcel,
                        onTap: () => _navigateToParcelDetail(context, parcel),
                        onDelete: () => _confirmDeleteParcel(context, parcel),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Error al cargar: $e'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddParcel(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddParcelScreen(isOfflineMode: widget.isOfflineMode),
      ),
    );
  }

  void _navigateToParcelDetail(BuildContext context, Parcel parcel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ParcelDetailScreen(
          parcelId: parcel.id,
          isOfflineMode: widget.isOfflineMode,
        ),
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
          '¿Eliminar "${parcel.name}" y todas sus plantas? Esta acción no se puede deshacer.',
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
            },
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onAddParcel;
  final VoidCallback? onAddCrop;

  const _AddButton({required this.onAddParcel, this.onAddCrop});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(AppSpacing.s1 + 4),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.add_rounded, color: AppColors.white, size: 22),
      ),
      tooltip: 'Agregar',
      onSelected: (value) {
        if (value == 'parcel') onAddParcel();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'parcel',
          child: Row(
            children: [
              Icon(Icons.grid_view_rounded, color: AppColors.gray2, size: 20),
              SizedBox(width: 12),
              Text('Nueva parcela'),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$count $label',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParcelCard extends StatelessWidget {
  final Parcel parcel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ParcelCard({
    required this.parcel,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s2),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.gray5),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s3),
          child: Row(
            children: [
              // Left: icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.grass_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              // Center: info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parcel.name,
                      style: AppTextStyles.bodyBold.copyWith(
                        color: AppColors.black2,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${parcel.farmName} • ${parcel.sizeHectares} ha',
                      style: AppTextStyles.smallTextRegular.copyWith(
                        color: AppColors.gray2,
                        fontSize: 13,
                      ),
                    ),
                    if (parcel.variety != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
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
              // Right: plant count + chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gray5.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.eco_rounded, size: 12, color: AppColors.gray2),
                        const SizedBox(width: 4),
                        Text(
                          '${parcel.plantCount}',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.gray2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.gray4,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddParcel;

  const _EmptyState({required this.onAddParcel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.s4),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.grass_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
            Text(
              'Sin parcelas registradas',
              style: AppTextStyles.heading6.copyWith(color: AppColors.black2),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primera parcela para empezar a registrar tus plantas de café.',
              style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s4),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onAddParcel,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Crear parcela'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
