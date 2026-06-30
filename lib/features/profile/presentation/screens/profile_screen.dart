import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/profile_provider.dart';
import '../widgets/version_widgets.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black2, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Mi perfil',
          style: AppTextStyles.heading6.copyWith(color: AppColors.black2),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const EditProfileScreen(),
              ),
            ),
            child: Text(
              'Editar',
              style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.s1),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error al cargar el perfil: $e',
            style: AppTextStyles.bodyRegular.copyWith(color: AppColors.error),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return _buildEmptyState(context);
          }
          return ListView(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
            children: [
              _buildHeader(context, profile.fullName, profile.email),
              const SizedBox(height: AppSpacing.s4),
              _buildSection(
                title: 'Contacto',
                items: [
                  _Item('Teléfono', profile.phone ?? '—'),
                  _Item('Correo', profile.email),
                ],
              ),
              _buildSection(
                title: 'Finca',
                items: [
                  _Item('Nombre de la finca', profile.farmName ?? '—'),
                  _Item('Variedad de café', profile.coffeeVariety ?? '—'),
                  _Item(
                    'Tamaño',
                    profile.farmSizeHectares != null
                        ? '${profile.farmSizeHectares!.toStringAsFixed(2)} ha'
                        : '—',
                  ),
                  _Item(
                    'Altitud',
                    profile.altitudeMeters != null
                        ? '${profile.altitudeMeters!.toStringAsFixed(0)} msnm'
                        : '—',
                  ),
                ],
              ),
              _buildSection(
                title: 'Ubicación',
                items: [
                  _Item('Región', profile.region ?? '—'),
                  _Item('Provincia', profile.province ?? '—'),
                  _Item('Distrito', profile.district ?? '—'),
                  _Item('Comunidad', profile.communityName ?? '—'),
                ],
              ),
              const SizedBox(height: AppSpacing.s2),
              const VersionCard(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, String email) {
    return Column(
      children: [
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.person, size: 56, color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          name,
          style: AppTextStyles.heading6
              .copyWith(color: AppColors.black2, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray2),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
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
              child: const Icon(Icons.person_add_alt_1,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.s3),
            Text(
              'Aún no has completado tu perfil',
              style: AppTextStyles.mediumTextBold
                  .copyWith(color: AppColors.black2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Cuéntanos sobre ti y tu finca para recibir recomendaciones más útiles.',
              style: AppTextStyles.bodyRegular.copyWith(color: AppColors.gray2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s3),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              ),
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Completar perfil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<_Item> items}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.gray5.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(AppSpacing.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2),
            ),
            const SizedBox(height: AppSpacing.s2),
            for (final item in items) _buildItemRow(item),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(_Item item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              item.label,
              style:
                  AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray2),
            ),
          ),
          Expanded(
            child: Text(
              item.value,
              style:
                  AppTextStyles.bodyRegular.copyWith(color: AppColors.gray1),
            ),
          ),
        ],
      ),
    );
  }
}

class _Item {
  final String label;
  final String value;
  const _Item(this.label, this.value);
}