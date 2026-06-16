import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/crop.dart';
import '../providers/crops_provider.dart';

class AddCropScreen extends ConsumerStatefulWidget {
  final String parcelId;
  final bool isOfflineMode;

  const AddCropScreen({
    super.key,
    required this.parcelId,
    this.isOfflineMode = false,
  });

  @override
  ConsumerState<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends ConsumerState<AddCropScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _plantCountController = TextEditingController(text: '1');
  CoffeeVariety _selectedVariety = CoffeeVariety.bourbon;
  DateTime? _plantingDate;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _plantCountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      // For simplicity, create one Crop per entry.
      // A batch version can be added later.
      final count = int.tryParse(_plantCountController.text.trim()) ?? 1;

      for (int i = 0; i < count; i++) {
        final crop = Crop(
          id: 'crop_${DateTime.now().microsecondsSinceEpoch}_$i',
          parcelId: widget.parcelId,
          name: count > 1
              ? '${_nameController.text.trim()} ${i + 1}'
              : _nameController.text.trim(),
          variety: _selectedVariety,
          plantingDate: _plantingDate,
          status: PlantStatus.healthy,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await ref.read(cropsProvider.notifier).addCrop(crop);
      }

      // Refresh parcels so plant count updates
      ref.read(parcelsProvider.notifier).loadParcels();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              count > 1 ? '$count plantas registradas' : 'Planta registrada',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.black2,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _plantingDate = date);
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
          'Agregar planta',
          style: AppTextStyles.heading6.copyWith(color: AppColors.black2),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.s4),
          children: [
            // Name
            _buildLabel('Nombre o identificación *'),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration(
                hint: 'Ej: Cafeto Lote 1, Árbol A-12',
                icon: Icons.eco_outlined,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Ingresa un nombre para la planta';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.s3),

            // Batch count (optional)
            _buildLabel('Cantidad a registrar (opcional)'),
            TextFormField(
              controller: _plantCountController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(
                hint: '1',
                icon: Icons.format_list_numbered_rounded,
              ),
            ),
            const SizedBox(height: AppSpacing.s3),

            // Variety selector
            _buildLabel('Variedad de café *'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gray5.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray5),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CoffeeVariety>(
                  value: _selectedVariety,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.gray3),
                  items: CoffeeVariety.values.map((v) {
                    return DropdownMenuItem(
                      value: v,
                      child: Text(
                        v.displayName,
                        style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedVariety = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s3),

            // Planting date
            _buildLabel('Fecha de siembra (opcional)'),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.gray5.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gray5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: AppColors.gray3),
                    const SizedBox(width: 12),
                    Text(
                      _plantingDate != null
                          ? '${_plantingDate!.day}/${_plantingDate!.month}/${_plantingDate!.year}'
                          : 'Seleccionar fecha',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: _plantingDate != null
                            ? AppColors.black2
                            : AppColors.gray3,
                      ),
                    ),
                    const Spacer(),
                    if (_plantingDate != null)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: AppColors.gray3,
                        onPressed: () => setState(() => _plantingDate = null),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
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
                            'Registrar planta',
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
