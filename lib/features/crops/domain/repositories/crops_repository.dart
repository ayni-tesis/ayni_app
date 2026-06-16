import '../entities/parcel.dart';
import '../entities/crop.dart';

abstract class CropsRepository {
  // Parcels
  Future<List<Parcel>> getParcels();
  Future<Parcel?> getParcelById(String id);
  Future<void> saveParcel(Parcel parcel);
  Future<void> deleteParcel(String id);

  // Crops (plants)
  Future<List<Crop>> getCropsByParcel(String parcelId);
  Future<List<Crop>> getAllCrops();
  Future<Crop?> getCropById(String id);
  Future<void> saveCrop(Crop crop);
  Future<void> deleteCrop(String id);
  Future<void> updateCropStatus(String id, PlantStatus status);
}
