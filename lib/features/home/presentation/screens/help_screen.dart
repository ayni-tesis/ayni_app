import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.black2),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Centro de Ayuda',
          style: AppTextStyles.heading6.copyWith(color: AppColors.black2),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray2,
          indicatorColor: AppColors.primary,
          labelStyle: AppTextStyles.bodyBold,
          unselectedLabelStyle: AppTextStyles.bodyRegular,
          tabs: const [
            Tab(text: 'Guía de Captura'),
            Tab(text: 'Preguntas Frecuentes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCaptureGuideTab(),
          _buildFaqTab(),
        ],
      ),
    );
  }

  Widget _buildCaptureGuideTab() {
    final steps = [
      _GuideStep(
        icon: Icons.wb_sunny_outlined,
        title: 'Buena Iluminación',
        description: 'Toma la foto bajo luz de día directa. Evita sombras fuertes sobre la hoja para que los colores de las manchas se distingan correctamente.',
      ),
      _GuideStep(
        icon: Icons.center_focus_strong_rounded,
        title: 'Enfoque Claro',
        description: 'Mantén el celular a unos 15-20 centímetros de la hoja. Asegúrate de que el visor enfoque bien la superficie antes de presionar el botón.',
      ),
      _GuideStep(
        icon: Icons.crop_free_rounded,
        title: 'Centrar una sola Hoja',
        description: 'Alinea la hoja afectada dentro de la zona del visor de la cámara. Trata de que una sola hoja ocupe el recuadro principal para evitar falsos positivos.',
      ),
      _GuideStep(
        icon: Icons.clean_hands_outlined,
        title: 'Evitar Obstrucciones',
        description: 'No sostengas la hoja tapando las manchas con los dedos. Si es necesario, sujétala por el pecíolo (tallo de la hoja).',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s4),
      children: [
        Text(
          '¿Cómo obtener un diagnóstico preciso?',
          style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(
          'Sigue estas recomendaciones de fotografía para que nuestro modelo de Inteligencia Artificial detecte correctamente las plagas.',
          style: AppTextStyles.bodyRegular.copyWith(color: AppColors.gray1, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.s4),
        ...steps.map((step) => _buildGuideStepCard(step)),
        const SizedBox(height: AppSpacing.s4),
      ],
    );
  }

  Widget _buildGuideStepCard(_GuideStep step) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s3),
      padding: const EdgeInsets.all(AppSpacing.s3 + 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(step.icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.s3 + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  step.description,
                  style: AppTextStyles.smallTextRegular.copyWith(color: AppColors.gray2, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTab() {
    final faqs = [
      _FaqItem(
        question: '¿Cómo funciona el diagnóstico sin conexión (Offline)?',
        answer: 'Cuando no tienes internet, AYNI procesa la fotografía directamente en tu dispositivo usando un modelo local optimizado (TFLite). El diagnóstico toma pocos segundos y los resultados se guardan en el historial del celular de forma segura.',
      ),
      _FaqItem(
        question: '¿Cuándo se sincronizan mis diagnósticos con el servidor?',
        answer: 'El sistema monitorea tu conexión en segundo plano. Apenas recuperes acceso a internet, todos los análisis tomados en modo offline se subirán automáticamente a los servidores de AYNI para habilitar el reporte consolidado de tu finca.',
      ),
      _FaqItem(
        question: '¿Qué significan los niveles de severidad?',
        answer: '• Leve (<25%): Infección inicial. Se controla fácilmente retirando las hojas.\n• Moderada (<50%): Manchas notorias. Requiere ventilación y caldos minerales.\n• Alta (<75%): Propagación media. Requiere fungicidas preventivos.\n• Crítica (>=75%): Defoliación inminente. Requiere acción química de inmediato.',
      ),
      _FaqItem(
        question: '¿Cómo puedo exportar mis reportes?',
        answer: 'Ve a la opción "Reportes" en tu cuenta. Allí podrás generar un archivo CSV (apropiado para Excel) con todo el historial de diagnósticos o un reporte ejecutivo en formato PDF para visualizar y compartir.',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s4),
      children: [
        Text(
          'Preguntas Frecuentes',
          style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(
          'Encuentra respuestas rápidas sobre el funcionamiento de la aplicación en el campo.',
          style: AppTextStyles.bodyRegular.copyWith(color: AppColors.gray1, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.s4),
        ...faqs.map((faq) => _buildFaqTile(faq)),
        const SizedBox(height: AppSpacing.s4),
      ],
    );
  }

  Widget _buildFaqTile(_FaqItem faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray5),
      ),
      child: ExpansionTile(
        shape: const Border(),
        title: Text(
          faq.question,
          style: AppTextStyles.bodyBold.copyWith(color: AppColors.black2, fontSize: 15),
        ),
        childrenPadding: const EdgeInsets.all(AppSpacing.s3 + 4).copyWith(top: 0),
        expandedAlignment: Alignment.topLeft,
        textColor: AppColors.primary,
        iconColor: AppColors.primary,
        children: [
          const Divider(color: AppColors.gray5),
          const SizedBox(height: 6),
          Text(
            faq.answer,
            style: AppTextStyles.bodyRegular.copyWith(
              color: AppColors.gray1,
              height: 1.4,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStep {
  final IconData icon;
  final String title;
  final String description;

  const _GuideStep({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({
    required this.question,
    required this.answer,
  });
}
