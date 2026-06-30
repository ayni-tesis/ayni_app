import 'dart:convert' as _conv;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ayni_app/core/errors/failures.dart';
import 'package:ayni_app/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:ayni_app/features/diagnosis/domain/entities/leaf_detection.dart';
import 'package:ayni_app/features/diagnosis/domain/entities/pest_type.dart';
import 'package:ayni_app/features/diagnosis/domain/repositories/diagnosis_repository.dart';
import 'package:ayni_app/features/sync/data/datasources/sync_local_datasource.dart';
import 'package:ayni_app/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:ayni_app/features/sync/domain/repositories/sync_repository.dart';

/// Tests unitarios del SyncRepositoryImpl — la pieza estrella del offline-first.
///
/// Esta clase implementa la cola de sincronización diferida (HU10, HU11, HU12,
/// HU65, HU66): permite capturar diagnósticos sin conexión, persistirlos en
/// local, y marcarlos como sincronizados cuando se recupera la red.
///
/// La lógica a validar cubre los flujos críticos de la app:
///   1. Listar diagnósticos pendientes (isSynced == false)
///   2. Contar cuántos faltan sincronizar
///   3. Marcar uno o varios como sincronizados
///   4. Persistir y recuperar el timestamp del último sync
///
/// Errores en esta capa provocarían pérdida silenciosa de diagnósticos
/// capturados en campo (sin red) — un fallo inaceptable para el agricultor.

// ─── Mocks Manuales ─────────────────────────────────────────────────────────

class MockDiagnosisRepository implements DiagnosisRepository {
  /// Resultado que retornará getDiagnosisHistory().
  /// Si es null, se retorna un Left(ServerFailure) — para probar fallback.
  Either<Failure, List<Diagnosis>> historyResult =
      const Right<Failure, List<Diagnosis>>(<Diagnosis>[]);

  int getDiagnosisHistoryCalls = 0;

  @override
  String? get latestDetectionImageUrl => null;

  @override
  Future<Either<Failure, List<Diagnosis>>> getDiagnosisHistory() async {
    getDiagnosisHistoryCalls++;
    return historyResult;
  }

  // Métodos no usados en estos tests pero requeridos por la interfaz.
  @override
  Future<Either<Failure, List<LeafDetection>>> detectLeaves(
    String path, {
    required bool isOffline,
  }) async =>
      const Right(<LeafDetection>[]);

  @override
  Future<Either<Failure, List<LeafDetection>>> classifyPests(
    List<LeafDetection> leaves, {
    required bool isOffline,
  }) async =>
      Right(leaves);

  @override
  Future<Either<Failure, void>> saveDiagnosis(Diagnosis diagnosis) async =>
      const Right(null);

  @override
  Future<Diagnosis?> syncDiagnosis(Diagnosis diagnosis) async => null;
}

/// Fake que replica la lógica de `SyncLocalDataSourceImpl` pero opera sobre
/// SharedPreferences mock. Usamos un `Fake` (no `Mock`) porque queremos
/// exactamente la misma semántica del código de producción.
class FakeSyncLocalDataSource implements SyncLocalDataSource {
  final SharedPreferences prefs;
  static const _pendingKey = 'diagnosis_history_key';
  static const _lastSyncKey = 'last_sync_timestamp';

  FakeSyncLocalDataSource(this.prefs);

  @override
  Future<void> markSynced(List<String> ids) async {
    final jsonString = prefs.getString(_pendingKey);
    if (jsonString == null) return;

    try {
      final jsonList = _conv.jsonDecode(jsonString) as List<dynamic>;
      final updated = jsonList.map((j) {
        final map = j as Map<String, dynamic>;
        if (ids.contains(map['id'])) {
          return {...map, 'isSynced': true};
        }
        return map;
      }).toList();
      await prefs.setString(_pendingKey, _conv.jsonEncode(updated));
    } catch (_) {
      // Ignore write errors (mismo comportamiento que la impl real).
    }
  }

  @override
  Future<int> getPendingCount() async {
    final jsonString = prefs.getString(_pendingKey);
    if (jsonString == null) return 0;

    try {
      final jsonList = _conv.jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .where((j) => (j as Map<String, dynamic>)['isSynced'] == false)
          .length;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    final millis = prefs.getInt(_lastSyncKey);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  @override
  Future<void> setLastSyncTime(DateTime time) async {
    await prefs.setInt(_lastSyncKey, time.millisecondsSinceEpoch);
  }
}

// ─── Helpers de dominio ─────────────────────────────────────────────────────

LeafDetection _leaf({String id = 'leaf_1', PestType? pest}) {
  return LeafDetection(
    id: id,
    boxX: 0.1,
    boxY: 0.1,
    boxWidth: 0.2,
    boxHeight: 0.2,
    croppedImagePath: '/crops/$id.jpg',
    diagnosedPest: pest,
  );
}

Diagnosis _diag({
  required String id,
  bool isOffline = true,
  bool isSynced = false,
  List<LeafDetection>? leaves,
}) {
  return Diagnosis(
    id: id,
    dateTime: DateTime(2026, 6, 17, 10),
    originalImagePath: '/img/$id.jpg',
    detectedLeaves: leaves ?? [_leaf(pest: PestType.roya)],
    isOffline: isOffline,
    isSynced: isSynced,
  );
}

/// Serializa una lista de Diagnosis al formato JSON que SyncLocalDataSource
/// espera leer (mismo formato que produce DiagnosisModel.toJson en producción).
String _serializeHistory(List<Diagnosis> ds) {
  final list = ds
      .map((d) => {
            'id': d.id,
            'dateTime': d.dateTime.toIso8601String(),
            'originalImagePath': d.originalImagePath,
            'detectedLeaves': d.detectedLeaves
                .map((l) => {
                      'id': l.id,
                      'boxX': l.boxX,
                      'boxY': l.boxY,
                      'boxWidth': l.boxWidth,
                      'boxHeight': l.boxHeight,
                      'croppedImagePath': l.croppedImagePath,
                      'diagnosedPest': l.diagnosedPest?.name,
                      'confidence': l.confidence,
                      'severity': l.severity,
                    })
                .toList(),
            'isOffline': d.isOffline,
            'isSynced': d.isSynced,
            'latitude': d.latitude,
            'longitude': d.longitude,
          })
      .toList();
  return _conv.jsonEncode(list);
}

// ─── Tests ──────────────────────────────────────────────────────────────────

void main() {
  late SharedPreferences prefs;
  late MockDiagnosisRepository diagnosisRepo;
  late FakeSyncLocalDataSource syncLocal;
  late SyncRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    diagnosisRepo = MockDiagnosisRepository();
    syncLocal = FakeSyncLocalDataSource(prefs);
    repository = SyncRepositoryImpl(
      diagnosisRepository: diagnosisRepo,
      localDataSource: syncLocal,
    );
  });

  // ─── getPendingDiagnoses ──────────────────────────────────────────────────

  group('SyncRepositoryImpl.getPendingDiagnoses', () {
    test('retorna lista vacía si no hay diagnósticos en historial', () async {
      diagnosisRepo.historyResult = const Right([]);
      final pending = await repository.getPendingDiagnoses();
      expect(pending, isEmpty);
      expect(diagnosisRepo.getDiagnosisHistoryCalls, 1);
    });

    test('filtra correctamente: solo retorna isSynced == false', () async {
      final d1 = _diag(id: 'd1', isSynced: false);
      final d2 = _diag(id: 'd2', isSynced: true);
      final d3 = _diag(id: 'd3', isSynced: false);
      diagnosisRepo.historyResult = Right([d1, d2, d3]);

      final pending = await repository.getPendingDiagnoses();

      expect(pending.length, 2);
      expect(pending.map((d) => d.id), containsAll(['d1', 'd3']));
      expect(pending.map((d) => d.id), isNot(contains('d2')));
    });

    test('retorna lista vacía si el repository devuelve Left(Failure)', () async {
      // Si falla la lectura, NO debe crashear — el caller mostrará "sin pendientes".
      diagnosisRepo.historyResult = const Left(ServerFailure('BD caída'));

      final pending = await repository.getPendingDiagnoses();

      expect(pending, isEmpty);
    });

    test('preserva el orden original del historial', () async {
      // Importante para mostrar en orden cronológico inverso en la UI.
      final d1 = _diag(id: 'first', isSynced: false);
      final d2 = _diag(id: 'second', isSynced: false);
      final d3 = _diag(id: 'third', isSynced: false);
      diagnosisRepo.historyResult = Right([d1, d2, d3]);

      final pending = await repository.getPendingDiagnoses();

      expect(pending.map((d) => d.id), ['first', 'second', 'third']);
    });
  });

  // ─── getPendingCount ──────────────────────────────────────────────────────

  group('SyncRepositoryImpl.getPendingCount', () {
    test('retorna 0 cuando no hay historial', () async {
      expect(await repository.getPendingCount(), 0);
    });

    test('cuenta correctamente los isSynced == false en el JSON', () async {
      // Sembramos 3 diagnósticos: 2 pendientes + 1 ya sincronizado.
      await prefs.setString(
        'diagnosis_history_key',
        _serializeHistory([
          _diag(id: 'a', isSynced: false),
          _diag(id: 'b', isSynced: true),
          _diag(id: 'c', isSynced: false),
        ]),
      );

      expect(await repository.getPendingCount(), 2);
    });

    test('retorna 0 si el JSON está corrupto (no crashea)', () async {
      await prefs.setString('diagnosis_history_key', '{esto no es json válido');

      expect(await repository.getPendingCount(), 0);
    });
  });

  // ─── markAsSynced ─────────────────────────────────────────────────────────

  group('SyncRepositoryImpl.markAsSynced', () {
    test('marca SOLO el id indicado, dejando los demás como pendientes', () async {
      await prefs.setString(
        'diagnosis_history_key',
        _serializeHistory([
          _diag(id: 'a', isSynced: false),
          _diag(id: 'b', isSynced: false),
          _diag(id: 'c', isSynced: false),
        ]),
      );

      await repository.markAsSynced('b');

      expect(await repository.getPendingCount(), 2,
          reason: 'Deben quedar 2 pendientes (a y c)');
    });

    test('es idempotente: marcar un id ya sincronizado no rompe', () async {
      await prefs.setString(
        'diagnosis_history_key',
        _serializeHistory([
          _diag(id: 'a', isSynced: true),
        ]),
      );

      // No debe lanzar excepción ni duplicar nada.
      await repository.markAsSynced('a');

      expect(await repository.getPendingCount(), 0);
    });

    test('si el id no existe, no afecta el historial', () async {
      await prefs.setString(
        'diagnosis_history_key',
        _serializeHistory([_diag(id: 'a', isSynced: false)]),
      );

      await repository.markAsSynced('id-inexistente');

      expect(await repository.getPendingCount(), 1);
    });
  });

  // ─── markAllAsSynced ──────────────────────────────────────────────────────

  group('SyncRepositoryImpl.markAllAsSynced', () {
    test('marca múltiples ids en una sola operación', () async {
      await prefs.setString(
        'diagnosis_history_key',
        _serializeHistory([
          _diag(id: 'a', isSynced: false),
          _diag(id: 'b', isSynced: false),
          _diag(id: 'c', isSynced: false),
        ]),
      );

      await repository.markAllAsSynced(['a', 'c']);

      expect(await repository.getPendingCount(), 1,
          reason: 'Solo debe quedar b pendiente');
    });

    test('con lista vacía, no modifica nada', () async {
      await prefs.setString(
        'diagnosis_history_key',
        _serializeHistory([_diag(id: 'a', isSynced: false)]),
      );

      await repository.markAllAsSynced(const []);

      expect(await repository.getPendingCount(), 1);
    });
  });

  // ─── Last sync time ───────────────────────────────────────────────────────

  group('SyncRepositoryImpl setLastSyncTime / getLastSyncTime', () {
    test('getLastSyncTime retorna null cuando nunca se ha sincronizado', () async {
      expect(await repository.getLastSyncTime(), isNull);
    });

    test('setLastSyncTime persiste y getLastSyncTime recupera el timestamp exacto', () async {
      final t = DateTime(2026, 6, 17, 14, 30);
      await repository.setLastSyncTime(t);

      final got = await repository.getLastSyncTime();
      expect(got, isNotNull);
      expect(got!.millisecondsSinceEpoch, t.millisecondsSinceEpoch);
    });

    test('sobrescribe el timestamp previo (no acumula)', () async {
      await repository.setLastSyncTime(DateTime(2026, 1, 1));
      await repository.setLastSyncTime(DateTime(2026, 6, 17));

      final got = await repository.getLastSyncTime();
      expect(got!.year, 2026);
      expect(got!.month, 6);
      expect(got!.day, 17);
    });
  });

  // ─── Flujo end-to-end (simulado) ──────────────────────────────────────────

  group('Flujo end-to-end offline-first', () {
    test('captura offline → sync → ya no aparece como pendiente', () async {
      // 1. Agricultor captura 2 diagnósticos sin conexión.
      final offline1 = _diag(id: 'diag_offline_1', isOffline: true, isSynced: false);
      final offline2 = _diag(id: 'diag_offline_2', isOffline: true, isSynced: false);
      diagnosisRepo.historyResult = Right([offline1, offline2]);
      await prefs.setString(
        'diagnosis_history_key',
        _serializeHistory([offline1, offline2]),
      );

      // 2. Sync provider consulta cuántos faltan.
      expect(await repository.getPendingCount(), 2);

      // 3. Sincroniza el primero con éxito.
      await repository.markAsSynced(offline1.id);

      // 4. Verifica que solo queda 1 pendiente.
      expect(await repository.getPendingCount(), 1);

      // 5. Persiste el timestamp del último sync exitoso.
      final now = DateTime(2026, 6, 17, 15);
      await repository.setLastSyncTime(now);
      expect(await repository.getLastSyncTime(), now);

      // 6. Sincroniza el segundo.
      await repository.markAsSynced(offline2.id);

      // 7. Cola vacía.
      expect(await repository.getPendingCount(), 0);

      // 8. getPendingDiagnoses ya no retorna nada.
      final pending = await repository.getPendingDiagnoses();
      expect(pending, isEmpty);
    });
  });
}