import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s2,
        vertical: AppSpacing.s1 + 4,
      ),
      decoration: const BoxDecoration(
        color: AppColors.warning,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 18,
            color: AppColors.black2,
          ),
          const SizedBox(width: AppSpacing.s1 + 4),
          Text(
            'Sin conexión — diagnósticos guardados localmente',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.black2,
            ),
          ),
        ],
      ),
    );
  }
}
