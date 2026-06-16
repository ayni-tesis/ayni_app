import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../shared/widgets/ayni_header.dart';
import '../../../../shared/widgets/ayni_bottom_nav.dart';
import '../../../diagnosis/presentation/screens/diagnosis_capture_screen.dart';
import '../../../diagnosis/presentation/screens/diagnosis_history_screen.dart';
import '../../../diagnosis/presentation/screens/diagnosis_home_screen.dart';
import '../../../diagnosis/presentation/providers/diagnosis_provider.dart';
import '../../../diagnosis/domain/entities/diagnosis.dart';
import '../../../diagnosis/domain/entities/pest_type.dart';
import '../../../crops/presentation/screens/crops_screen.dart';
import '../../../sync/presentation/screens/sync_status_screen.dart';

final _isOfflineModeProvider = StateProvider<bool>((ref) => false);

class HomeScreen extends ConsumerStatefulWidget {
  final bool isOfflineMode;
  final VoidCallback? onConnectionModeChange;
  final VoidCallback? onLogout;

  const HomeScreen({
    super.key,
    this.isOfflineMode = false,
    this.onConnectionModeChange,
    this.onLogout,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentTabIndex = 0;

  void _onCameraTap(bool isOfflineMode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DiagnosisCaptureScreen(isOfflineMode: isOfflineMode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectivityAsync = ref.watch(connectivityStreamProvider);
    final isOfflineMode = ref.watch(_isOfflineModeProvider) || widget.isOfflineMode;

    return connectivityAsync.when(
      data: (isOnline) => _buildScaffold(isOnline, isOfflineMode),
      loading: () => _buildScaffold(true, isOfflineMode),
      error: (_, __) => _buildScaffold(true, isOfflineMode),
    );
  }

  Widget _buildScaffold(bool isOnline, bool isOfflineMode) {
    final bool canDiagnoseOnline = isOnline || isOfflineMode;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AyniHeader(
        title: _currentTabIndex == 3 ? 'Account' : 'Ayni',
        showActions: _currentTabIndex != 3,
      ),
      body: _buildActiveBody(isOnline, isOfflineMode, canDiagnoseOnline),
      bottomNavigationBar: AyniBottomNav(
        currentIndex: _currentTabIndex,
        onTabSelected: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        onCameraTap: () => _onCameraTap(isOfflineMode),
      ),
    );
  }

  Widget _buildActiveBody(bool isOnline, bool isOfflineMode, bool canDiagnose) {
    switch (_currentTabIndex) {
      case 0:
        return _HomeBody(
          isOnline: isOnline,
          isOfflineMode: isOfflineMode,
          onConnectionModeChange: widget.onConnectionModeChange,
        );
      case 1:
        return DiagnosisHomeScreen(isOfflineMode: isOfflineMode);
      case 2:
        return CropsScreen(isOfflineMode: isOfflineMode);
      case 3:
        return _AccountBody(onLogout: widget.onLogout);
      default:
        return _HomeBody(
          isOnline: isOnline,
          isOfflineMode: isOfflineMode,
          onConnectionModeChange: widget.onConnectionModeChange,
        );
    }
  }
}

class _HomeBody extends StatelessWidget {
  final bool isOnline;
  final bool isOfflineMode;
  final VoidCallback? onConnectionModeChange;

  const _HomeBody({
    required this.isOnline,
    required this.isOfflineMode,
    this.onConnectionModeChange,
  });

  @override
  Widget build(BuildContext context) {
    final bool canDiagnoseOnline = isOnline || isOfflineMode;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.s2),
            if (!isOnline && !isOfflineMode) _OfflineBanner(),
            if (isOfflineMode) _OfflineModeBanner(onConnectionModeChange: onConnectionModeChange),
            if (!isOnline && !isOfflineMode) const SizedBox(height: AppSpacing.s2),
            _HomeHeader(isOfflineMode: isOfflineMode, isOnline: isOnline),
            const SizedBox(height: AppSpacing.s4),
            _DiagnoseCard(enabled: canDiagnoseOnline, isOfflineMode: isOfflineMode),
            const SizedBox(height: AppSpacing.s4),
            _CropsOverviewCard(),
            const SizedBox(height: AppSpacing.s4),
            _RecentDiagnosesSection(isOfflineMode: isOfflineMode),
            const SizedBox(height: AppSpacing.s4),
            _PlaguesSection(),
            const SizedBox(height: AppSpacing.s4),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final bool isOfflineMode;
  final bool isOnline;

  const _HomeHeader({required this.isOfflineMode, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¡Hola, Juan!',
          style: AppTextStyles.heading4.copyWith(color: AppColors.black2),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOfflineMode
                    ? AppColors.warning
                    : (isOnline ? AppColors.success : AppColors.error),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isOfflineMode
                  ? 'Modo sin conexión'
                  : (isOnline ? 'En línea' : 'Sin conexión'),
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isOfflineMode
                    ? AppColors.warning
                    : (isOnline ? AppColors.success : AppColors.error),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CropsOverviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen de mis cultivos',
          style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2),
        ),
        const SizedBox(height: AppSpacing.s2),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total',
                value: '0',
                icon: Icons.eco_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.s2),
            Expanded(
              child: _StatCard(
                label: 'Sanas',
                value: '0',
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.s2),
            Expanded(
              child: _StatCard(
                label: 'Con plaga',
                value: '0',
                icon: Icons.warning_rounded,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s2 + 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.heading5.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.smallTextRegular.copyWith(
              color: AppColors.gray2,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RecentDiagnosesSection extends ConsumerWidget {
  final bool isOfflineMode;

  const _RecentDiagnosesSection({required this.isOfflineMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(diagnosisHistoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Diagnósticos recientes',
              style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DiagnosisHistoryScreen(),
                  ),
                );
              },
              child: Text(
                'Ver todos',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s2),
        historyAsync.when(
          data: (history) {
            if (history.isEmpty) return _EmptyRecentState();
            return Column(
              children: history.take(3).map((d) => _RecentDiagnosisTile(diagnosis: d)).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.s4),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _RecentDiagnosisTile extends StatelessWidget {
  final Diagnosis diagnosis;

  const _RecentDiagnosisTile({required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    final hasInfection = diagnosis.hasInfection;
    final primaryPest = diagnosis.detectedLeaves
        .where((l) => l.diagnosedPest != null && l.diagnosedPest != PestType.healthy)
        .firstOrNull
        ?.diagnosedPest;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s1 + 4),
      padding: const EdgeInsets.all(AppSpacing.s2 + 4),
      decoration: BoxDecoration(
        color: AppColors.gray5.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray5.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hasInfection
                  ? AppColors.error.withValues(alpha: 0.1)
                  : AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasInfection ? Icons.warning_amber_rounded : Icons.eco_rounded,
              color: hasInfection ? AppColors.error : AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primaryPest?.displayName ?? 'Hoja sana',
                  style: AppTextStyles.smallTextBold.copyWith(color: AppColors.black2, fontSize: 14),
                ),
                Text(
                  '${diagnosis.detectedLeaves.length} hojas detectadas',
                  style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray3, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: hasInfection
                  ? AppColors.error.withValues(alpha: 0.1)
                  : AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              hasInfection ? 'Con plaga' : 'Sana',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: hasInfection ? AppColors.error : AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRecentState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.gray5.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.s2),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sin diagnósticos aún',
                  style: AppTextStyles.smallTextBold.copyWith(color: AppColors.black2),
                ),
                Text(
                  'Toma tu primera foto para comenzar.',
                  style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray3, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaguesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final plagues = [
      _PlagueInfo(name: 'Roya', icon: Icons.bug_report_rounded, color: const Color(0xFFD48F00), description: 'Manchas amarillas/anaranjadas en el envés de la hoja.'),
      _PlagueInfo(name: 'Araña roja', icon: Icons.pest_control_rounded, color: AppColors.error, description: 'Ácaros que tejen telarañas finas en el envés.'),
      _PlagueInfo(name: 'Phoma', icon: Icons.coronavirus_rounded, color: AppColors.gray2, description: 'Manchas oscuras y necrosis, secando los bordes.'),
      _PlagueInfo(name: 'Minador', icon: Icons.linear_scale_rounded, color: const Color(0xFF8B4513), description: 'Caminos secos transparentes en el interior de la hoja.'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enfermedades que podemos detectar',
          style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2),
        ),
        const SizedBox(height: AppSpacing.s2),
        ...plagues.map((p) => _PlagueCard(plague: p)),
      ],
    );
  }
}

class _PlagueInfo {
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  const _PlagueInfo({
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class _PlagueCard extends StatelessWidget {
  final _PlagueInfo plague;

  const _PlagueCard({required this.plague});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s1 + 4),
      padding: const EdgeInsets.all(AppSpacing.s2 + 4),
      decoration: BoxDecoration(
        color: AppColors.gray5.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray5.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: plague.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(plague.icon, color: plague.color, size: 20),
          ),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plague.name,
                  style: AppTextStyles.smallTextBold.copyWith(color: AppColors.black2, fontSize: 14),
                ),
                Text(
                  plague.description,
                  style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray3, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 18),
        ],
      ),
    );
  }
}

class _AccountBody extends ConsumerWidget {
  final VoidCallback? onLogout;

  const _AccountBody({this.onLogout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.gray5,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const ClipOval(
                    child: Icon(Icons.person, size: 56, color: AppColors.gray3),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_rounded, color: AppColors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Andrew Ainsley',
            style: AppTextStyles.heading6.copyWith(color: AppColors.black2, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'andrew.ainsley@yourdomain.com',
            style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray2),
          ),
          const SizedBox(height: AppSpacing.s3),
          _buildMenuItem(
            icon: Icons.notifications_none_rounded,
            title: 'Notificaciones',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.grass_outlined,
            title: 'Mis cultivos',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.sync_rounded,
            title: 'Sincronización',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SyncStatusScreen()),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.help_outline_rounded,
            title: 'Ayuda',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.dark_mode_outlined,
            title: 'Modo oscuro',
            trailing: Switch.adaptive(
              value: false,
              onChanged: (val) {},
              activeColor: AppColors.primary,
            ),
          ),
          _buildMenuItem(
            icon: Icons.logout_rounded,
            title: 'Cerrar sesión',
            textColor: AppColors.error,
            iconColor: AppColors.error,
            showChevron: false,
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Cerrar sesión'),
                    content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ref.read(diagnosisNotifierProvider.notifier).reset();
                          if (onLogout != null) onLogout!();
                        },
                        child: const Text('Cerrar sesión', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: AppSpacing.s6),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    Color? textColor,
    Color? iconColor,
    bool showChevron = true,
    Widget? trailing,
    String? trailingText,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(icon, color: iconColor ?? AppColors.gray2, size: 22),
          title: Text(
            title,
            style: AppTextStyles.bodyBold.copyWith(
              color: textColor ?? AppColors.black2,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          trailing: trailing ??
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (trailingText != null) ...[
                    Text(
                      trailingText,
                      style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray3, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (showChevron) const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.gray4, size: 14),
                ],
              ),
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s2 + 4,
        vertical: AppSpacing.s1 + 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 18, color: AppColors.warning),
          const SizedBox(width: AppSpacing.s1 + 4),
          Expanded(
            child: Text(
              'Sin conexión — diagnósticos guardados localmente',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.gray1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineModeBanner extends StatelessWidget {
  final VoidCallback? onConnectionModeChange;

  const _OfflineModeBanner({this.onConnectionModeChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s2 + 4,
        vertical: AppSpacing.s1 + 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 18, color: AppColors.warning),
          const SizedBox(width: AppSpacing.s1 + 4),
          Expanded(
            child: Text(
              'Modo sin conexión activo',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.gray1,
              ),
            ),
          ),
          TextButton(
            onPressed: onConnectionModeChange,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Cambiar',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnoseCard extends StatelessWidget {
  final bool enabled;
  final bool isOfflineMode;

  const _DiagnoseCard({required this.enabled, required this.isOfflineMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s3 + 4),
      decoration: BoxDecoration(
        gradient: enabled
            ? const LinearGradient(
                colors: [Color(0xFF04A033), Color(0xFF066F24)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: enabled ? null : AppColors.gray4,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.s2),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 28, color: AppColors.white),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(enabled ? Icons.wifi : Icons.cloud_off, size: 14, color: AppColors.white),
                    const SizedBox(width: 4),
                    Text(
                      enabled ? 'IA activa' : 'Sin conexión',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          const Text(
            'Diagnosticar planta',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Toma una foto de la hoja de café para detectar\nplagas y recibir recomendaciones.',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: AppColors.white.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: enabled ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DiagnosisHomeScreen(isOfflineMode: isOfflineMode),
                  ),
                );
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: enabled ? AppColors.primary : AppColors.gray3,
                disabledBackgroundColor: AppColors.white.withValues(alpha: 0.6),
                disabledForegroundColor: AppColors.gray3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Diagnosticar',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
