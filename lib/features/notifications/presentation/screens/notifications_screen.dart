import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/notification_item.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black2, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notificaciones',
          style: AppTextStyles.heading6.copyWith(
            color: AppColors.black2,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllAsRead(),
              child: Text(
                'Marcar leídas',
                style: AppTextStyles.smallTextBold.copyWith(
                  color: AppColors.primary,
                ),
              ),
            )
          else
            const IconButton(
              icon: Icon(Icons.settings_outlined, color: AppColors.black2, size: 24),
              onPressed: null,
            ),
          const SizedBox(width: AppSpacing.s2),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Text(
              'Error al cargar notificaciones: $e',
              style: AppTextStyles.bodyRegular.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) return _buildEmptyState();
          return ListView.builder(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s4, vertical: AppSpacing.s2),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];
              return _buildNotificationCard(context, ref, item);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
  ) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.s3),
        margin: const EdgeInsets.only(bottom: AppSpacing.s3),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      onDismissed: (_) =>
          ref.read(notificationsProvider.notifier).delete(item.id),
      child: GestureDetector(
        onTap: () {
          if (!item.isRead) {
            ref.read(notificationsProvider.notifier).markAsRead(item.id);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.s3),
          padding: const EdgeInsets.all(AppSpacing.s3),
          decoration: BoxDecoration(
            color: item.isRead
                ? AppColors.white
                : AppColors.secondary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead ? AppColors.gray5 : AppColors.primary.withValues(alpha: 0.15),
              width: item.isRead ? 1 : 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.s2),
                decoration: BoxDecoration(
                  color: _iconColor(item.type).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconFor(item.type),
                  color: _iconColor(item.type),
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            item.title,
                            style: AppTextStyles.bodyBold.copyWith(
                              color: AppColors.black2,
                              fontSize: 15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(item.receivedAt),
                          style: AppTextStyles.smallTextRegular.copyWith(
                            color: AppColors.gray3,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyRegular.copyWith(
                        color: AppColors.gray1,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    if (!item.isRead) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'No tienes notificaciones',
              style: AppTextStyles.mediumTextBold.copyWith(color: AppColors.black2),
            ),
            const SizedBox(height: 8),
            Text(
              'Te avisaremos cuando tus diagnósticos se sincronicen o haya nuevas alertas de plagas.',
              style: AppTextStyles.bodyRegular.copyWith(color: AppColors.gray2),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.syncCompleted:
        return Icons.sync_rounded;
      case NotificationType.pestAlert:
        return Icons.warning_rounded;
      case NotificationType.recommendation:
        return Icons.tips_and_updates_rounded;
      case NotificationType.systemUpdate:
        return Icons.system_update_alt_rounded;
      case NotificationType.diagnosisComplete:
        return Icons.check_circle_rounded;
      case NotificationType.other:
        return Icons.notifications_rounded;
    }
  }

  Color _iconColor(NotificationType type) {
    switch (type) {
      case NotificationType.syncCompleted:
        return AppColors.success;
      case NotificationType.pestAlert:
        return AppColors.warning;
      case NotificationType.recommendation:
        return AppColors.primary;
      case NotificationType.systemUpdate:
        return AppColors.gray2;
      case NotificationType.diagnosisComplete:
        return AppColors.success;
      case NotificationType.other:
        return AppColors.primary;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} d';
    return DateFormat('dd/MM/yy').format(dt);
  }
}