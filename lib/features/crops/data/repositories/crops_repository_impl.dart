import '../../domain/entities/parcel.dart';
import '../../domain/entities/crop.dart';
import '../../domain/repositories/crops_repository.dart';
import '../datasources/crops_local_datasource.dart';

class CropsRepositoryImpl implements CropsRepository {
  final CropsLocalDataSource localDataSource;

  CropsRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Parcel>> getParcels() => localDataSource.getParcels();

  @override
  Future<Parcel?> getParcelById(String id) => localDataSource.getParcelById(id);

  @override
  Future<void> saveParcel(Parcel parcel) => localDataSource.saveParcel(parcel);

  @override
  Future<void> deleteParcel(String id) => localDataSource.deleteParcel(id);

  @override
  Future<List<Crop>> getCropsByParcel(String parcelId) =>
      localDataSource.getCropsByParcel(parcelId);

  @override
  Future<List<Crop>> getAllCrops() => localDataSource.getAllCrops();

  @override
  Future<Crop?> getCropById(String id) => localDataSource.getCropById(id);

  @override
  Future<void> saveCrop(Crop crop) => localDataSource.saveCrop(crop);

  @override
  Future<void> deleteCrop(String id) => localDataSource.deleteCrop(id);

  @override
  Future<void> updateCropStatus(String id, PlantStatus status) async {
    final crop = await localDataSource.getCropById(id);
    if (crop != null) {
      await localDataSource.saveCrop(crop.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      ));
    }
  }
}
