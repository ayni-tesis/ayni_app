import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/farmer_profile.dart';

/// Persists the farmer profile as a single JSON blob in
/// SharedPreferences. There is at most one profile per device.
class ProfileLocalDataSource {
  static const String _kKey = 'profile.farmer.v1';

  final SharedPreferences _prefs;

  ProfileLocalDataSource({required SharedPreferences sharedPreferences})
      : _prefs = sharedPreferences;

  FarmerProfile? getProfile() {
    final raw = _prefs.getString(_kKey);
    if (raw == null || raw.isEmpty) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return FarmerProfile(
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      region: json['region'] as String?,
      province: json['province'] as String?,
      district: json['district'] as String?,
      communityName: json['communityName'] as String?,
      farmName: json['farmName'] as String?,
      farmSizeHectares: (json['farmSizeHectares'] as num?)?.toDouble(),
      altitudeMeters: (json['altitudeMeters'] as num?)?.toDouble(),
      coffeeVariety: json['coffeeVariety'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Future<void> save(FarmerProfile profile) async {
    final json = {
      'fullName': profile.fullName,
      'email': profile.email,
      'phone': profile.phone,
      'region': profile.region,
      'province': profile.province,
      'district': profile.district,
      'communityName': profile.communityName,
      'farmName': profile.farmName,
      'farmSizeHectares': profile.farmSizeHectares,
      'altitudeMeters': profile.altitudeMeters,
      'coffeeVariety': profile.coffeeVariety,
      'updatedAt': profile.updatedAt.toIso8601String(),
    };
    await _prefs.setString(_kKey, jsonEncode(json));
  }
}