import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../network/api_client.dart';
import '../network/connectivity_service.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class VersionCheckResult {
  final String minimumVersion;
  final bool forceUpdate;
  final String updateUrl;
  final bool updateAvailable;

  VersionCheckResult({
    required this.minimumVersion,
    required this.forceUpdate,
    required this.updateUrl,
    required this.updateAvailable,
  });

  factory VersionCheckResult.fromJson(Map<String, dynamic> json) {
    return VersionCheckResult(
      minimumVersion: json['minimumVersion'] ?? '',
      forceUpdate: json['forceUpdate'] ?? false,
      updateUrl: json['updateUrl'] ?? '',
      updateAvailable: json['updateAvailable'] ?? false,
    );
  }
}

final versionCheckServiceProvider = Provider<VersionCheckService>((ref) {
  return VersionCheckService(
    api: ref.watch(apiClientProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

class VersionCheckService {
  final ApiClient _api;
  final ConnectivityService _connectivity;

  VersionCheckService({
    required ApiClient api,
    required ConnectivityService connectivity,
  })  : _api = api,
        _connectivity = connectivity;

  Future<VersionCheckResult?> checkAppVersion() async {
    try {
      final hasConnection = await _connectivity.isConnected();
      if (!hasConnection) return null;

      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version;
      final platform = Platform.isAndroid ? 'android' : 'ios';

      final response = await _api.get(
        '/auth/version/check',
        queryParameters: {
          'platform': platform,
          'version': version,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return VersionCheckResult.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {
      // Fail silently according to specs
    }
    return null;
  }
}
