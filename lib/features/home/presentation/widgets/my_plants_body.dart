import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../diagnosis/domain/entities/pest_type.dart';
import '../../../diagnosis/presentation/screens/diagnosis_capture_screen.dart';

class MockPlant {
  final String id;
  final String name;
  final String variety;
  final String location;
  final PestType healthStatus;
  final String lastCheck;
  final String severity;

  const MockPlant({
    required this.id,
    required this.name,
    required this.variety,
    required this.location,
    required this.healthStatus,
    required this.lastCheck,
    required this.severity,
  });
}

class MyPlantsBody extends ConsumerStatefulWidget {
  final bool isOfflineMode;

  const MyPlantsBody({
    super.key,
    required this.isOfflineMode,
  });

  @override
  ConsumerState<MyPlantsBody> createState() => _MyPlantsBodyState();
}

class _MyPlantsBodyState extends ConsumerState<MyPlantsBody> {
  String _searchQuery = '';
  String _selectedFilter = 'Todas'; // 'Todas', 'Sanas', 'Enfermas'
  final TextEditingController _searchController = TextEditingController();

  final List<MockPlant> _mockPlants = const [
    MockPlant(
      id: 'p1',
      name: 'Cafeto Bourbon Lote 1',
      variety: 'Bourbon',
      location: 'Finca La Esperanza',
      healthStatus: PestType.roya,
      severity: 'Media',
      lastCheck: 'Hace 2 días',
    ),
    MockPlant(
      id: 'p2',
      name: 'Cafeto Catimor Lote Norte',
      variety: 'Catimor',
      location: 'Finca Santa Teresa',
      healthStatus: PestType.healthy,
      severity: 'Ninguna',
      lastCheck: 'Hace 4 horas',
    ),
    MockPlant(
      id: 'p3',
      name: 'Cafeto Typica Lote 3',
      variety: 'Typica',
      location: 'Sector Bajo Sombra',
      healthStatus: PestType.minador,
      severity: 'Baja',
      lastCheck: 'Hace 1 día',
    ),
    MockPlant(
      id: 'p4',
      name: 'Cafeto Geisha Alta Vista',
      variety: 'Geisha',
      location: 'Lote Superior Villa Rica',
      healthStatus: PestType.phoma,
      severity: 'Alta',
      lastCheck: 'Hace 3 días',
    ),
    MockPlant(
      id: 'p5',
      name: 'Cafeto Bourbon Jóvenes',
      variety: 'Bourbon',
      location: 'Vivero Esperanza',
      healthStatus: PestType.healthy,
      severity: 'Ninguna',
      lastCheck: 'Hace 5 días',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(PestType type) {
    switch (type) {
      case PestType.healthy:
        return AppColors.success;
      case PestType.roya:
        return AppColors.error;
      case PestType.minador:
        return const Color(0xFFD48F00);
      case PestType.phoma:
        return AppColors.gray2;
      case PestType.redspider:
        return AppColors.error;
    }
  }

  List<MockPlant> get _filteredPlants {
    return _mockPlants.where((plant) {
      // 1. Search Query filter
      final matchesSearch = plant.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          plant.variety.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          plant.location.toLowerCase().contains(_searchQuery.toLowerCase());

      // 2. Chip Filter
      bool matchesChip = true;
      if (_selectedFilter == 'Sanas') {
        matchesChip = plant.healthStatus == PestType.healthy;
      } else if (_selectedFilter == 'Enfermas') {
        matchesChip = plant.healthStatus != PestType.healthy;
      }

      return matchesSearch && matchesChip;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final plantsToShow = _filteredPlants;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.s2),
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.gray5.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gray5),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Buscar planta, variedad o lote...',
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.gray3),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Todas', 'Sanas', 'Enfermas'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    selectedColor: AppColors.secondary,
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.primary : AppColors.gray1,
                    ),
                    backgroundColor: AppColors.white,
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.gray4,
                        width: 1.2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          // Title count
          Text(
            'Mis Cafetos (${plantsToShow.length})',
            style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2),
          ),
          const SizedBox(height: 10),
          // Plants List
          Expanded(
            child: plantsToShow.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: plantsToShow.length,
                    itemBuilder: (context, index) {
                      final plant = plantsToShow[index];
                      return _buildPlantCard(plant);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.s3),
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco_outlined,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'No se encontraron plantas',
            style: AppTextStyles.mediumTextBold.copyWith(color: AppColors.black2),
          ),
          const SizedBox(height: 8),
          Text(
            'Prueba buscando con otros términos o cambia el filtro de estado.',
            style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray2),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlantCard(MockPlant plant) {
    final statusColor = _getStatusColor(plant.healthStatus);
    final isHealthy = plant.healthStatus == PestType.healthy;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s2),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.gray5),
      ),
      child: InkWell(
        onTap: () => _showPlantDetailSheet(plant),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s3),
          child: Row(
            children: [
              // Left side: Icon or Thumbnail representation
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isHealthy ? AppColors.secondary : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isHealthy ? Icons.eco_rounded : Icons.warning_amber_rounded,
                  color: isHealthy ? AppColors.primary : AppColors.error,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              // Center: Text details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.name,
                      style: AppTextStyles.bodyBold.copyWith(
                        color: AppColors.black2,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${plant.variety} • ${plant.location}',
                      style: AppTextStyles.smallTextRegular.copyWith(
                        color: AppColors.gray2,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Último análisis: ${plant.lastCheck}',
                      style: AppTextStyles.smallTextRegular.copyWith(
                        color: AppColors.gray3,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Right side: Health Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      plant.healthStatus.displayName,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                  if (!isHealthy) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Severidad: ${plant.severity}',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlantDetailSheet(MockPlant plant) {
    final statusColor = _getStatusColor(plant.healthStatus);
    final isHealthy = plant.healthStatus == PestType.healthy;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grab handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.gray4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  // Plant Header Details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plant.name,
                              style: AppTextStyles.heading5.copyWith(color: AppColors.black2),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Variedad: ${plant.variety} | Lote: ${plant.location}',
                              style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray2),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          plant.healthStatus.displayName,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  // Current Health Status Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.s3),
                    decoration: BoxDecoration(
                      color: isHealthy ? AppColors.secondary.withValues(alpha: 0.4) : AppColors.error.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isHealthy ? AppColors.primary.withValues(alpha: 0.2) : AppColors.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHealthy ? 'Planta Saludable' : 'Infección Detectada',
                          style: AppTextStyles.bodyBold.copyWith(
                            color: isHealthy ? AppColors.primary : AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          plant.healthStatus.description,
                          style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray1),
                        ),
                        if (!isHealthy) ...[
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray1),
                              children: [
                                const TextSpan(
                                  text: 'Severidad: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: plant.severity,
                                  style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  // Treatment Recommendations Section
                  Text(
                    'Recomendaciones de Cuidado',
                    style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.s3),
                    decoration: BoxDecoration(
                      color: AppColors.gray5.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gray5),
                    ),
                    child: Text(
                      plant.healthStatus.treatmentRecommendation,
                      style: AppTextStyles.smallTextRegular.copyWith(
                        color: AppColors.gray1,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s5),
                  // Diagnose Again Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // close bottom sheet
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => DiagnosisCaptureScreen(
                              isOfflineMode: widget.isOfflineMode,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt_rounded),
                          const SizedBox(width: 8),
                          Text(
                            'Volver a Diagnosticar',
                            style: AppTextStyles.bodyBold.copyWith(color: AppColors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
