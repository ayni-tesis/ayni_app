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
import '../../../diagnosis/presentation/providers/diagnosis_provider.dart';
import '../../../diagnosis/domain/entities/pest_type.dart';
import '../widgets/my_plants_body.dart';

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
      case 2:
        return MyPlantsBody(isOfflineMode: isOfflineMode);
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
            // Offline banner
            if (!isOnline && !isOfflineMode) _OfflineBanner(),
            if (isOfflineMode) _OfflineModeBanner(onConnectionModeChange: onConnectionModeChange),
            const SizedBox(height: AppSpacing.s3),
            // Header greeting (Simple for farm dashboard)
            _buildGreeting(),
            const SizedBox(height: AppSpacing.s4),
            // Main diagnose card
            _DiagnoseCard(enabled: canDiagnoseOnline, isOfflineMode: isOfflineMode),
            const SizedBox(height: AppSpacing.s3),
            // Feature cards grid
            _FeatureCardsGrid(isOnline: canDiagnoseOnline, isOfflineMode: isOfflineMode),
            const SizedBox(height: AppSpacing.s4),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¡Hola, Juan!',
          style: AppTextStyles.heading5.copyWith(color: AppColors.black2),
        ),
        const SizedBox(height: 4),
        Text(
          isOfflineMode
              ? 'Modo sin conexión'
              : (isOnline ? 'Conectado' : 'Sin conexión'),
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
          // Profile Picture and Edit Icon
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
                    child: Icon(
                      Icons.person,
                      size: 56,
                      color: AppColors.gray3,
                    ),
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
                    child: const Icon(
                      Icons.edit_rounded,
                      color: AppColors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          // Name
          Text(
            'Andrew Ainsley',
            style: AppTextStyles.heading6.copyWith(
              color: AppColors.black2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          // Email
          Text(
            'andrew.ainsley@yourdomain.com',
            style: AppTextStyles.smallTextRegular.copyWith(
              color: AppColors.gray2,
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          
          // Green Upgrade Plan Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.s3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF27AE60)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.s2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upgrade Plan to Unlock More!',
                        style: AppTextStyles.bodyBold.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Get access to advanced AI diagnostic tools.',
                        style: AppTextStyles.smallTextRegular.copyWith(
                          color: AppColors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.white,
                  size: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s4),

          // Menu Items
          _buildMenuItem(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.security_rounded,
            title: 'Account & Security',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.receipt_long_rounded,
            title: 'Billing',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.payment_rounded,
            title: 'Payments',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.language_rounded,
            title: 'Language',
            trailingText: 'Español',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            trailing: Switch.adaptive(
              value: false,
              onChanged: (val) {},
              activeColor: AppColors.primary,
            ),
          ),
          _buildMenuItem(
            icon: Icons.help_outline_rounded,
            title: 'Help Center',
            onTap: () {},
          ),
          // Logout item - styled in Red
          _buildMenuItem(
            icon: Icons.logout_rounded,
            title: 'Logout',
            textColor: AppColors.error,
            iconColor: AppColors.error,
            showChevron: false,
            onTap: () {
              // Show a nice logout dialog
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text('Cerrar sesión'),
                    content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // pop dialog
                          ref.read(diagnosisNotifierProvider.notifier).reset();
                          if (onLogout != null) {
                            onLogout!();
                          }
                        },
                        child: const Text(
                          'Cerrar sesión',
                          style: TextStyle(color: AppColors.error),
                        ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: Icon(
            icon,
            color: iconColor ?? AppColors.gray2,
            size: 22,
          ),
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
                      style: AppTextStyles.smallTextRegular.copyWith(
                        color: AppColors.gray3,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (showChevron)
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.gray4,
                      size: 14,
                    ),
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
                    Icon(
                      enabled ? Icons.wifi : Icons.cloud_off,
                      size: 14,
                      color: AppColors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      enabled ? 'IA activa' : 'Sin conexión',
                      style: TextStyle(
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
          Text(
            'Check Your Plant',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Take photos, start diagnose diseases\n& get plant care tips',
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
                    builder: (context) => DiagnosisCaptureScreen(isOfflineMode: isOfflineMode),
                  ),
                );
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: enabled ? AppColors.primary : AppColors.gray3,
                disabledBackgroundColor: AppColors.white.withValues(alpha: 0.6),
                disabledForegroundColor: AppColors.gray3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Diagnose',
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

class _FeatureCardsGrid extends StatelessWidget {
  final bool isOnline;
  final bool isOfflineMode;

  const _FeatureCardsGrid({required this.isOnline, required this.isOfflineMode});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enfermedades Comunes',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.black2,
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        SizedBox(
          height: 130,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _DiseaseCard(
                label: 'Roya',
                color: const Color(0xFFFFEBEE),
                icon: Icons.bug_report_rounded,
                iconColor: AppColors.error,
                onTap: () => _showPestDetailSheet(context, PestType.roya),
              ),
              const SizedBox(width: AppSpacing.s2),
              _DiseaseCard(
                label: 'Minador',
                color: const Color(0xFFFFF3E0),
                icon: Icons.pest_control_rounded,
                iconColor: const Color(0xFFD48F00),
                onTap: () => _showPestDetailSheet(context, PestType.minador),
              ),
              const SizedBox(width: AppSpacing.s2),
              _DiseaseCard(
                label: 'Phoma',
                color: const Color(0xFFF5F5F5),
                icon: Icons.coronavirus_rounded,
                iconColor: AppColors.gray2,
                onTap: () => _showPestDetailSheet(context, PestType.phoma),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        // Secondary actions
        _SecondaryActionRow(isOnline: isOnline, isOfflineMode: isOfflineMode),
      ],
    );
  }
}

class _DiseaseCard extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _DiseaseCard({
    required this.label,
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(AppSpacing.s2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray5.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: iconColor),
            const SizedBox(height: AppSpacing.s1),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.black2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryActionRow extends StatelessWidget {
  final bool isOnline;
  final bool isOfflineMode;

  const _SecondaryActionRow({required this.isOnline, required this.isOfflineMode});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.photo_library_outlined,
            label: 'Desde Galería',
            enabled: isOnline,
            onTap: isOnline ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DiagnosisCaptureScreen(isOfflineMode: isOfflineMode),
                ),
              );
            } : null,
          ),
        ),
        const SizedBox(width: AppSpacing.s2),
        Expanded(
          child: _ActionTile(
            icon: Icons.history_rounded,
            label: 'Historial',
            enabled: true,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DiagnosisHistoryScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.s2),
        Expanded(
          child: _ActionTile(
            icon: Icons.person_outline,
            label: 'Consultar Experto',
            enabled: true,
            onTap: () {
              _showAskExpertSheet(context);
            },
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2 + 4),
        decoration: BoxDecoration(
          color: enabled ? AppColors.gray5 : AppColors.gray5.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled ? AppColors.gray4 : AppColors.gray5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: enabled ? AppColors.primary : AppColors.gray4,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: enabled ? AppColors.black2 : AppColors.gray4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Helper interactive mock functions and classes ---

class MockExpert {
  final String name;
  final String specialty;
  final String experience;
  final bool isOnline;

  const MockExpert({
    required this.name,
    required this.specialty,
    required this.experience,
    required this.isOnline,
  });
}

const List<MockExpert> _mockExperts = [
  MockExpert(
    name: 'Ing. Carlos Mendoza',
    specialty: 'Fitopatología y Plagas del Café',
    experience: '12 años de experiencia • Villa Rica',
    isOnline: true,
  ),
  MockExpert(
    name: 'Dra. Sofía Altamirano',
    specialty: 'Variedades y Conservación de Suelos',
    experience: '8 años de experiencia • Cooperativa Agraria',
    isOnline: true,
  ),
  MockExpert(
    name: 'Ing. Ricardo Quispe',
    specialty: 'Fertilización y Nutrición Foliar',
    experience: '15 años de experiencia • Selva Central',
    isOnline: false,
  ),
];

void _showPestDetailSheet(BuildContext context, PestType pest) {
  final Color statusColor = pest == PestType.healthy
      ? AppColors.success
      : (pest == PestType.roya
          ? AppColors.error
          : (pest == PestType.minador ? const Color(0xFFD48F00) : AppColors.gray2));

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.gray4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pest.displayName,
                      style: AppTextStyles.heading5.copyWith(color: AppColors.black2),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        pest == PestType.healthy ? 'Sano' : 'Plaga de Café',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  '¿Qué es?',
                  style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2),
                ),
                const SizedBox(height: 6),
                Text(
                  pest.description,
                  style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray1, height: 1.4),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  'Recomendaciones de Control y Tratamiento',
                  style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.s3),
                  decoration: BoxDecoration(
                    color: AppColors.gray5.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gray5),
                  ),
                  child: Text(
                    pest.treatmentRecommendation,
                    style: AppTextStyles.smallTextRegular.copyWith(
                      color: AppColors.gray1,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Entendido',
                      style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
              ],
            ),
          );
        },
      );
    },
  );
}

void _showAskExpertSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.gray4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s3),
                Text(
                  'Asesores Técnicos de Café',
                  style: AppTextStyles.heading5.copyWith(color: AppColors.black2),
                ),
                const SizedBox(height: 4),
                Text(
                  'Consulta tus dudas directamente con ingenieros agrónomos de Villa Rica.',
                  style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray2),
                ),
                const SizedBox(height: AppSpacing.s4),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _mockExperts.length,
                  itemBuilder: (context, index) {
                    final expert = _mockExperts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.s2 + 4),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.gray5),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(AppSpacing.s2 + 4),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.secondary,
                          child: Text(
                            expert.name.split(' ').last.substring(0, 1),
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                expert.name,
                                style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2),
                              ),
                            ),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: expert.isOnline ? AppColors.success : AppColors.gray4,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              expert.isOnline ? 'Activo' : 'Inactivo',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: expert.isOnline ? AppColors.success : AppColors.gray3,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              expert.specialty,
                              style: AppTextStyles.smallTextBold.copyWith(
                                color: AppColors.primary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              expert.experience,
                              style: AppTextStyles.smallTextRegular.copyWith(
                                color: AppColors.gray3,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
                        onTap: () {
                          _showChatSimulationDialog(context, expert);
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.s4),
              ],
            ),
          );
        },
      );
    },
  );
}

void _showChatSimulationDialog(BuildContext context, MockExpert expert) {
  final TextEditingController messageController = TextEditingController();
  final List<Map<String, dynamic>> messages = [
    {
      'sender': 'expert',
      'text': '¡Hola! Soy el ${expert.name}. He visto que estás trabajando en tu cafetal en Villa Rica. ¿En qué puedo ayudarte hoy?',
      'time': 'Ahora',
    }
  ];

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 450,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3 + 4, vertical: AppSpacing.s2),
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            expert.name.split(' ').last.substring(0, 1),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expert.name,
                                style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2),
                              ),
                              Text(
                                'Asesor en línea',
                                style: AppTextStyles.smallTextRegular.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.gray1),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: const Color(0xFFF9F9F9),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.s3),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isExpert = msg['sender'] == 'expert';
                          return Align(
                            alignment: isExpert ? Alignment.centerLeft : Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2 + 4, vertical: 10),
                              decoration: BoxDecoration(
                                color: isExpert ? AppColors.white : AppColors.primary,
                                border: isExpert ? Border.all(color: AppColors.gray5) : null,
                                borderRadius: BorderRadius.circular(16).copyWith(
                                  topLeft: isExpert ? const Radius.circular(0) : const Radius.circular(16),
                                  topRight: isExpert ? const Radius.circular(16) : const Radius.circular(0),
                                ),
                              ),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg['text'],
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 14,
                                      color: isExpert ? AppColors.black2 : AppColors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      msg['time'],
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 9,
                                        color: isExpert ? AppColors.gray3 : AppColors.white.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      border: Border(top: BorderSide(color: AppColors.gray5)),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.gray5.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextField(
                              controller: messageController,
                              decoration: const InputDecoration(
                                hintText: 'Escribe tu consulta...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                          onPressed: () {
                            final text = messageController.text.trim();
                            if (text.isEmpty) return;

                            setState(() {
                              messages.add({
                                'sender': 'user',
                                'text': text,
                                'time': 'Ahora',
                              });
                            });
                            messageController.clear();

                            Future.delayed(const Duration(milliseconds: 1500), () {
                              if (!context.mounted) return;
                              setState(() {
                                String reply = 'Entiendo tu duda sobre "$text". Como recomendación general en Villa Rica, es clave regular la sombra del cafetal al 40% y monitorear la humedad de la hoja.';
                                if (text.toLowerCase().contains('roya')) {
                                  reply = 'Para la Roya del café, te sugiero aplicar caldos minerales (sulfocálcico) preventivamente y retirar hojas enfermas para evitar esporas.';
                                } else if (text.toLowerCase().contains('minador')) {
                                  reply = 'El Minador suele controlarse podando las hojas afectadas tempranamente. Fomenta controladores biológicos en el lote.';
                                }
                                messages.add({
                                  'sender': 'expert',
                                  'text': reply,
                                  'time': 'Ahora',
                                });
                              });
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
