import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/profile_local_datasource.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/farmer_profile.dart';
import '../../domain/repositories/profile_repository.dart';

final profileLocalDataSourceProvider = Provider<ProfileLocalDataSource>((ref) {
  return ProfileLocalDataSource(
    sharedPreferences: ref.watch(sharedPreferencesProvider),
  );
});

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource(
    api: ref.watch(apiClientProvider),
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    remote: ref.watch(profileRemoteDataSourceProvider),
    local: ref.watch(profileLocalDataSourceProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

class ProfileNotifier extends StateNotifier<AsyncValue<FarmerProfile?>> {
  final ProfileRepository _repository;
  final Ref _ref;

  ProfileNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading()) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final profile = await _repository.getProfile();
    state = AsyncValue.data(profile);
  }

  /// Returns `true` if the save succeeded. The state is updated to
  /// the new profile on success.
  Future<bool> save(FarmerProfile profile) async {
    state = const AsyncValue.loading();
    try {
      await _repository.saveProfile(profile);
      state = AsyncValue.data(profile);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Seeds a profile from the current auth user. Called after the
  /// first login/signup so the screen has something to render.
  Future<void> ensureSeededFromAuth() async {
    final existing = await _repository.getProfile();
    if (existing != null) return;
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    final seeded = FarmerProfile(
      fullName: user.fullName,
      email: user.email,
      updatedAt: DateTime.now(),
    );
    await _repository.saveProfile(seeded);
    state = AsyncValue.data(seeded);
  }
}

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<FarmerProfile?>>((ref) {
  return ProfileNotifier(
    ref.watch(profileRepositoryProvider),
    ref,
  );
});

/// Convenience: the current profile, or `null` if not yet created.
final currentProfileProvider = Provider<FarmerProfile?>((ref) {
  return ref.watch(profileNotifierProvider).valueOrNull;
});