import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/farmer_profile.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _farmName;
  late final TextEditingController _region;
  late final TextEditingController _province;
  late final TextEditingController _district;
  late final TextEditingController _community;
  late final TextEditingController _farmSize;
  late final TextEditingController _altitude;
  late final TextEditingController _coffeeVariety;

  bool _isSaving = false;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _fullName = TextEditingController();
    _email = TextEditingController();
    _phone = TextEditingController();
    _farmName = TextEditingController();
    _region = TextEditingController();
    _province = TextEditingController();
    _district = TextEditingController();
    _community = TextEditingController();
    _farmSize = TextEditingController();
    _altitude = TextEditingController();
    _coffeeVariety = TextEditingController();
  }

  @override
  void dispose() {
    for (final c in [
      _fullName,
      _email,
      _phone,
      _farmName,
      _region,
      _province,
      _district,
      _community,
      _farmSize,
      _altitude,
      _coffeeVariety,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _seedFromProfile(FarmerProfile profile) {
    if (_seeded) return;
    _seeded = true;
    _fullName.text = profile.fullName;
    _email.text = profile.email;
    _phone.text = profile.phone ?? '';
    _farmName.text = profile.farmName ?? '';
    _region.text = profile.region ?? '';
    _province.text = profile.province ?? '';
    _district.text = profile.district ?? '';
    _community.text = profile.communityName ?? '';
    _farmSize.text =
        profile.farmSizeHectares?.toStringAsFixed(2) ?? '';
    _altitude.text =
        profile.altitudeMeters?.toStringAsFixed(0) ?? '';
    _coffeeVariety.text = profile.coffeeVariety ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final profile = FarmerProfile(
      fullName: _fullName.text.trim(),
      email: _email.text.trim(),
      phone: _nullIfBlank(_phone.text),
      farmName: _nullIfBlank(_farmName.text),
      region: _nullIfBlank(_region.text),
      province: _nullIfBlank(_province.text),
      district: _nullIfBlank(_district.text),
      communityName: _nullIfBlank(_community.text),
      farmSizeHectares: _tryParseDouble(_farmSize.text),
      altitudeMeters: _tryParseDouble(_altitude.text),
      coffeeVariety: _nullIfBlank(_coffeeVariety.text),
      updatedAt: DateTime.now(),
    );

    final ok = await ref.read(profileNotifierProvider.notifier).save(profile);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar el perfil. Inténtalo de nuevo.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String? _nullIfBlank(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  double? _tryParseDouble(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: AppColors.black2, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Editar perfil',
          style: AppTextStyles.heading6.copyWith(color: AppColors.black2),
        ),
        centerTitle: true,
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
          if (profile != null) _seedFromProfile(profile);
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Datos personales'),
                  _buildField(
                      controller: _fullName,
                      label: 'Nombre completo',
                      icon: Icons.person_outline,
                      required: true),
                  _buildField(
                      controller: _email,
                      label: 'Correo electrónico',
                      icon: Icons.email_outlined,
                      required: true,
                      keyboardType: TextInputType.emailAddress),
                  _buildField(
                      controller: _phone,
                      label: 'Teléfono',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: AppSpacing.s3),
                  _buildSectionTitle('Finca'),
                  _buildField(
                      controller: _farmName,
                      label: 'Nombre de la finca',
                      icon: Icons.eco_outlined),
                  _buildField(
                      controller: _region,
                      label: 'Región',
                      icon: Icons.map_outlined),
                  _buildField(
                      controller: _province,
                      label: 'Provincia',
                      icon: Icons.location_city_outlined),
                  _buildField(
                      controller: _district,
                      label: 'Distrito',
                      icon: Icons.location_on_outlined),
                  _buildField(
                      controller: _community,
                      label: 'Comunidad',
                      icon: Icons.groups_outlined),
                  _buildField(
                      controller: _farmSize,
                      label: 'Tamaño de la finca (ha)',
                      icon: Icons.straighten,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true)),
                  _buildField(
                      controller: _altitude,
                      label: 'Altitud (msnm)',
                      icon: Icons.terrain_outlined,
                      keyboardType: TextInputType.number),
                  _buildField(
                      controller: _coffeeVariety,
                      label: 'Variedad de café',
                      icon: Icons.local_florist_outlined),
                  const SizedBox(height: AppSpacing.s4),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.white),
                              ),
                            )
                          : Text(
                              'Guardar cambios',
                              style: AppTextStyles.bodyBold
                                  .copyWith(color: AppColors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.s2, bottom: AppSpacing.s2),
        child: Text(
          text,
          style: AppTextStyles.mediumTextBold.copyWith(color: AppColors.black2),
        ),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s2),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: AppTextStyles.bodyRegular.copyWith(color: AppColors.black2),
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          prefixIcon: Icon(icon, color: AppColors.gray3, size: 20),
          filled: true,
          fillColor: AppColors.gray5.withValues(alpha: 0.4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: required
            ? (value) => (value == null || value.trim().isEmpty)
                ? 'Este campo es obligatorio.'
                : null
            : null,
      ),
    );
  }
}