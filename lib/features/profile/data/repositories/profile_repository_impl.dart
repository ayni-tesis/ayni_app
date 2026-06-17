import '../../domain/entities/farmer_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_local_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileLocalDataSource _local;

  ProfileRepositoryImpl({required this._local});

  @override
  Future<FarmerProfile?> getProfile() async => _local.getProfile();

  @override
  Future<void> saveProfile(FarmerProfile profile) => _local.save(profile);
}