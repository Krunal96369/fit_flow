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
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  @override
  Stream<bool> onConnectivityChanged() {
    return _connectivity.onConnectivityChanged.map(
      (result) => result != ConnectivityResult.none,
    );
  }
}
