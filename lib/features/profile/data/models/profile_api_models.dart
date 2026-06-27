// DTOs para user-service vía API Gateway.
//
// Endpoints:
//   GET    /users/profile        → FarmerProfileResponse
//   PUT    /users/profile        ← FarmerProfileRequest
//   PATCH  /users/profile/fcm-token ← FcmTokenRequest

// ─── GET /users/profile & PUT /users/profile ─────────────────────────────────

class FarmerProfileResponse {
  final String userId;
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

  const FarmerProfileResponse({
    required this.userId,
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

  factory FarmerProfileResponse.fromJson(Map<String, dynamic> json) {
    return FarmerProfileResponse(
      userId: json['userId'] as String,
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
}

/// Request body para PUT /users/profile (create or full update).
class FarmerProfileRequest {
  final String fullName;
  final String? phone;
  final String? region;
  final String? province;
  final String? district;
  final String? communityName;
  final String? farmName;
  final double? farmSizeHectares;
  final double? altitudeMeters;
  final String? coffeeVariety;

  const FarmerProfileRequest({
    required this.fullName,
    this.phone,
    this.region,
    this.province,
    this.district,
    this.communityName,
    this.farmName,
    this.farmSizeHectares,
    this.altitudeMeters,
    this.coffeeVariety,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        if (phone != null) 'phone': phone,
        if (region != null) 'region': region,
        if (province != null) 'province': province,
        if (district != null) 'district': district,
        if (communityName != null) 'communityName': communityName,
        if (farmName != null) 'farmName': farmName,
        if (farmSizeHectares != null) 'farmSizeHectares': farmSizeHectares,
        if (altitudeMeters != null) 'altitudeMeters': altitudeMeters,
        if (coffeeVariety != null) 'coffeeVariety': coffeeVariety,
      };
}

// ─── FCM Token ───────────────────────────────────────────────────────────────

/// Request body para PATCH /users/profile/fcm-token.
class FcmTokenRequest {
  final String fcmToken;

  const FcmTokenRequest({required this.fcmToken});

  Map<String, dynamic> toJson() => {'fcmToken': fcmToken};
}
