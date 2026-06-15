import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _nunitoBase => GoogleFonts.nunito();

  // Headings
  static TextStyle get heading1 => _nunitoBase.copyWith(
        fontSize: 56,
        height: 61.6 / 56,
        fontWeight: FontWeight.w700,
        color: AppColors.black2,
      );

  static TextStyle get heading2 => _nunitoBase.copyWith(
        fontSize: 48,
        height: 52.8 / 48,
        fontWeight: FontWeight.w700,
        color: AppColors.black2,
      );

  static TextStyle get heading3 => _nunitoBase.copyWith(
        fontSize: 40,
        height: 44 / 40,
        fontWeight: FontWeight.w700,
        color: AppColors.black2,
      );

  static TextStyle get heading4 => _nunitoBase.copyWith(
        fontSize: 32,
        height: 35.2 / 32,
        fontWeight: FontWeight.w700,
        color: AppColors.black2,
      );

  static TextStyle get heading5 => _nunitoBase.copyWith(
        fontSize: 24,
        height: 26.4 / 24,
        fontWeight: FontWeight.w700,
        color: AppColors.black2,
      );

  static TextStyle get heading6 => _nunitoBase.copyWith(
        fontSize: 20,
        height: 22 / 20,
        fontWeight: FontWeight.w700,
        color: AppColors.black2,
      );

  // Large Text
  static TextStyle get largeTextBold => _nunitoBase.copyWith(
        fontSize: 20,
        height: 28 / 20,
        fontWeight: FontWeight.w700,
        color: AppColors.gray1,
      );

  static TextStyle get largeTextRegular => _nunitoBase.copyWith(
        fontSize: 20,
        height: 28 / 20,
        fontWeight: FontWeight.w400,
        color: AppColors.gray1,
      );

  // Medium Text
  static TextStyle get mediumTextBold => _nunitoBase.copyWith(
        fontSize: 18,
        height: 25.2 / 18,
        fontWeight: FontWeight.w700,
        color: AppColors.gray1,
      );

  static TextStyle get mediumTextRegular => _nunitoBase.copyWith(
        fontSize: 18,
        height: 25.2 / 18,
        fontWeight: FontWeight.w400,
        color: AppColors.gray1,
      );

  // Body Text
  static TextStyle get bodyBold => _nunitoBase.copyWith(
        fontSize: 16,
        height: 22.4 / 16,
        fontWeight: FontWeight.w700,
        color: AppColors.gray1,
      );

  static TextStyle get bodyRegular => _nunitoBase.copyWith(
        fontSize: 16,
        height: 22.4 / 16,
        fontWeight: FontWeight.w400,
        color: AppColors.gray1,
      );

  // Small Text
  static TextStyle get smallTextBold => _nunitoBase.copyWith(
        fontSize: 14,
        height: 19.6 / 14,
        fontWeight: FontWeight.w700,
        color: AppColors.gray2,
      );

  static TextStyle get smallTextRegular => _nunitoBase.copyWith(
        fontSize: 14,
        height: 19.6 / 14,
        fontWeight: FontWeight.w400,
        color: AppColors.gray2,
      );
}
