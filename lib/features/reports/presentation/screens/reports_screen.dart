import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../diagnosis/domain/entities/diagnosis.dart';
import '../../../diagnosis/domain/entities/pest_type.dart';
import '../../../diagnosis/presentation/providers/diagnosis_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  // Mock action processing state
  bool _isExporting = false;
  double _exportProgress = 0.0;
  String _exportStep = '';

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(diagnosisHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.black2, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Reportes Fitosanitarios',
          style: AppTextStyles.heading6.copyWith(color: AppColors.black2),
        ),
        centerTitle: true,
      ),
      body: historyAsync.when(
        data: (history) {
          if (history.isEmpty) {
            return _buildEmptyState();
          }
          return _buildReportsDashboard(history);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Text(
              'Error al cargar diagnósticos: $error',
              style: AppTextStyles.bodyRegular.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
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
                Icons.analytics_outlined,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Sin datos para reportes',
              style: AppTextStyles.mediumTextBold.copyWith(color: AppColors.black2),
            ),
            const SizedBox(height: 8),
            Text(
              'Necesitas realizar al menos un diagnóstico de hojas de café para poder generar y descargar reportes PDF o CSV.',
              style: AppTextStyles.bodyRegular.copyWith(color: AppColors.gray2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s4),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsDashboard(List<Diagnosis> history) {
    // Calculate statistics
    final totalDiagnoses = history.length;
    int totalLeaves = 0;
    int healthyLeaves = 0;
    final Map<PestType, int> pestCounts = {};

    for (var d in history) {
      totalLeaves += d.detectedLeaves.length;
      for (var leaf in d.detectedLeaves) {
        final pest = leaf.diagnosedPest ?? PestType.healthy;
        if (pest == PestType.healthy) {
          healthyLeaves++;
        } else {
          pestCounts[pest] = (pestCounts[pest] ?? 0) + 1;
        }
      }
    }

    final healthIndex = totalLeaves > 0 ? (healthyLeaves / totalLeaves) * 100 : 100.0;

    PestType? mostFrequentPest;
    int maxPestCount = 0;
    pestCounts.forEach((pest, count) {
      if (count > maxPestCount) {
        maxPestCount = count;
        mostFrequentPest = pest;
      }
    });

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s4),
      children: [
        _buildStatsCard(
          totalDiagnoses: totalDiagnoses,
          healthIndex: healthIndex,
          mostFrequentPest: mostFrequentPest,
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          'Opciones de Exportación',
          style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2, fontSize: 16),
        ),
        const SizedBox(height: AppSpacing.s2),
        _buildExportOptionCard(
          title: 'Reporte Ejecutivo (PDF)',
          description: 'Genera un documento formal con gráficos de salud foliar, severidad promedio y recomendaciones de tratamiento.',
          icon: Icons.picture_as_pdf_rounded,
          iconColor: AppColors.error,
          onPreview: () => _showPdfPreview(context, history, healthIndex, mostFrequentPest),
          onDownload: () => _simulateExport('PDF', 'AYNI_Reporte_Fitosanitario.pdf'),
          onShare: () => _showShareSheet(context, 'PDF', 'AYNI_Reporte_Fitosanitario.pdf'),
        ),
        const SizedBox(height: AppSpacing.s3),
        _buildExportOptionCard(
          title: 'Detalle de Datos (CSV)',
          description: 'Exporta una hoja de cálculo estructurada con la fecha, coordenadas GPS, tipo de plaga detectada y confianza del modelo.',
          icon: Icons.grid_on_rounded,
          iconColor: AppColors.success,
          onPreview: () => _showCsvPreview(context, history),
          onDownload: () => _simulateExport('CSV', 'AYNI_Diagnosticos_Detallado.csv'),
          onShare: () => _showShareSheet(context, 'CSV', 'AYNI_Diagnosticos_Detallado.csv'),
        ),
        const SizedBox(height: AppSpacing.s4),
        _buildDisclaimerSection(),
      ],
    );
  }

  Widget _buildStatsCard({
    required int totalDiagnoses,
    required double healthIndex,
    required PestType? mostFrequentPest,
  }) {
    final Color healthColor = healthIndex >= 85
        ? AppColors.success
        : (healthIndex >= 60 ? AppColors.warning : AppColors.error);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3 + 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estado General del Cultivo',
            style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2, fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Salud Foliar',
                      style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${healthIndex.toStringAsFixed(1)}%',
                      style: AppTextStyles.heading5.copyWith(
                        color: healthColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.gray5),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diagnósticos',
                      style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalDiagnoses',
                      style: AppTextStyles.heading5.copyWith(
                        color: AppColors.black2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.gray5),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plaga Principal',
                      style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mostFrequentPest?.displayName ?? 'Ninguna',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: mostFrequentPest != null ? AppColors.error : AppColors.success,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          // Progress bar of health index
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: healthIndex / 100,
              minHeight: 8,
              backgroundColor: AppColors.gray5,
              valueColor: AlwaysStoppedAnimation<Color>(healthColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onPreview,
    required VoidCallback onDownload,
    required VoidCallback onShare,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3 + 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray2, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3 + 2),
          const Divider(color: AppColors.gray5, height: 1),
          const SizedBox(height: AppSpacing.s2),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isExporting ? null : onPreview,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(color: AppColors.gray4),
                    minimumSize: const Size(0, 48), // Accessibiliy minimum tap height
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.gray1),
                  label: Text(
                    'Ver',
                    style: AppTextStyles.smallTextBold.copyWith(color: AppColors.gray1),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isExporting ? null : onDownload,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(color: AppColors.primary),
                    minimumSize: const Size(0, 48), // Accessibiliy minimum tap height
                  ),
                  icon: const Icon(Icons.download_rounded, size: 18, color: AppColors.primary),
                  label: Text(
                    'Descargar',
                    style: AppTextStyles.smallTextBold.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isExporting ? null : onShare,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(color: AppColors.primary),
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(0, 48), // Accessibiliy minimum tap height
                  ),
                  icon: const Icon(Icons.share_rounded, size: 18, color: AppColors.white),
                  label: Text(
                    'Compartir',
                    style: AppTextStyles.smallTextBold.copyWith(color: AppColors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.gray5.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray5.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.gray3, size: 20),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Text(
              'Nota: Los archivos generados se guardan localmente en la carpeta /Descargas de su dispositivo y pueden abrirse sin necesidad de conexión a internet.',
              style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray2, height: 1.4, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Simulated download progress execution
  void _simulateExport(String format, String filename) {
    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
      _exportStep = 'Cargando registros...';
    });

    Timer? timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Setup a periodic timer to advance progress
            if (timer == null) {
              int ticks = 0;
              timer = Timer.periodic(const Duration(milliseconds: 300), (t) {
                ticks++;
                if (ticks == 1) {
                  setDialogState(() {
                    _exportProgress = 0.3;
                    _exportStep = 'Estructurando datos en formato $format...';
                  });
                } else if (ticks == 3) {
                  setDialogState(() {
                    _exportProgress = 0.75;
                    _exportStep = 'Escribiendo archivo en almacenamiento...';
                  });
                } else if (ticks >= 5) {
                  t.cancel();
                  Navigator.of(context).pop(); // Close dialog
                  _onExportSuccess(format, filename);
                }
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding: const EdgeInsets.all(AppSpacing.s4),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    'Generando Reporte',
                    style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _exportStep,
                    style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray2),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _exportProgress,
                      backgroundColor: AppColors.gray5,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      setState(() {
        _isExporting = false;
      });
    });
  }

  void _onExportSuccess(String format, String filename) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
        margin: const EdgeInsets.all(AppSpacing.s3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.white),
            const SizedBox(width: AppSpacing.s2),
            Expanded(
              child: Text(
                '¡Reporte $format exportado con éxito!\nGuardado como: /Descargas/$filename',
                style: AppTextStyles.smallTextBold.copyWith(color: AppColors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Show customized share bottom sheet
  void _showShareSheet(BuildContext context, String format, String filename) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        final shareOptions = [
          {'name': 'WhatsApp', 'icon': Icons.chat_outlined, 'color': const Color(0xFF25D366)},
          {'name': 'Gmail', 'icon': Icons.mail_outline_rounded, 'color': const Color(0xFFEA4335)},
          {'name': 'Bluetooth', 'icon': Icons.bluetooth_rounded, 'color': const Color(0xFF157DEC)},
          {'name': 'Telegram', 'icon': Icons.send_rounded, 'color': const Color(0xFF0088CC)},
          {'name': 'Guardar en Drive', 'icon': Icons.cloud_upload_outlined, 'color': const Color(0xFF34A853)},
          {'name': 'Copiar enlace', 'icon': Icons.link_rounded, 'color': AppColors.gray2},
        ];

        return Container(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  'Compartir Reporte ($format)',
                  style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2, fontSize: 17),
                ),
                Text(
                  filename,
                  style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray3, fontSize: 12),
                ),
                const SizedBox(height: AppSpacing.s4),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: shareOptions.length,
                  itemBuilder: (context, index) {
                    final option = shareOptions[index];
                    final name = option['name'] as String;
                    final icon = option['icon'] as IconData;
                    final color = option['color'] as Color;

                    return InkWell(
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.success,
                            margin: const EdgeInsets.all(AppSpacing.s3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            content: Text(
                              'Reporte compartido con éxito vía $name',
                              style: AppTextStyles.smallTextBold.copyWith(color: AppColors.white),
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 28),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name,
                            style: AppTextStyles.smallTextBold.copyWith(color: AppColors.black2, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.s3),
              ],
            ),
          ),
        );
      },
    );
  }

  // Interactive PDF layout preview
  void _showPdfPreview(
    BuildContext context,
    List<Diagnosis> history,
    double healthIndex,
    PestType? mostFrequentPest,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            final formattedReportDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
            final farmerName = 'Diego Rafael Cisneros / Francis Daniel Mamani';

            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Vista Previa de Impresión PDF',
                        style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.gray2),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.gray5),
                Expanded(
                  child: Container(
                    color: AppColors.gray5.withValues(alpha: 0.4),
                    padding: const EdgeInsets.all(AppSpacing.s4),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.s4),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // PDF Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'AYNI - AGRICULTURA INTELIGENTE',
                                        style: TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Reporte Fitosanitario de Finca',
                                        style: AppTextStyles.bodyBold.copyWith(fontSize: 16, color: AppColors.black1),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.eco_rounded, color: AppColors.primary, size: 36),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: AppColors.black2, thickness: 1.5),
                            const SizedBox(height: 12),

                            // Metadata table
                            _buildPdfMetaRow('Caficultores:', farmerName),
                            _buildPdfMetaRow('Fecha Reporte:', formattedReportDate),
                            _buildPdfMetaRow('Total Muestras:', '$currencySymbol${history.length} diagnósticos'),
                            _buildPdfMetaRow('Índice Salud Foliar:', '${healthIndex.toStringAsFixed(1)}% (Óptimo >= 85%)'),
                            _buildPdfMetaRow('Plaga Predominante:', mostFrequentPest?.displayName ?? 'Ninguna (Sano)'),
                            const SizedBox(height: 20),

                            // Health indicator visual mock
                            Text(
                              '1. Resumen Fitosanitario Cuantitativo',
                              style: AppTextStyles.bodyBold.copyWith(fontSize: 13, color: AppColors.black2),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.gray5.withValues(alpha: 0.2),
                                border: Border.all(color: AppColors.gray4),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildPdfStatItem('Índice de Salud', '${healthIndex.toStringAsFixed(1)}%'),
                                  _buildPdfStatItem('Hojas Afectadas', '${100 - healthIndex.round()}%'),
                                  _buildPdfStatItem('Diagnósticos', '${history.length}'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Detail list
                            Text(
                              '2. Detalle de Análisis por Muestra',
                              style: AppTextStyles.bodyBold.copyWith(fontSize: 13, color: AppColors.black2),
                            ),
                            const SizedBox(height: 8),
                            Table(
                              border: TableBorder.all(color: AppColors.gray4, width: 0.5),
                              columnWidths: const {
                                0: FlexColumnWidth(1.2),
                                1: FlexColumnWidth(1.3),
                                2: FlexColumnWidth(0.8),
                                3: FlexColumnWidth(0.9),
                              },
                              children: [
                                // Table Header
                                TableRow(
                                  decoration: BoxDecoration(color: AppColors.gray5.withValues(alpha: 0.4)),
                                  children: [
                                    _buildPdfTableCell('Fecha/Hora', isHeader: true),
                                    _buildPdfTableCell('Diagnóstico', isHeader: true),
                                    _buildPdfTableCell('Confianza', isHeader: true),
                                    _buildPdfTableCell('Modo', isHeader: true),
                                  ],
                                ),
                                // Table Rows
                                ...history.map((d) {
                                  final dateStr = DateFormat('dd/MM HH:mm').format(d.dateTime);
                                  final pestList = d.detectedLeaves
                                      .map((l) => l.diagnosedPest?.displayName ?? 'Sana')
                                      .toSet()
                                      .join(', ');
                                  final avgConf = d.detectedLeaves.isNotEmpty
                                      ? (d.detectedLeaves.map((l) => l.confidence ?? 1.0).reduce((a, b) => a + b) /
                                          d.detectedLeaves.length)
                                      : 0.0;

                                  return TableRow(
                                    children: [
                                      _buildPdfTableCell(dateStr),
                                      _buildPdfTableCell(pestList),
                                      _buildPdfTableCell('${(avgConf * 100).toStringAsFixed(0)}%'),
                                      _buildPdfTableCell(d.isOffline ? 'Offline' : 'Online'),
                                    ],
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Treatment Recommendations
                            Text(
                              '3. Recomendaciones Técnicas de Control',
                              style: AppTextStyles.bodyBold.copyWith(fontSize: 13, color: AppColors.black2),
                            ),
                            const SizedBox(height: 8),
                            _buildPdfRecommendationBlock(mostFrequentPest),

                            const SizedBox(height: 40),
                            Center(
                              child: Text(
                                'Documento oficial autogenerado por AYNI App. Villa Rica, Pasco, Perú.',
                                style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray3, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPdfMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.gray2,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.black1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfStatItem(String title, String val) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontFamily: 'Nunito', fontSize: 10, color: AppColors.gray2, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(fontFamily: 'Nunito', fontSize: 16, color: AppColors.black2, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _buildPdfTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? FontWeight.w800 : FontWeight.w500,
          color: isHeader ? AppColors.black2 : AppColors.gray1,
        ),
        textAlign: isHeader ? TextAlign.center : TextAlign.left,
      ),
    );
  }

  Widget _buildPdfRecommendationBlock(PestType? mainPest) {
    String recText = '';
    if (mainPest == null || mainPest == PestType.healthy) {
      recText = 'El cultivo se encuentra en un estado saludable óptimo. Continuar con monitoreos preventivos semanales, control de sombra limpia y fertilización biológica habitual.';
    } else {
      recText = 'La plaga predominante en el lote es ${mainPest.displayName}.\n\n'
          'Acciones inmediatas:\n'
          '${mainPest.treatmentRecommendation}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.15),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        recText,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 10,
          color: AppColors.gray1,
          height: 1.4,
        ),
      ),
    );
  }

  // Interactive CSV layout preview
  void _showCsvPreview(BuildContext context, List<Diagnosis> history) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Vista Previa de Datos CSV',
                        style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.gray2),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.gray5),
                Expanded(
                  child: Container(
                    color: AppColors.gray5.withValues(alpha: 0.4),
                    padding: const EdgeInsets.all(AppSpacing.s4),
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // CSV File Mock Header representation
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: AppColors.black3,
                          child: Text(
                            'AYNI_Diagnosticos_Detallado.csv',
                            style: TextStyle(fontFamily: 'Courier', color: AppColors.white, fontSize: 13),
                          ),
                        ),
                        Container(
                          color: AppColors.white,
                          padding: const EdgeInsets.all(12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // CSV Raw Headers
                                Text(
                                  'id_diag,fecha,latitud,longitud,offline,cantidad_hojas,plagas_detectadas,confianza_promedio',
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.black2,
                                  ),
                                ),
                                const Divider(color: AppColors.gray4, height: 12),
                                // CSV Rows
                                ...history.map((d) {
                                  final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(d.dateTime);
                                  final latStr = d.latitude?.toStringAsFixed(5) ?? '';
                                  final lngStr = d.longitude?.toStringAsFixed(5) ?? '';
                                  final offlineStr = d.isOffline ? 'SI' : 'NO';
                                  final leavesCount = d.detectedLeaves.length;
                                  final pestList = d.detectedLeaves
                                      .map((l) => l.diagnosedPest?.displayName ?? 'Sana')
                                      .toSet()
                                      .join('|');
                                  final avgConf = d.detectedLeaves.isNotEmpty
                                      ? (d.detectedLeaves.map((l) => l.confidence ?? 1.0).reduce((a, b) => a + b) /
                                          d.detectedLeaves.length)
                                      : 0.0;
                                  final avgConfStr = avgConf.toStringAsFixed(2);

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                                    child: Text(
                                      '${d.id},$dateStr,$latStr,$lngStr,$offlineStr,$leavesCount,$pestList,$avgConfStr',
                                      style: TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 11,
                                        color: AppColors.gray1,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Simple placeholder for formatting
  static const String currencySymbol = '';
}
