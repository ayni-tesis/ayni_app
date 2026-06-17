/// Per-device farmer profile. In the offline MVP this is the
/// caficultor's contact + farm metadata. When the backend lands the
/// shape mirrors `FarmerProfile` in the `user-service` (CLAUDE.md §5.4).
class FarmerProfile {
  final String fullName;
  final String email;
  final String? phone;
  final String? region;
  final String? province;
  final String? district;
  final String? communityName;
  final String? farmName;
  final double? farmSizeHectares;
  final double? altitudeMeters;
  final String? coffeeVariety;
  final DateTime updatedAt;

  const FarmerProfile({
    required this.fullName,
    required this.email,
    this.phone,
    this.region,
    this.province,
    this.district,
    this.communityName,
    this.farmName,
    this.farmSizeHectares,
    this.altitudeMeters,
    this.coffeeVariety,
    required this.updatedAt,
  });

  FarmerProfile copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? region,
    String? province,
    String? district,
    String? communityName,
    String? farmName,
    double? farmSizeHectares,
    double? altitudeMeters,
    String? coffeeVariety,
    DateTime? updatedAt,
  }) {
    return FarmerProfile(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      region: region ?? this.region,
      province: province ?? this.province,
      district: district ?? this.district,
      communityName: communityName ?? this.communityName,
      farmName: farmName ?? this.farmName,
      farmSizeHectares: farmSizeHectares ?? this.farmSizeHectares,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
      coffeeVariety: coffeeVariety ?? this.coffeeVariety,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}