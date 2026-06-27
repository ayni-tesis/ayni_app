import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/animation_utils.dart';
import '../../domain/entities/pest_type.dart';
import 'pest_detail_screen.dart';

class PestCatalogScreen extends StatelessWidget {
  const PestCatalogScreen({super.key});

  IconData _getPestIcon(PestType type) {
    switch (type) {
      case PestType.roya:
        return Icons.bug_report_rounded;
      case PestType.minador:
        return Icons.linear_scale_rounded;
      case PestType.phoma:
        return Icons.coronavirus_rounded;
      case PestType.redspider:
        return Icons.pest_control_rounded;
      case PestType.healthy:
        return Icons.eco_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show all 5 types from PestType enum
    final pests = PestType.values;

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
          'Catálogo de Plagas',
          style: AppTextStyles.heading6.copyWith(color: AppColors.black2),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.s4),
          itemCount: pests.length,
          itemBuilder: (context, index) {
            final pest = pests[index];
            final pestColor = pest.color;
            final isHealthy = pest == PestType.healthy;

            return StaggeredSlideFade(
              index: index,
              child: ScaleOnTap(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PestDetailScreen(pestType: pest),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.s3),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gray5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.s3 + 4),
                      child: Row(
                        children: [
                          // Left: Icon container
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: pestColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getPestIcon(pest),
                              color: pestColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s3 + 2),
                          // Middle: Text details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pest.displayName,
                                  style: AppTextStyles.bodyBold.copyWith(
                                    color: AppColors.black2,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  pest.description,
                                  style: AppTextStyles.smallTextRegular.copyWith(
                                    color: AppColors.gray2,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                // Default severity / status label
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isHealthy
                                            ? AppColors.success.withValues(alpha: 0.1)
                                            : AppColors.error.withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isHealthy
                                            ? 'Estado: Saludable'
                                            : 'Severidad típica: ${pest.severityDefault.displayName}',
                                        style: TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isHealthy
                                              ? AppColors.success
                                              : AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Right: Arrow
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.gray4,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
