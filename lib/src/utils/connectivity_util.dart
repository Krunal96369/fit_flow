import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityUtilProvider = Provider<ConnectivityUtil>((ref) {
  return ConnectivityUtilImpl();
});

abstract class ConnectivityUtil {
  Future<bool> isOnline();
  Stream<bool> onConnectivityChanged();
}

class ConnectivityUtilImpl implements ConnectivityUtil {
  final Connectivity _connectivity = Connectivity();

  @override
  Future<bool> isOnline() async {
    try {
      // Use checkConnectivity which always returns a single ConnectivityResult
      final result = await _connectivity.checkConnectivity();
      // Starting with flutter_plus 6.0.0, this returns a List<ConnectivityResult>
      // If it's a list, we're online if any result is not "none"
      return !result.contains(ConnectivityResult.none);
    } catch (e) {
      // If anything goes wrong, assume we're offline
      return false;
    }
  }

  @override
  Stream<bool> onConnectivityChanged() {
    return _connectivity.onConnectivityChanged.map((result) {
      // Starting with flutter_plus 6.0.0, this returns a List<ConnectivityResult>
      // If it's a list, we're online if any result is not "none"
      return !result.contains(ConnectivityResult.none);
    });
  }
}
