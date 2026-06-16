import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/parcel.dart';
import '../providers/crops_provider.dart';

class EditParcelScreen extends ConsumerStatefulWidget {
  final Parcel parcel;

  const EditParcelScreen({super.key, required this.parcel});

  @override
  ConsumerState<EditParcelScreen> createState() => _EditParcelScreenState();
}

class _EditParcelScreenState extends ConsumerState<EditParcelScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _farmNameController;
  late final TextEditingController _sizeController;
  late final TextEditingController _varietyController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.parcel.name);
    _farmNameController = TextEditingController(text: widget.parcel.farmName);
    _sizeController = TextEditingController(
      text: widget.parcel.sizeHectares.toString(),
    );
    _varietyController = TextEditingController(text: widget.parcel.variety ?? '');
  }

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
      final updated = widget.parcel.copyWith(
        name: _nameController.text.trim(),
        farmName: _farmNameController.text.trim(),
        sizeHectares: double.parse(_sizeController.text.trim()),
        variety: _varietyController.text.trim().isEmpty
            ? null
            : _varietyController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await ref.read(parcelsProvider.notifier).updateParcel(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Parcela actualizada'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
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
          'Editar parcela',
          style: AppTextStyles.heading6.copyWith(color: AppColors.black2),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.s4),
          children: [
            _buildLabel('Nombre de la parcela *'),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration(
                hint: 'Ej: Lote Norte',
                icon: Icons.label_outline_rounded,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Ingresa un nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.s3),

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
                  return 'Número inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.s3),

            _buildLabel('Variedad principal (opcional)'),
            TextFormField(
              controller: _varietyController,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration(
                hint: 'Ej: Bourbon, Catimor',
                icon: Icons.grass_outlined,
              ),
            ),
            const SizedBox(height: AppSpacing.s5),

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
                            'Guardar cambios',
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
