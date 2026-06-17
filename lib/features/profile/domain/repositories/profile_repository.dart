import '../entities/farmer_profile.dart';

/// Abstract contract the presentation layer consumes to read and
/// write the farmer's profile.
abstract class ProfileRepository {
  /// Returns the locally stored profile, or `null` if the farmer
  /// has never opened the edit screen.
  Future<FarmerProfile?> getProfile();

  /// Persists the profile on this device. Overwrites any previous
  /// value.
  Future<void> saveProfile(FarmerProfile profile);
}