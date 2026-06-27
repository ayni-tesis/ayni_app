import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class SeverityIndicator extends StatelessWidget {
  final double severity;

  const SeverityIndicator({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    final double clampedSeverity = severity.clamp(0.0, 1.0);

    String label;
    Color color;
    int activeSegments;

    if (clampedSeverity < 0.25) {
      label = 'Leve';
      color = const Color(0xFF66BB6A); // Green / Success
      activeSegments = 1;
    } else if (clampedSeverity < 0.50) {
      label = 'Moderada';
      color = const Color(0xFFFFA726); // Amber / Warning
      activeSegments = 2;
    } else if (clampedSeverity < 0.75) {
      label = 'Alta';
      color = const Color(0xFFFB8C00); // Orange
      activeSegments = 3;
    } else {
      label = 'Crítica';
      color = const Color(0xFFEF5350); // Red / Error
      activeSegments = 4;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                'Severidad de la infección:',
                style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray2),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$label (${(clampedSeverity * 100).toStringAsFixed(1)}%)',
              style: AppTextStyles.smallTextBold.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(4, (index) {
            final isSegmentActive = index < activeSegments;
            Color segmentColor;
            if (isSegmentActive) {
              segmentColor = color;
            } else {
              segmentColor = AppColors.gray5;
            }

            return Expanded(
              child: Container(
                height: 8,
                margin: EdgeInsets.only(
                  right: index < 3 ? 4.0 : 0.0,
                ),
                decoration: BoxDecoration(
                  color: segmentColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
