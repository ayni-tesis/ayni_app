import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Base de datos SQLite local para la cola de sincronización offline.
///
/// Schema:
///   sync_queue      — diagnósticos capturados offline pendientes de sincronizar
///   sync_metadata   — clave-valor para datos auxiliares (última sync, etc.)
class SyncDatabase {
  static const String _dbName = 'ayni_sync.db';
  static const int _dbVersion = 1;

  static Database? _database;

  /// Obtiene la instancia singleton de la base de datos.
  /// Crea las tablas en la primera llamada.
  static Future<Database> getInstance() async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sync_queue (
        id              TEXT PRIMARY KEY,
        diagnosis_json  TEXT NOT NULL,
        is_synced       INTEGER NOT NULL DEFAULT 0,
        created_at      INTEGER NOT NULL,
        synced_at       INTEGER
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_sync_queue_is_synced ON sync_queue(is_synced)
    ''');

    await db.execute('''
      CREATE TABLE sync_metadata (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // ─── sync_queue ────────────────────────────────────────────────────────────

  /// Inserta un diagnóstico en la cola de sincronización.
  ///
  /// Usa `ConflictAlgorithm.ignore`: si el id ya existe (p. ej. el
  /// reconciliador de SyncStatusScreen vuelve a intentar encolar un
  /// diagnóstico cuyo flag `isSynced` local no se actualizó tras un sync
  /// por lote), no debe pisar su `is_synced` actual. Con `replace` un
  /// diagnóstico recién sincronizado (is_synced = 1) se resetea a
  /// pendiente (is_synced = 0) en cada reconciliación, haciendo que la
  /// cola nunca se vacíe.
  Future<void> insertDiagnosis(String id, String diagnosisJson) async {
    final db = await getInstance();
    await db.insert(
      'sync_queue',
      {
        'id': id,
        'diagnosis_json': diagnosisJson,
        'is_synced': 0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Marca los diagnósticos con los IDs dados como sincronizados.
  Future<void> markSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final placeholders = ids.map((_) => '?').join(',');
    await db.rawUpdate(
      'UPDATE sync_queue SET is_synced = 1, synced_at = ? WHERE id IN ($placeholders)',
      [now, ...ids],
    );
  }

  /// Obtiene todos los diagnósticos pendientes de sincronizar (is_synced == 0).
  Future<List<Map<String, dynamic>>> getPendingDiagnoses() async {
    final db = await getInstance();
    return db.query(
      'sync_queue',
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'created_at ASC',
    );
  }

  /// Cuenta cuántos diagnósticos están pendientes de sincronizar.
  Future<int> getPendingCount() async {
    final db = await getInstance();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sync_queue WHERE is_synced = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Elimina un diagnóstico de la cola (tras ser procesado exitosamente).
  Future<void> deleteDiagnosis(String id) async {
    final db = await getInstance();
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  // ─── sync_metadata ─────────────────────────────────────────────────────────

  /// Guarda un valor clave-valor en la metadata.
  Future<void> setMetadata(String key, String value) async {
    final db = await getInstance();
    await db.insert(
      'sync_metadata',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene un valor de la metadata, o null si no existe.
  Future<String?> getMetadata(String key) async {
    final db = await getInstance();
    final result = await db.query(
      'sync_metadata',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String;
  }
}
