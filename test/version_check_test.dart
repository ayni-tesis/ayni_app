import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ayni_app/core/network/api_client.dart';
import 'package:ayni_app/core/network/connectivity_service.dart';
import 'package:ayni_app/core/services/version_check_service.dart';

// ─── Manual Mocks ────────────────────────────────────────────────────────────

class MockApiClient implements ApiClient {
  Response? mockResponse;
  bool shouldThrow = false;
  String? lastPath;
  Map<String, dynamic>? lastQueryParams;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    lastPath = path;
    lastQueryParams = queryParameters;
    if (shouldThrow) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        message: 'Network Error',
      );
    }
    return mockResponse as Response<T>;
  }

  // No-op method overrides required by ApiClient interface.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockConnectivityService implements ConnectivityService {
  bool mockConnection = true;

  @override
  Future<bool> isConnected() async {
    return mockConnection;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockApiClient mockApi;
  late MockConnectivityService mockConnectivity;
  late VersionCheckService service;

  setUp(() {
    mockApi = MockApiClient();
    mockConnectivity = MockConnectivityService();
    service = VersionCheckService(
      api: mockApi,
      connectivity: mockConnectivity,
    );

    // Mock PackageInfo platform channels (standard package_info_plus test setup).
    PackageInfo.setMockInitialValues(
      appName: 'Ayni',
      packageName: 'com.ayni.ayni_app',
      version: '1.0.1',
      buildNumber: '1',
      buildSignature: 'signature',
    );
  });

  group('VersionCheckService.checkAppVersion', () {
    test('returns forceUpdate true when local version is older than minimum', () async {
      // GIVEN
      mockConnectivity.mockConnection = true;
      mockApi.mockResponse = Response(
        requestOptions: RequestOptions(path: '/auth/version/check'),
        statusCode: 200,
        data: {
          'minimumVersion': '1.0.2',
          'forceUpdate': true,
          'updateUrl': 'https://play.google.com/store/apps/details?id=com.ayni.ayni_app',
        },
      );

      // WHEN
      final result = await service.checkAppVersion();

      // THEN
      expect(result, isNotNull);
      expect(result!.forceUpdate, isTrue);
      expect(result.minimumVersion, '1.0.2');
      expect(result.updateUrl, 'https://play.google.com/store/apps/details?id=com.ayni.ayni_app');
      expect(mockApi.lastPath, '/auth/version/check');
      expect(mockApi.lastQueryParams, {
        'platform': 'android', // Platform is mocked/run as android or ios in tests
        'version': '1.0.1',
      });
    });

    test('returns forceUpdate false when local version is equal to minimum', () async {
      // GIVEN
      mockConnectivity.mockConnection = true;
      mockApi.mockResponse = Response(
        requestOptions: RequestOptions(path: '/auth/version/check'),
        statusCode: 200,
        data: {
          'minimumVersion': '1.0.2',
          'forceUpdate': false,
          'updateUrl': 'https://play.google.com/store/apps/details?id=com.ayni.ayni_app',
        },
      );

      // WHEN
      final result = await service.checkAppVersion();

      // THEN
      expect(result, isNotNull);
      expect(result!.forceUpdate, isFalse);
    });

    test('returns null when device is offline without calling API', () async {
      // GIVEN
      mockConnectivity.mockConnection = false;

      // WHEN
      final result = await service.checkAppVersion();

      // THEN
      expect(result, isNull);
      expect(mockApi.lastPath, isNull); // Api client was never called
    });

    test('returns null when API call throws exception (fail-silent resilience)', () async {
      // GIVEN
      mockConnectivity.mockConnection = true;
      mockApi.shouldThrow = true;

      // WHEN
      final result = await service.checkAppVersion();

      // THEN
      expect(result, isNull);
    });
  });
}
