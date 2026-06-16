import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/parcel_model.dart';
import '../models/crop_model.dart';
import '../../domain/entities/parcel.dart';
import '../../domain/entities/crop.dart';

abstract class CropsLocalDataSource {
  Future<List<ParcelModel>> getParcels();
  Future<ParcelModel?> getParcelById(String id);
  Future<void> saveParcel(Parcel parcel);
  Future<void> deleteParcel(String id);
  Future<List<CropModel>> getCropsByParcel(String parcelId);
  Future<List<CropModel>> getAllCrops();
  Future<CropModel?> getCropById(String id);
  Future<void> saveCrop(Crop crop);
  Future<void> deleteCrop(String id);
}

class CropsLocalDataSourceImpl implements CropsLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const _parcelsKey = 'parcels_key';
  static const _cropsKey = 'crops_key';

  CropsLocalDataSourceImpl({required this.sharedPreferences});

  // ─── Parcels ────────────────────────────────────────────────────────────────

  @override
  Future<List<ParcelModel>> getParcels() async {
    final jsonString = sharedPreferences.getString(_parcelsKey);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((j) => ParcelModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<ParcelModel?> getParcelById(String id) async {
    final parcels = await getParcels();
    try {
      return parcels.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveParcel(Parcel parcel) async {
    final parcels = await getParcels();
    final index = parcels.indexWhere((p) => p.id == parcel.id);
    final updated = ParcelModel.fromEntity(parcel);

    if (index >= 0) {
      parcels[index] = updated;
    } else {
      parcels.add(updated);
    }

    final jsonList = parcels.map((p) => p.toJson()).toList();
    await sharedPreferences.setString(_parcelsKey, jsonEncode(jsonList));
  }

  @override
  Future<void> deleteParcel(String id) async {
    final parcels = await getParcels();
    parcels.removeWhere((p) => p.id == id);

    // Also delete all crops in this parcel
    final crops = await getAllCrops();
    crops.removeWhere((c) => c.parcelId == id);

    await sharedPreferences.setString(
      _parcelsKey,
      jsonEncode(parcels.map((p) => p.toJson()).toList()),
    );
    await sharedPreferences.setString(
      _cropsKey,
      jsonEncode(crops.map((c) => c.toJson()).toList()),
    );
  }

  // ─── Crops ─────────────────────────────────────────────────────────────────

  @override
  Future<List<CropModel>> getAllCrops() async {
    final jsonString = sharedPreferences.getString(_cropsKey);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((j) => CropModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<CropModel>> getCropsByParcel(String parcelId) async {
    final all = await getAllCrops();
    return all.where((c) => c.parcelId == parcelId).toList();
  }

  @override
  Future<CropModel?> getCropById(String id) async {
    final crops = await getAllCrops();
    try {
      return crops.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveCrop(Crop crop) async {
    final crops = await getAllCrops();
    final index = crops.indexWhere((c) => c.id == crop.id);
    final updated = CropModel.fromEntity(crop);

    if (index >= 0) {
      crops[index] = updated;
    } else {
      crops.add(updated);
    }

    // Update plant count on the parent parcel
    final parcel = await getParcelById(crop.parcelId);
    if (parcel != null) {
      final newCount = crops.where((c) => c.parcelId == crop.parcelId).length;
      await saveParcel(parcel.copyWith(
        plantCount: newCount,
        updatedAt: DateTime.now(),
      ));
    }

    await sharedPreferences.setString(
      _cropsKey,
      jsonEncode(crops.map((c) => c.toJson()).toList()),
    );
  }

  @override
  Future<void> deleteCrop(String id) async {
    final crops = await getAllCrops();
    final crop = crops.cast<CropModel?>().firstWhere(
          (c) => c?.id == id,
          orElse: () => null,
        );
    crops.removeWhere((c) => c.id == id);

    // Update parcel plant count
    if (crop != null) {
      final parcel = await getParcelById(crop.parcelId);
      if (parcel != null) {
        final newCount = crops.where((c) => c.parcelId == crop.parcelId).length;
        await saveParcel(parcel.copyWith(
          plantCount: newCount,
          updatedAt: DateTime.now(),
        ));
      }
    }

    await sharedPreferences.setString(
      _cropsKey,
      jsonEncode(crops.map((c) => c.toJson()).toList()),
    );
  }
}
