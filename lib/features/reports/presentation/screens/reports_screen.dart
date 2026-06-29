import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../diagnosis/domain/entities/diagnosis.dart';
import '../../../diagnosis/domain/entities/pest_type.dart';
import '../../../diagnosis/presentation/providers/diagnosis_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _isExporting = false;

  // ── CSV ─────────────────────────────────────────────────────────────────────

  Future<File> _buildCsvFile(List<Diagnosis> history) async {
    final buffer = StringBuffer();
    buffer.writeln(
      'id_diag,fecha,latitud,longitud,offline,cantidad_hojas,plagas_detectadas,confianza_promedio',
    );

    for (final d in history) {
      final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(d.dateTime);
      final lat = d.latitude?.toStringAsFixed(5) ?? '';
      final lng = d.longitude?.toStringAsFixed(5) ?? '';
      final offline = d.isOffline ? 'SI' : 'NO';
      final leavesCount = d.detectedLeaves.length;
      final pests = d.detectedLeaves
          .map((l) => l.diagnosedPest?.displayName ?? 'Sana')
          .toSet()
          .join('|');
      final avgConf = leavesCount == 0
          ? 0.0
          : d.detectedLeaves.map((l) => l.confidence ?? 1.0).reduce((a, b) => a + b) /
              leavesCount;

      buffer.writeln(
        '${d.id},$dateStr,$lat,$lng,$offline,$leavesCount,$pests,${avgConf.toStringAsFixed(2)}',
      );
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/AYNI_Diagnosticos_Detallado.csv');
    await file.writeAsString(buffer.toString(), flush: true);
    return file;
  }

  // ── PDF ─────────────────────────────────────────────────────────────────────

  Future<File> _buildPdfFile({
    required List<Diagnosis> history,
    required double healthIndex,
    required PestType? mainPest,
    required String farmerName,
  }) async {
    final primaryColor = PdfColor.fromInt(0xFF04A033);
    final lightGreen = PdfColor.fromInt(0xFFDDFFE7);
    final gray = PdfColor.fromInt(0xFF4F4F4F);
    final lightGray = PdfColor.fromInt(0xFFE0E0E0);
    final now = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    final doc = pw.Document(
      title: 'Reporte Fitosanitario AYNI',
      author: farmerName,
      subject: 'Diagnóstico de plagas en hojas de café',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),

        header: (_) => pw.Column(children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'AYNI — AGRICULTURA INTELIGENTE',
                    style: pw.TextStyle(
                      color: primaryColor,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Reporte Fitosanitario de Finca',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: lightGreen,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  'SENASA Compatible',
                  style: pw.TextStyle(
                    color: primaryColor,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Divider(color: PdfColors.black, thickness: 1.5),
          pw.SizedBox(height: 4),
        ]),

        footer: (context) => pw.Column(children: [
          pw.Divider(color: lightGray),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Documento generado por AYNI App · Villa Rica, Pasco, Perú',
                style: pw.TextStyle(color: gray, fontSize: 8),
              ),
              pw.Text(
                'Pág. ${context.pageNumber} / ${context.pagesCount}',
                style: pw.TextStyle(color: gray, fontSize: 8),
              ),
            ],
          ),
        ]),

        build: (context) => [
          // ── Metadata ─────────────────────────────────────────────────────────
          _pdfMetaRow('Caficultor:', farmerName),
          _pdfMetaRow('Fecha del reporte:', now),
          _pdfMetaRow('Total diagnósticos:', '${history.length}'),
          _pdfMetaRow('Índice de salud foliar:', '${healthIndex.toStringAsFixed(1)}% (Óptimo ≥ 85%)'),
          _pdfMetaRow('Plaga predominante:', mainPest?.displayName ?? 'Ninguna (Cultivo sano)'),
          pw.SizedBox(height: 20),

          // ── Resumen cuantitativo ──────────────────────────────────────────────
          pw.Text(
            '1. Resumen Fitosanitario Cuantitativo',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: lightGray),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _pdfStatItem('Salud foliar', '${healthIndex.toStringAsFixed(1)}%', primaryColor),
                _pdfStatItem('Hojas afectadas', '${(100 - healthIndex).round()}%', PdfColor.fromInt(0xFFEB5757)),
                _pdfStatItem('Diagnósticos', '${history.length}', gray),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // ── Tabla de diagnósticos ─────────────────────────────────────────────
          pw.Text(
            '2. Detalle de Análisis por Muestra',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Fecha/Hora', 'Diagnóstico', 'Confianza', 'Modo'],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: primaryColor),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
            },
            data: history.map((d) {
              final dateStr = DateFormat('dd/MM HH:mm').format(d.dateTime);
              final pests = d.detectedLeaves
                  .map((l) => l.diagnosedPest?.displayName ?? 'Sana')
                  .toSet()
                  .join(', ');
              final avgConf = d.detectedLeaves.isEmpty
                  ? 0.0
                  : d.detectedLeaves.map((l) => l.confidence ?? 1.0).reduce((a, b) => a + b) /
                      d.detectedLeaves.length;
              return [
                dateStr,
                pests,
                '${(avgConf * 100).toStringAsFixed(0)}%',
                d.isOffline ? 'Offline' : 'Online',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),

          // ── Recomendaciones ───────────────────────────────────────────────────
          pw.Text(
            '3. Recomendaciones Técnicas de Control',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: lightGreen,
              border: pw.Border.all(color: primaryColor),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              mainPest != null && mainPest != PestType.healthy
                  ? 'La plaga predominante es ${mainPest.displayName}.\n\n${mainPest.treatmentRecommendation}'
                  : 'El cultivo se encuentra en estado saludable óptimo. Continuar con monitoreos preventivos semanales, control de sombra limpia y fertilización biológica habitual.',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/AYNI_Reporte_Fitosanitario.pdf');
    await file.writeAsBytes(await doc.save(), flush: true);
    return file;
  }

  pw.Widget _pdfMetaRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 140,
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF4F4F4F),
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
            ),
          ],
        ),
      );

  pw.Widget _pdfStatItem(String title, String value, PdfColor valueColor) =>
      pw.Column(children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColor.fromInt(0xFF828282),
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: valueColor,
          ),
        ),
      ]);

  // ── Export orchestration ─────────────────────────────────────────────────────

  Future<void> _export({
    required String format,
    required Future<File> Function() buildFile,
    required String subject,
    required String filename,
  }) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final file = await buildFile();
      if (!mounted) return;

      await Share.shareXFiles(
        [XFile(file.path, name: filename)],
        subject: subject,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar el $format: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(AppSpacing.s3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ── UI ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(diagnosisHistoryProvider);
    final farmerName =
        ref.watch(currentProfileProvider)?.fullName ?? 'Caficultor AYNI';

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
          if (history.isEmpty) return _buildEmptyState();
          return _buildDashboard(history, farmerName);
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
              child: const Icon(Icons.analytics_outlined, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Sin datos para reportes',
              style: AppTextStyles.mediumTextBold.copyWith(color: AppColors.black2),
            ),
            const SizedBox(height: 8),
            Text(
              'Realiza al menos un diagnóstico de hojas de café para generar reportes PDF o CSV.',
              style: AppTextStyles.bodyRegular.copyWith(color: AppColors.gray2),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(List<Diagnosis> history, String farmerName) {
    int totalLeaves = 0;
    int healthyLeaves = 0;
    final Map<PestType, int> pestCounts = {};

    for (final d in history) {
      totalLeaves += d.detectedLeaves.length;
      for (final leaf in d.detectedLeaves) {
        final pest = leaf.diagnosedPest ?? PestType.healthy;
        if (pest == PestType.healthy) {
          healthyLeaves++;
        } else {
          pestCounts[pest] = (pestCounts[pest] ?? 0) + 1;
        }
      }
    }

    final healthIndex = totalLeaves > 0 ? (healthyLeaves / totalLeaves) * 100 : 100.0;

    PestType? mainPest;
    int maxCount = 0;
    pestCounts.forEach((pest, count) {
      if (count > maxCount) {
        maxCount = count;
        mainPest = pest;
      }
    });

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s4),
      children: [
        _buildStatsCard(
          totalDiagnoses: history.length,
          healthIndex: healthIndex,
          mostFrequentPest: mainPest,
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          'Opciones de Exportación',
          style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2, fontSize: 16),
        ),
        const SizedBox(height: AppSpacing.s2),

        // PDF card
        _buildExportCard(
          title: 'Reporte Ejecutivo (PDF)',
          description:
              'Documento formal con tabla de diagnósticos, índice de salud foliar y recomendaciones de tratamiento.',
          icon: Icons.picture_as_pdf_rounded,
          iconColor: AppColors.error,
          onPreview: () => _showPdfPreview(context, history, healthIndex, mainPest, farmerName),
          onDownload: () => _export(
            format: 'PDF',
            buildFile: () => _buildPdfFile(
              history: history,
              healthIndex: healthIndex,
              mainPest: mainPest,
              farmerName: farmerName,
            ),
            subject: 'Reporte Fitosanitario AYNI',
            filename: 'AYNI_Reporte_Fitosanitario.pdf',
          ),
          onShare: () => _export(
            format: 'PDF',
            buildFile: () => _buildPdfFile(
              history: history,
              healthIndex: healthIndex,
              mainPest: mainPest,
              farmerName: farmerName,
            ),
            subject: 'Te comparto mi reporte fitosanitario de AYNI 🌿',
            filename: 'AYNI_Reporte_Fitosanitario.pdf',
          ),
        ),
        const SizedBox(height: AppSpacing.s3),

        // CSV card
        _buildExportCard(
          title: 'Detalle de Datos (CSV)',
          description:
              'Hoja de cálculo con fecha, coordenadas GPS, tipo de plaga detectada y confianza del modelo.',
          icon: Icons.grid_on_rounded,
          iconColor: AppColors.success,
          onPreview: () => _showCsvPreview(context, history),
          onDownload: () => _export(
            format: 'CSV',
            buildFile: () => _buildCsvFile(history),
            subject: 'Datos de diagnósticos AYNI',
            filename: 'AYNI_Diagnosticos_Detallado.csv',
          ),
          onShare: () => _export(
            format: 'CSV',
            buildFile: () => _buildCsvFile(history),
            subject: 'Te comparto mis datos de diagnósticos de AYNI 🌿',
            filename: 'AYNI_Diagnosticos_Detallado.csv',
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        _buildDisclaimer(),
      ],
    );
  }

  Widget _buildStatsCard({
    required int totalDiagnoses,
    required double healthIndex,
    required PestType? mostFrequentPest,
  }) {
    final healthColor = healthIndex >= 85
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
                    Text('Salud Foliar',
                        style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray2)),
                    const SizedBox(height: 4),
                    Text(
                      '${healthIndex.toStringAsFixed(1)}%',
                      style: AppTextStyles.heading5.copyWith(
                          color: healthColor, fontWeight: FontWeight.w900),
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
                    Text('Diagnósticos',
                        style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray2)),
                    const SizedBox(height: 4),
                    Text(
                      '$totalDiagnoses',
                      style: AppTextStyles.heading5.copyWith(
                          color: AppColors.black2, fontWeight: FontWeight.w900),
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
                    Text('Plaga Principal',
                        style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray2)),
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

  Widget _buildExportCard({
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
                    Text(title,
                        style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(description,
                        style: AppTextStyles.smallTextRegular.copyWith(
                            color: AppColors.gray2, height: 1.4)),
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
                    minimumSize: const Size(0, 48),
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.gray1),
                  label: Text('Ver',
                      style: AppTextStyles.smallTextBold.copyWith(color: AppColors.gray1)),
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
                    minimumSize: const Size(0, 48),
                  ),
                  icon: _isExporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        )
                      : const Icon(Icons.download_rounded, size: 18, color: AppColors.primary),
                  label: Text(
                    _isExporting ? 'Generando...' : 'Descargar',
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
                    minimumSize: const Size(0, 48),
                  ),
                  icon: const Icon(Icons.share_rounded, size: 18, color: AppColors.white),
                  label: Text('Compartir',
                      style: AppTextStyles.smallTextBold.copyWith(color: AppColors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
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
              'Los archivos se generan en el dispositivo. Al tocar "Compartir" puedes enviarlos por WhatsApp, Gmail u otras apps instaladas.',
              style: AppTextStyles.smallTextRegular.copyWith(
                  color: AppColors.gray2, height: 1.4, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Previews (read-only, sin cambios funcionales) ────────────────────────────

  void _showPdfPreview(
    BuildContext context,
    List<Diagnosis> history,
    double healthIndex,
    PestType? mostFrequentPest,
    String farmerName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) {
          final now = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
          return Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.gray4, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Vista Previa PDF',
                        style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2, fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.gray2),
                      onPressed: () => Navigator.of(ctx).pop(),
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
                              offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('AYNI — AGRICULTURA INTELIGENTE',
                                        style: const TextStyle(
                                            fontFamily: 'Nunito',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary)),
                                    Text('Reporte Fitosanitario de Finca',
                                        style: AppTextStyles.bodyBold
                                            .copyWith(fontSize: 15, color: AppColors.black1)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.eco_rounded, color: AppColors.primary, size: 32),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(color: AppColors.black2, thickness: 1.5),
                          const SizedBox(height: 10),
                          _previewMetaRow('Caficultor:', farmerName),
                          _previewMetaRow('Fecha Reporte:', now),
                          _previewMetaRow('Total Muestras:', '${history.length} diagnósticos'),
                          _previewMetaRow('Índice Salud Foliar:',
                              '${healthIndex.toStringAsFixed(1)}% (Óptimo ≥ 85%)'),
                          _previewMetaRow('Plaga Predominante:',
                              mostFrequentPest?.displayName ?? 'Ninguna (Sano)'),
                          const SizedBox(height: 16),
                          Text('2. Detalle por Muestra',
                              style: AppTextStyles.bodyBold.copyWith(fontSize: 12, color: AppColors.black2)),
                          const SizedBox(height: 6),
                          Table(
                            border: TableBorder.all(color: AppColors.gray4, width: 0.5),
                            columnWidths: const {
                              0: FlexColumnWidth(1.2),
                              1: FlexColumnWidth(1.3),
                              2: FlexColumnWidth(0.7),
                              3: FlexColumnWidth(0.8),
                            },
                            children: [
                              TableRow(
                                decoration:
                                    BoxDecoration(color: AppColors.gray5.withValues(alpha: 0.4)),
                                children: ['Fecha/Hora', 'Diagnóstico', 'Conf.', 'Modo']
                                    .map((h) => Padding(
                                          padding: const EdgeInsets.all(5),
                                          child: Text(h,
                                              style: const TextStyle(
                                                  fontFamily: 'Nunito',
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800)),
                                        ))
                                    .toList(),
                              ),
                              ...history.map((d) {
                                final dateStr =
                                    DateFormat('dd/MM HH:mm').format(d.dateTime);
                                final pests = d.detectedLeaves
                                    .map((l) => l.diagnosedPest?.displayName ?? 'Sana')
                                    .toSet()
                                    .join(', ');
                                final avgConf = d.detectedLeaves.isEmpty
                                    ? 0.0
                                    : d.detectedLeaves
                                            .map((l) => l.confidence ?? 1.0)
                                            .reduce((a, b) => a + b) /
                                        d.detectedLeaves.length;
                                return TableRow(children: [
                                  dateStr,
                                  pests,
                                  '${(avgConf * 100).toStringAsFixed(0)}%',
                                  d.isOffline ? 'Offline' : 'Online',
                                ]
                                    .map((cell) => Padding(
                                          padding: const EdgeInsets.all(5),
                                          child: Text(cell,
                                              style: const TextStyle(
                                                  fontFamily: 'Nunito',
                                                  fontSize: 9,
                                                  color: AppColors.gray1)),
                                        ))
                                    .toList());
                              }),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Center(
                            child: Text(
                              'Documento generado por AYNI App · Villa Rica, Pasco, Perú.',
                              style: AppTextStyles.smallTextRegular
                                  .copyWith(color: AppColors.gray3, fontSize: 9),
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
      ),
    );
  }

  Widget _previewMetaRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(label,
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray2)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 11, color: AppColors.black1)),
            ),
          ],
        ),
      );

  void _showCsvPreview(BuildContext context, List<Diagnosis> history) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.gray4, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Vista Previa CSV',
                      style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2, fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.gray2),
                    onPressed: () => Navigator.of(ctx).pop(),
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
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: AppColors.black3,
                      child: const Text(
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
                            const Text(
                              'id_diag,fecha,latitud,longitud,offline,cantidad_hojas,plagas_detectadas,confianza_promedio',
                              style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.black2),
                            ),
                            const Divider(color: AppColors.gray4, height: 12),
                            ...history.map((d) {
                              final dateStr =
                                  DateFormat('yyyy-MM-dd HH:mm:ss').format(d.dateTime);
                              final lat = d.latitude?.toStringAsFixed(5) ?? '';
                              final lng = d.longitude?.toStringAsFixed(5) ?? '';
                              final offline = d.isOffline ? 'SI' : 'NO';
                              final leavesCount = d.detectedLeaves.length;
                              final pests = d.detectedLeaves
                                  .map((l) => l.diagnosedPest?.displayName ?? 'Sana')
                                  .toSet()
                                  .join('|');
                              final avgConf = leavesCount == 0
                                  ? 0.0
                                  : d.detectedLeaves
                                          .map((l) => l.confidence ?? 1.0)
                                          .reduce((a, b) => a + b) /
                                      leavesCount;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Text(
                                  '${d.id},$dateStr,$lat,$lng,$offline,$leavesCount,$pests,${avgConf.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontFamily: 'Courier',
                                      fontSize: 10,
                                      color: AppColors.gray1),
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
        ),
      ),
    );
  }
}
