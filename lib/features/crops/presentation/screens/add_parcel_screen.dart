import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/parcel.dart';
import '../providers/crops_provider.dart';

class AddParcelScreen extends ConsumerStatefulWidget {
  final bool isOfflineMode;

  const AddParcelScreen({super.key, this.isOfflineMode = false});

  @override
  ConsumerState<AddParcelScreen> createState() => _AddParcelScreenState();
}

class _AddParcelScreenState extends ConsumerState<AddParcelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _farmNameController = TextEditingController();
  final _sizeController = TextEditingController();
  final _varietyController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _farmNameController.dispose();
    _sizeController.dispose();
    _varietyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final parcel = Parcel(
        id: 'parcel_${DateTime.now().microsecondsSinceEpoch}',
        name: _nameController.text.trim(),
        farmName: _farmNameController.text.trim(),
        sizeHectares: double.parse(_sizeController.text.trim()),
        variety: _varietyController.text.trim().isEmpty
            ? null
            : _varietyController.text.trim(),
        plantCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(parcelsProvider.notifier).addParcel(parcel);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Parcela creada exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.black2),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Nueva parcela',
          style: AppTextStyles.heading6.copyWith(color: AppColors.black2),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.s4),
          children: [
            // Header illustration
            Container(
              padding: const EdgeInsets.all(AppSpacing.s4),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.s2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registrar parcela',
                          style: AppTextStyles.bodyBold.copyWith(
                            color: AppColors.black2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Divide tu finca en parcelas para un mejor seguimiento.',
                          style: AppTextStyles.smallTextRegular.copyWith(
                            color: AppColors.gray2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s4),

            // Name
            _buildLabel('Nombre de la parcela *'),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration(
                hint: 'Ej: Lote Norte, Parcela Alta',
                icon: Icons.label_outline_rounded,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Ingresa un nombre para la parcela';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.s3),

            // Farm name
            _buildLabel('Nombre de la finca *'),
            TextFormField(
              controller: _farmNameController,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration(
                hint: 'Ej: Finca La Esperanza',
                icon: Icons.home_outlined,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Ingresa el nombre de la finca';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.s3),

            // Size
            _buildLabel('Tamaño (hectáreas) *'),
            TextFormField(
              controller: _sizeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDecoration(
                hint: 'Ej: 2.5',
                icon: Icons.straighten_rounded,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Ingresa el tamaño';
                }
                final size = double.tryParse(v.trim());
                if (size == null || size <= 0) {
                  return 'Ingresa un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.s3),

            // Variety
            _buildLabel('Variedad principal (opcional)'),
            TextFormField(
              controller: _varietyController,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration(
                hint: 'Ej: Bourbon, Catimor, Geisha',
                icon: Icons.grass_outlined,
              ),
            ),
            const SizedBox(height: AppSpacing.s5),

            // Save button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_rounded),
                          const SizedBox(width: 8),
                          Text(
                            'Crear parcela',
                            style: AppTextStyles.bodyBold.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.smallTextBold.copyWith(color: AppColors.black2),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.gray4),
      prefixIcon: Icon(icon, color: AppColors.gray3),
      filled: true,
      fillColor: AppColors.gray5.withValues(alpha: 0.4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gray5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
