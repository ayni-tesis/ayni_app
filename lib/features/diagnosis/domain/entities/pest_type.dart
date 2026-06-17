import 'package:flutter/material.dart';

enum PestSeverity {
  low,
  moderate,
  high,
  critical;

  String get displayName {
    switch (this) {
      case PestSeverity.low:
        return 'Leve';
      case PestSeverity.moderate:
        return 'Moderada';
      case PestSeverity.high:
        return 'Alta';
      case PestSeverity.critical:
        return 'Crítica';
    }
  }
}

enum PestType {
  roya,
  minador,
  phoma,
  healthy,
  redspider;

  String get displayName {
    switch (this) {
      case PestType.roya:
        return 'Roya';
      case PestType.minador:
        return 'Minador';
      case PestType.phoma:
        return 'Phoma';
      case PestType.healthy:
        return 'Sana';
      case PestType.redspider:
        return 'Araña Roja';
    }
  }

  String get description {
    switch (this) {
      case PestType.roya:
        return 'Hongo que genera manchas amarillas/anaranjadas con polvo en el envés de la hoja.';
      case PestType.minador:
        return 'Pequeña larva que come el interior de la hoja, dejando caminos secos transparentes.';
      case PestType.phoma:
        return 'Enfermedad que causa manchas oscuras y necrosis, secando los bordes de las hojas.';
      case PestType.healthy:
        return 'La hoja no presenta signos visibles de plagas o enfermedades.';
      case PestType.redspider:
        return 'Ácaro diminuto que teje telarañas finas en el envés de la hoja, succionando la savia y causando puntos amarillos.';
    }
  }

  String get treatmentRecommendation {
    switch (this) {
      case PestType.roya:
        return '1. Realizar podas selectivas para mejorar la ventilación.\n2. Aplicar fungicidas a base de cobre en el envés de las hojas.\n3. Monitorear las plantas vecinas regularmente.';
      case PestType.minador:
        return '1. Eliminar manualmente las hojas muy afectadas para evitar la propagación.\n2. Fomentar la presencia de avispas benéficas (controladores biológicos).\n3. En ataques severos, aplicar insecticidas específicos recomendados.';
      case PestType.phoma:
        return '1. Retirar y quemar el material infectado (hojas y ramas secas).\n2. Regular la sombra del cafetal para evitar exceso de humedad.\n3. Aplicar fungicidas preventivos antes del periodo de lluvias.';
      case PestType.healthy:
        return '¡Buen trabajo! Continúa con el mantenimiento de sombra limpia, deshierbe a tiempo y fertilización orgánica periódica.';
      case PestType.redspider:
        return '1. Incrementar la humedad ambiente rociando agua limpia.\n2. Aplicar acaricidas naturales como jabón potásico o aceite de neem.\n3. Eliminar las hojas severamente infestadas para reducir la población.';
    }
  }

  List<String> get symptoms {
    switch (this) {
      case PestType.roya:
        return [
          'Manchas amarillas o anaranjadas en el envés de la hoja.',
          'Polvillo anaranjado (esporas) al tocar las manchas.',
          'Defoliación (caída de hojas) en ataques severos.',
          'Debilitamiento general del arbusto de café.'
        ];
      case PestType.minador:
        return [
          'Galerías o caminos transparentes y sinuosos dentro de la hoja.',
          'Zonas secas o necróticas donde la larva se ha alimentado.',
          'Hojas arrugadas o ligeramente deformadas.'
        ];
      case PestType.phoma:
        return [
          'Manchas necróticas oscuras e irregulares en los bordes de la hoja.',
          'Ramas secas o muerte descendente en brotes jóvenes.',
          'Caída prematura de hojas y brotes nuevos.'
        ];
      case PestType.healthy:
        return [
          'Hojas de color verde intenso y uniforme.',
          'Ausencia de manchas, caminos o necrosis.',
          'Superficie foliar limpia y brillante.'
        ];
      case PestType.redspider:
        return [
          'Puntos finos amarillentos o bronceados en el haz de la hoja.',
          'Telarañas extremadamente finas y sedosas en el envés.',
          'Hojas con aspecto opaco o ligeramente marchito.'
        ];
    }
  }

  List<String> get preventionTips {
    switch (this) {
      case PestType.roya:
        return [
          'Sembrar variedades de café resistentes (ej. Catimor, Castillo).',
          'Realizar podas sistemáticas para mejorar la ventilación del lote.',
          'Mantener un plan de fertilización óptimo y equilibrado.'
        ];
      case PestType.minador:
        return [
          'Fomentar la presencia de avispas benéficas como control natural.',
          'Retirar y destruir de inmediato las primeras hojas minadas detectadas.',
          'Regular la sombra para evitar microclimas demasiado secos.'
        ];
      case PestType.phoma:
        return [
          'Evitar establecer parcelas en zonas con exceso persistente de neblina.',
          'Desinfectar las herramientas de poda antes y después de su uso.',
          'Remover y eliminar los restos de tejidos vegetales enfermos.'
        ];
      case PestType.healthy:
        return [
          'Monitorear el cultivo semanalmente en busca de primeros síntomas.',
          'Realizar podas sanitarias preventivas a tiempo.',
          'Mantener un registro de las fertilizaciones y aplicaciones orgánicas.'
        ];
      case PestType.redspider:
        return [
          'Evitar la acumulación de polvo en los caminos aledaños al lote.',
          'Mantener una buena cobertura de suelo para retener humedad.',
          'Aplicar extractos naturales preventivos como aceite de neem.'
        ];
    }
  }

  PestSeverity get severityDefault {
    switch (this) {
      case PestType.roya:
        return PestSeverity.high;
      case PestType.minador:
        return PestSeverity.moderate;
      case PestType.phoma:
        return PestSeverity.high;
      case PestType.healthy:
        return PestSeverity.low;
      case PestType.redspider:
        return PestSeverity.moderate;
    }
  }

  Color get color {
    switch (this) {
      case PestType.roya:
        return const Color(0xFFEF5350); // Red / Error soft
      case PestType.minador:
        return const Color(0xFFFFA726); // Amber / Warning
      case PestType.phoma:
        return const Color(0xFF78909C); // Slate / Gray
      case PestType.healthy:
        return const Color(0xFF66BB6A); // Green / Success
      case PestType.redspider:
        return const Color(0xFFD32F2F); // Dark Red
    }
  }
}
