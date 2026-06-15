import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final connectivityStreamProvider = StreamProvider<bool>((ref) {
  return ConnectivityService().connectivityStream;
});

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((results) {
      return results.any((result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet);
    });
  }

  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet);
  }
}
