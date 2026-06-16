import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SyncLocalDataSource {
  Future<int> getPendingCount();
  Future<DateTime?> getLastSyncTime();
  Future<void> setLastSyncTime(DateTime time);
  Future<void> markSynced(List<String> ids);
}

class SyncLocalDataSourceImpl implements SyncLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const _pendingKey = 'diagnosis_history_key'; // reads from diagnosis history
  static const _lastSyncKey = 'last_sync_timestamp';

  SyncLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<int> getPendingCount() async {
    final jsonString = sharedPreferences.getString(_pendingKey);
    if (jsonString == null) return 0;

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      // Count diagnoses where isSynced == false
      return jsonList
          .where((j) => (j as Map<String, dynamic>)['isSynced'] == false)
          .length;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    final millis = sharedPreferences.getInt(_lastSyncKey);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  @override
  Future<void> setLastSyncTime(DateTime time) async {
    await sharedPreferences.setInt(_lastSyncKey, time.millisecondsSinceEpoch);
  }

  @override
  Future<void> markSynced(List<String> ids) async {
    final jsonString = sharedPreferences.getString(_pendingKey);
    if (jsonString == null) return;

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final updated = jsonList.map((j) {
        final map = j as Map<String, dynamic>;
        if (ids.contains(map['id'])) {
          return {...map, 'isSynced': true};
        }
        return map;
      }).toList();

      await sharedPreferences.setString(_pendingKey, jsonEncode(updated));
    } catch (_) {
      // Ignore write errors
    }
  }
}
