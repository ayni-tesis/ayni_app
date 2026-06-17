import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/crops_local_datasource.dart';
import '../../data/repositories/crops_repository_impl.dart';
import '../../domain/entities/parcel.dart';
import '../../domain/entities/crop.dart';
import '../../domain/repositories/crops_repository.dart';

// ─── DataSource & Repository ─────────────────────────────────────────────────

final cropsLocalDataSourceProvider = Provider<CropsLocalDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CropsLocalDataSourceImpl(sharedPreferences: prefs);
});

final cropsRepositoryProvider = Provider<CropsRepository>((ref) {
  return CropsRepositoryImpl(
    localDataSource: ref.watch(cropsLocalDataSourceProvider),
  );
});

// ─── Parcels state ────────────────────────────────────────────────────────────

class ParcelsNotifier extends StateNotifier<AsyncValue<List<Parcel>>> {
  final CropsRepository repository;

  ParcelsNotifier(this.repository) : super(const AsyncValue.loading()) {
    loadParcels();
  }

  Future<void> loadParcels() async {
    state = const AsyncValue.loading();
    try {
      final parcels = await repository.getParcels();
      state = AsyncValue.data(parcels);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addParcel(Parcel parcel) async {
    await repository.saveParcel(parcel);
    await loadParcels();
  }

  Future<void> updateParcel(Parcel parcel) async {
    await repository.saveParcel(parcel);
    await loadParcels();
  }

  Future<void> deleteParcel(String id) async {
    await repository.deleteParcel(id);
    await loadParcels();
  }
}

final parcelsProvider =
    StateNotifierProvider<ParcelsNotifier, AsyncValue<List<Parcel>>>((ref) {
  return ParcelsNotifier(ref.watch(cropsRepositoryProvider));
});

// ─── Crops state ───────────────────────────────────────────────────────────────

class CropsNotifier extends StateNotifier<AsyncValue<List<Crop>>> {
  final CropsRepository repository;

  CropsNotifier(this.repository) : super(const AsyncValue.loading()) {
    loadAllCrops();
  }

  Future<void> loadAllCrops() async {
    state = const AsyncValue.loading();
    try {
      final crops = await repository.getAllCrops();
      state = AsyncValue.data(crops);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadCropsByParcel(String parcelId) async {
    state = const AsyncValue.loading();
    try {
      final crops = await repository.getCropsByParcel(parcelId);
      state = AsyncValue.data(crops);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCrop(Crop crop) async {
    await repository.saveCrop(crop);
    await loadAllCrops();
  }

  Future<void> updateCrop(Crop crop) async {
    await repository.saveCrop(crop);
    await loadAllCrops();
  }

  Future<void> deleteCrop(String id) async {
    await repository.deleteCrop(id);
    await loadAllCrops();
  }
}

final cropsProvider =
    StateNotifierProvider<CropsNotifier, AsyncValue<List<Crop>>>((ref) {
  return CropsNotifier(ref.watch(cropsRepositoryProvider));
});

// ─── Selected parcel ──────────────────────────────────────────────────────────

final selectedParcelIdProvider = StateProvider<String?>((ref) => null);

final selectedParcelProvider = FutureProvider<Parcel?>((ref) async {
  final id = ref.watch(selectedParcelIdProvider);
  if (id == null) return null;
  final repo = ref.watch(cropsRepositoryProvider);
  return repo.getParcelById(id);
});

// ─── Stats ────────────────────────────────────────────────────────────────────

final parcelStatsProvider = Provider<({int total, int healthy, int withPest})>((ref) {
  final cropsAsync = ref.watch(cropsProvider);
  return cropsAsync.maybeWhen(
    data: (crops) {
      final total = crops.length;
      final withPest = crops.where((c) => c.status != PlantStatus.healthy).length;
      return (total: total, healthy: total - withPest, withPest: withPest);
    },
    orElse: () => (total: 0, healthy: 0, withPest: 0),
  );
});
