import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock notifications list targeted for Villa Rica coffee growers
    final List<NotificationItem> notifications = [
      NotificationItem(
        id: '1',
        title: 'Sincronización Completada',
        description: 'Se han sincronizado con éxito 3 diagnósticos locales que tenías pendientes.',
        time: 'Hace 5 min',
        icon: Icons.sync_rounded,
        iconColor: AppColors.success,
        isRead: false,
      ),
      NotificationItem(
        id: '2',
        title: 'Alerta Preventiva de Roya',
        description: 'La humedad y lluvias en Villa Rica aumentan la probabilidad de brotes de Roya. Monitorea tus plantas.',
        time: 'Hace 2 horas',
        icon: Icons.warning_rounded,
        iconColor: AppColors.warning,
        isRead: false,
      ),
      NotificationItem(
        id: '3',
        title: 'Recomendación de Cultivo',
        description: 'La poda de ramas bajas mejora el flujo de aire y reduce la acumulación de humedad en las hojas.',
        time: 'Ayer',
        icon: Icons.tips_and_updates_rounded,
        iconColor: AppColors.primary,
        isRead: true,
      ),
      NotificationItem(
        id: '4',
        title: 'Sistema Actualizado',
        description: 'Tu modelo local de YOLO y clasificación se ha actualizado a la versión v1.4.',
        time: 'Hace 3 días',
        icon: Icons.system_update_alt_rounded,
        iconColor: AppColors.gray2,
        isRead: true,
      ),
    ];

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
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.black2, size: 24),
            onPressed: () {},
          ),
          const SizedBox(width: AppSpacing.s2),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s2),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                return _buildNotificationCard(item);
              },
            ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s3),
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: item.isRead ? AppColors.white : AppColors.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isRead ? AppColors.gray5 : AppColors.primary.withValues(alpha: 0.15),
          width: item.isRead ? 1 : 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon indicator
          Container(
            padding: const EdgeInsets.all(AppSpacing.s2),
            decoration: BoxDecoration(
              color: item.iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.iconColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.s3),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.title,
                      style: AppTextStyles.bodyBold.copyWith(
                        color: AppColors.black2,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      item.time,
                      style: AppTextStyles.smallTextRegular.copyWith(
                        color: AppColors.gray3,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: AppTextStyles.bodyRegular.copyWith(
                    color: AppColors.gray1,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
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
}

class NotificationItem {
  final String id;
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color iconColor;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.isRead,
  });
}
