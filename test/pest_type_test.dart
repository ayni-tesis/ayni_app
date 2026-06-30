import 'package:flutter_test/flutter_test.dart';
import 'package:ayni_app/features/diagnosis/domain/entities/pest_type.dart';

/// Tests unitarios de la entidad `PestType` — capa de dominio pura.
///
/// Esta entidad es el núcleo de la clasificación: cada plaga tiene un
/// `displayName`, `description`, `severityDefault`, `color`, `symptoms`,
/// `preventionTips` y `treatmentRecommendation`. Validar estos getters
/// asegura que la UI (catálogo, detalle, recomendación) recibe siempre
/// información consistente para las 5 clases que reconoce el modelo ML.
void main() {
  group('PestType.displayName', () {
    test('mapea cada enum a su nombre legible en español', () {
      expect(PestType.roya.displayName, 'Roya');
      expect(PestType.minador.displayName, 'Minador');
      expect(PestType.phoma.displayName, 'Phoma');
      expect(PestType.healthy.displayName, 'Sana');
      expect(PestType.redspider.displayName, 'Araña Roja');
    });

    test('cobertura: las 5 plagas tienen displayName no vacío', () {
      for (final pest in PestType.values) {
        expect(pest.displayName, isNotEmpty,
            reason: '${pest.name} debe tener un displayName');
      }
    });
  });

  group('PestType.description', () {
    test('cada plaga tiene una descripción de al menos 30 caracteres', () {
      for (final pest in PestType.values) {
        expect(pest.description.length, greaterThan(30),
            reason: '${pest.name} debe tener descripción detallada');
      }
    });

    test('Sana no menciona control ni tratamiento en su descripción', () {
      // La hoja sana no debe recomendar productos químicos.
      expect(
        PestType.healthy.description.toLowerCase(),
        isNot(contains('fungicida')),
      );
      expect(
        PestType.healthy.description.toLowerCase(),
        isNot(contains('insecticida')),
      );
    });
  });

  group('PestType.severityDefault', () {
    test('la severidad por defecto refleja la agresividad de la plaga', () {
      // Roya y Phoma son las más agresivas (alto impacto en producción).
      expect(PestType.roya.severityDefault, PestSeverity.high);
      expect(PestType.phoma.severityDefault, PestSeverity.high);

      // Minador y Araña Roja tienen impacto moderado.
      expect(PestType.minador.severityDefault, PestSeverity.moderate);
      expect(PestType.redspider.severityDefault, PestSeverity.moderate);

      // Sana es siempre leve por definición.
      expect(PestType.healthy.severityDefault, PestSeverity.low);
    });

    test('ninguna plaga tiene severidad crítica por defecto', () {
      // "Crítica" se reserva para detecciones con confianza + severidad altas
      // y se calcula en runtime; el valor por defecto debe ser ≤ high.
      for (final pest in PestType.values) {
        expect(pest.severityDefault, isNot(PestSeverity.critical),
            reason: '${pest.name} no debe iniciar en estado crítico');
      }
    });
  });

  group('PestType.color', () {
    test('cada plaga tiene un color distinto (UX: evita confusiones visuales)', () {
      final colors = PestType.values.map((p) => p.color).toSet();
      expect(colors.length, PestType.values.length,
          reason: 'Cada plaga debe tener un color único para el badge UI');
    });

    test('Sana es verde (señal positiva de feedback al agricultor)', () {
      // #66BB6A es verde. Verificamos que el canal verde sea dominante.
      expect(PestType.healthy.color.green, greaterThan(PestType.healthy.color.red));
      expect(PestType.healthy.color.green, greaterThan(PestType.healthy.color.blue));
    });
  });

  group('PestType.symptoms', () {
    test('cada plaga tiene entre 2 y 6 síntomas listados', () {
      for (final pest in PestType.values) {
        final n = pest.symptoms.length;
        expect(n, greaterThanOrEqualTo(2),
            reason: '${pest.name} debe tener al menos 2 síntomas');
        expect(n, lessThanOrEqualTo(6),
            reason: '${pest.name} debe tener como máximo 6 síntomas');
      }
    });

    test('Roya menciona manchas amarillas o anaranjadas (síntoma clave)', () {
      final allText = PestType.roya.symptoms.join(' ').toLowerCase();
      expect(allText, anyOf(contains('amarill'), contains('anaranjad')));
    });

    test('Minador menciona galerías o caminos (síntoma visual clave)', () {
      final allText = PestType.minador.symptoms.join(' ').toLowerCase();
      expect(allText, anyOf(contains('galerías'), contains('caminos')));
    });
  });

  group('PestType.preventionTips', () {
    test('cada plaga tiene al menos 2 consejos preventivos', () {
      for (final pest in PestType.values) {
        expect(pest.preventionTips.length, greaterThanOrEqualTo(2),
            reason: '${pest.name} debe tener consejos preventivos');
      }
    });
  });

  group('PestType.treatmentRecommendation', () {
    test('cada plaga tiene recomendación de tratamiento', () {
      for (final pest in PestType.values) {
        expect(pest.treatmentRecommendation, isNotEmpty);
        // Las recomendaciones vienen en pasos numerados (1., 2., 3., ...).
        expect(pest.treatmentRecommendation, contains('1.'),
            reason: '${pest.name} debe tener al menos 1 paso numerado');
      }
    });

    test('Sana recomienda mantenimiento, no tratamiento químico', () {
      final rec = PestType.healthy.treatmentRecommendation.toLowerCase();
      expect(rec, isNot(contains('fungicida')));
      expect(rec, isNot(contains('insecticida')));
    });
  });

  group('PestSeverity.displayName', () {
    test('mapea cada severidad a español', () {
      expect(PestSeverity.low.displayName, 'Leve');
      expect(PestSeverity.moderate.displayName, 'Moderada');
      expect(PestSeverity.high.displayName, 'Alta');
      expect(PestSeverity.critical.displayName, 'Crítica');
    });
  });
}