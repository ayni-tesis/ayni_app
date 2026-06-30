import 'package:flutter_test/flutter_test.dart';
import 'package:ayni_app/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:ayni_app/features/diagnosis/domain/entities/leaf_detection.dart';
import 'package:ayni_app/features/diagnosis/domain/entities/pest_type.dart';

/// Tests unitarios de la entidad `Diagnosis` — capa de dominio pura.
///
/// Esta entidad es el Aggregate Root de la feature de diagnóstico. Sus getters
/// (`overallStatusSummary`, `hasInfection`) son consumidos por la pantalla de
/// resultado, el historial, los reportes PDF y las estadísticas globales.
/// Validarlos es crítico porque un cálculo incorrecto se propaga a múltiples
/// pantallas sin que se note en una sola revisión visual.
void main() {
  // ─── Helpers ──────────────────────────────────────────────────────────────
  LeafDetection leaf({
    String id = 'leaf_1',
    PestType? pest,
    double? confidence,
    double? severity,
  }) {
    return LeafDetection(
      id: id,
      boxX: 0.1,
      boxY: 0.1,
      boxWidth: 0.2,
      boxHeight: 0.2,
      croppedImagePath: '/path/$id.jpg',
      diagnosedPest: pest,
      confidence: confidence,
      severity: severity,
    );
  }

  Diagnosis diag({
    String id = 'diag_1',
    List<LeafDetection>? leaves,
    bool isOffline = false,
    bool isSynced = false,
  }) {
    return Diagnosis(
      id: id,
      dateTime: DateTime(2026, 6, 17, 10),
      originalImagePath: '/img/original.jpg',
      detectedLeaves: leaves ?? const [],
      isOffline: isOffline,
      isSynced: isSynced,
    );
  }

  // ─── overallStatusSummary ────────────────────────────────────────────────
  group('Diagnosis.overallStatusSummary', () {
    test('retorna "No se detectaron hojas" cuando la lista está vacía', () {
      // Caso borde: el modelo detector no encontró hojas válidas.
      final d = diag(leaves: []);
      expect(d.overallStatusSummary, 'No se detectaron hojas');
    });

    test('retorna "Todas las hojas están sanas" si todas son healthy', () {
      final d = diag(leaves: [
        leaf(pest: PestType.healthy),
        leaf(id: 'leaf_2', pest: PestType.healthy),
      ]);
      expect(d.overallStatusSummary, 'Todas las hojas están sanas');
    });

    test('cuenta correctamente hojas con problemas cuando hay mezcla', () {
      final d = diag(leaves: [
        leaf(pest: PestType.roya),
        leaf(id: 'leaf_2', pest: PestType.healthy),
        leaf(id: 'leaf_3', pest: PestType.phoma),
      ]);
      // 2 de 3 con problemas (Roya y Phoma).
      expect(d.overallStatusSummary, '2 de 3 hojas con problemas');
    });

    test('cuenta correctamente cuando TODAS tienen plaga', () {
      final d = diag(leaves: [
        leaf(pest: PestType.roya),
        leaf(id: 'leaf_2', pest: PestType.minador),
      ]);
      expect(d.overallStatusSummary, '2 de 2 hojas con problemas');
    });

    test('considera healthy como "sin problema" (no cuenta como infectada)', () {
      final d = diag(leaves: [
        leaf(pest: PestType.healthy),
        leaf(id: 'leaf_2', pest: PestType.healthy),
        leaf(id: 'leaf_3', pest: PestType.healthy),
      ]);
      expect(d.overallStatusSummary, 'Todas las hojas están sanas');
    });
  });

  // ─── hasInfection ─────────────────────────────────────────────────────────
  group('Diagnosis.hasInfection', () {
    test('false si no hay hojas detectadas', () {
      expect(diag(leaves: []).hasInfection, isFalse);
    });

    test('false si todas las hojas son healthy', () {
      final d = diag(leaves: [
        leaf(pest: PestType.healthy),
        leaf(id: 'leaf_2', pest: PestType.healthy),
      ]);
      expect(d.hasInfection, isFalse);
    });

    test('true si al menos una hoja tiene plaga distinta a healthy', () {
      final d = diag(leaves: [
        leaf(pest: PestType.healthy),
        leaf(id: 'leaf_2', pest: PestType.roya),
      ]);
      expect(d.hasInfection, isTrue);
    });

    test('true para cualquier plaga distinta de healthy (roya/minador/phoma/redspider)', () {
      for (final pest in [
        PestType.roya,
        PestType.minador,
        PestType.phoma,
        PestType.redspider,
      ]) {
        final d = diag(leaves: [leaf(pest: pest)]);
        expect(d.hasInfection, isTrue, reason: '$pest debe marcar infección');
      }
    });
  });

  // ─── copyWith ─────────────────────────────────────────────────────────────
  group('Diagnosis.copyWith', () {
    test('preserva todos los campos al no pasar argumentos', () {
      final original = diag(
        leaves: [leaf(pest: PestType.roya)],
        isOffline: true,
        isSynced: false,
      );
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.dateTime, original.dateTime);
      expect(copy.originalImagePath, original.originalImagePath);
      expect(copy.detectedLeaves, original.detectedLeaves);
      expect(copy.isOffline, original.isOffline);
      expect(copy.isSynced, original.isSynced);
    });

    test('actualiza solo isSynced al marcar como sincronizado', () {
      final original = diag(isSynced: false);
      final synced = original.copyWith(isSynced: true);
      expect(synced.isSynced, isTrue);
      expect(synced.id, original.id);
      expect(synced.detectedLeaves, original.detectedLeaves);
    });

    test('sustituye la lista de hojas al pasar nuevas detecciones', () {
      final original = diag(leaves: [leaf(pest: PestType.roya)]);
      final updated = original.copyWith(
        detectedLeaves: [
          leaf(pest: PestType.phoma),
          leaf(id: 'leaf_2', pest: PestType.healthy),
        ],
      );
      expect(updated.detectedLeaves.length, 2);
      expect(updated.detectedLeaves[0].diagnosedPest, PestType.phoma);
    });
  });

  // ─── toString ─────────────────────────────────────────────────────────────
  group('Diagnosis.toString', () {
    test('incluye id, conteo de hojas y estado offline/synced', () {
      final d = diag(
        id: 'diag_42',
        leaves: [leaf(), leaf(id: 'leaf_2')],
        isOffline: true,
      );
      final s = d.toString();
      expect(s, contains('diag_42'));
      expect(s, contains('leavesCount: 2'));
      expect(s, contains('isOffline: true'));
    });
  });

  // ─── Caso de uso real: flujo offline → sync ──────────────────────────────
  group('Caso real: diagnóstico offline que luego se sincroniza', () {
    test('un diagnóstico offline empieza con isSynced=false y puede marcarse synced', () {
      // Reproduce el flujo del sync_provider.
      final created = diag(
        leaves: [leaf(pest: PestType.roya, confidence: 0.92)],
        isOffline: true,
        isSynced: false,
      );
      expect(created.isOffline, isTrue);
      expect(created.isSynced, isFalse);
      expect(created.hasInfection, isTrue);

      // Después de sync exitoso, el sync repository llama copyWith(isSynced: true).
      final synced = created.copyWith(isSynced: true);
      expect(synced.isSynced, isTrue);
      expect(synced.hasInfection, isTrue, reason: 'El diagnóstico sigue infectado');
      expect(synced.detectedLeaves.length, 1);
    });
  });
}