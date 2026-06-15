import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class AyniBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final VoidCallback onCameraTap;

  const AyniBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCameraTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s2,
            vertical: AppSpacing.s1 + 2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Home
              _buildNavItem(
                index: 0,
                icon: Icons.home_filled,
                inactiveIcon: Icons.home_outlined,
                label: 'Home',
              ),
              // 2. Diagnose
              _buildNavItem(
                index: 1,
                icon: Icons.shield_rounded,
                inactiveIcon: Icons.shield_outlined,
                label: 'Diagnose',
                onCustomTap: onCameraTap, // Tapping Diagnose tab directly opens camera flow
              ),
              // 3. Center Camera Floating Button
              _buildCenterCameraButton(),
              // 4. My Plants
              _buildNavItem(
                index: 2,
                icon: Icons.eco,
                inactiveIcon: Icons.eco_outlined, // Pot representation / eco pot
                label: 'My Plants',
              ),
              // 5. Account
              _buildNavItem(
                index: 3,
                icon: Icons.person,
                inactiveIcon: Icons.person_outline,
                label: 'Account',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData inactiveIcon,
    required String label,
    VoidCallback? onCustomTap,
  }) {
    // Offset index since center button is inserted and not in tabs index
    final bool isActive = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: onCustomTap ?? () => onTabSelected(index),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 48, // Accessible tap target size
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? icon : inactiveIcon,
                size: 24,
                color: isActive ? AppColors.primary : AppColors.gray3,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? AppColors.primary : AppColors.gray3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterCameraButton() {
    return GestureDetector(
      onTap: onCameraTap,
      child: Container(
        width: 56,
        height: 56, // Accessible tap target size >= 48dp
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.camera_alt_rounded,
            color: AppColors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
