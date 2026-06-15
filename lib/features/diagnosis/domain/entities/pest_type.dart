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
}
