import 'package:dio/dio.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../domain/entities/farmer_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_local_datasource.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/profile_api_models.dart';

/// Repository que intenta el API remoto primero y guarda localmente.
/// Offline-first: si hay error de red, lee/escribe desde SharedPreferences.
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remote;
  final ProfileLocalDataSource _local;
  final ConnectivityService _connectivity;

  ProfileRepositoryImpl({
    required this._remote,
    required this._local,
    required this._connectivity,
  });

  @override
  Future<FarmerProfile?> getProfile() async {
    try {
      final isOnline = await _connectivity.isConnected();
      if (!isOnline) return _local.getProfile();

      final remoteProfile = await _remote.getProfile();
      final entity = _toEntity(remoteProfile);
      // Persist server data locally for offline access
      await _local.save(entity);
      return entity;
    } on DioException {
      // Network error → try local cache
      return _local.getProfile();
    } catch (_) {
      return _local.getProfile();
    }
  }

  @override
  Future<void> saveProfile(FarmerProfile profile) async {
    // Always save locally first so the app works offline
    await _local.save(profile);

    try {
      final isOnline = await _connectivity.isConnected();
      if (!isOnline) return;

      final request = FarmerProfileRequest(
        fullName: profile.fullName,
        phone: profile.phone,
        region: profile.region,
        province: profile.province,
        district: profile.district,
        communityName: profile.communityName,
        farmName: profile.farmName,
        farmSizeHectares: profile.farmSizeHectares,
        altitudeMeters: profile.altitudeMeters,
        coffeeVariety: profile.coffeeVariety,
      );

      final remoteProfile = await _remote.saveProfile(request);
      final entity = _toEntity(remoteProfile);
      // Sync back the server response (includes userId, updatedAt, etc.)
      await _local.save(entity);
    } catch (_) {
      // Network/server error → already saved locally, sync later.
      // Nota: _remote envuelve DioException en un Exception genérico,
      // por eso se captura cualquier excepción y no solo DioException.
    }
  }

  /// Registra el token FCM en el servidor para recibir push notifications.
  @override
  Future<void> updateFcmToken(String fcmToken) async {
    try {
      final isOnline = await _connectivity.isConnected();
      if (!isOnline) return;

      await _remote.updateFcmToken(FcmTokenRequest(fcmToken: fcmToken));
    } catch (_) {
      // Silent failure — token se reintentará en próximo bootstrap.
      // Nota: _remote envuelve DioException en un Exception genérico,
      // por eso se captura cualquier excepción y no solo DioException.
    }
  }

  // ─── Mapper ────────────────────────────────────────────────────────────────

  FarmerProfile _toEntity(FarmerProfileResponse r) {
    return FarmerProfile(
      userId: r.userId,
      fullName: r.fullName,
      email: r.email,
      phone: r.phone,
      region: r.region,
      province: r.province,
      district: r.district,
      communityName: r.communityName,
      farmName: r.farmName,
      farmSizeHectares: r.farmSizeHectares,
      altitudeMeters: r.altitudeMeters,
      coffeeVariety: r.coffeeVariety,
      updatedAt: r.updatedAt,
    );
  }
}
