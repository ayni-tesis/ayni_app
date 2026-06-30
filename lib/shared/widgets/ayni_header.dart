import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../../features/notifications/presentation/screens/notifications_screen.dart';
import 'ayni_logo.dart';

class AyniHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showActions;
  final bool hasNotifications;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onBookmarkTap;

  const AyniHeader({
    super.key,
    this.title = 'Ayni',
    this.showActions = true,
    this.hasNotifications = true,
    this.onNotificationTap,
    this.onBookmarkTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s1 + 2,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Left: Brand mark
            const AyniLogo(
              size: 28,
              fill: AppColors.primary,
              veinColor: AppColors.secondary,
            ),
            const Spacer(),
            // Center: App Title
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.black2,
              ),
            ),
            const Spacer(),
            if (showActions) ...[
              // Right: Notification outlined button
              _buildRoundIconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.black2,
                      size: 24,
                    ),
                    if (hasNotifications)
                      Positioned(
                        top: 1,
                        right: 1,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                onTap: onNotificationTap ?? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: AppSpacing.s2),
              // Right: Bookmark outlined button
              _buildRoundIconButton(
                icon: const Icon(
                  Icons.bookmark_border_rounded,
                  color: AppColors.black2,
                  size: 24,
                ),
                onTap: onBookmarkTap ?? () {},
              ),
            ] else ...[
              // Empty space to balance brand leaf logo (32dp) on the left
              const SizedBox(width: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoundIconButton({
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 48,
      height: 48, // Accessible tap target size >= 48dp
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.gray5,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Center(child: icon),
      ),
    );
  }
}
