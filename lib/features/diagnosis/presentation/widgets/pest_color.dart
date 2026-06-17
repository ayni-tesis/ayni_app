import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/pest_type.dart';

/// Returns the color used for a bounding box outline and label background
/// based on the detected pest type.
Color getPestBoxColor(PestType? pest) {
  switch (pest) {
    case PestType.roya:
      return AppColors.error;
    case PestType.minador:
      return const Color(0xFFD48F00);
    case PestType.phoma:
      return AppColors.gray1;
    case PestType.healthy:
      return AppColors.success;
    case PestType.redspider:
      return const Color(0xFF8B0000);
    case null:
      return AppColors.gray3;
  }
}

/// Returns the fill color (with alpha) used for the area inside the bounding box.
Color getPestBoxFillColor(PestType? pest) {
  return getPestBoxColor(pest).withValues(alpha: 0.12);
}

/// Returns a display name suitable for a bounding box label.
String getPestBoxLabel(PestType? pest) {
  return pest?.displayName ?? 'Desconocido';
}