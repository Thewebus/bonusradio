import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:myBonus/utils/constant.dart';

// App-wide network state, started once in main().
// - isOnline: false only when the backend is really unreachable — being
//   attached to a Wi-Fi/4G network isn't enough (captive portal, no credit),
//   so a connected state is confirmed with a tiny request to the backend.
// - onCellular: mobile data is the active link (no Wi-Fi/Ethernet).
class NetworkService {
  NetworkService._();

  static final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);
  static final ValueNotifier<bool> onCellular = ValueNotifier<bool>(false);

  static final Connectivity _connectivity = Connectivity();
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 6),
    receiveTimeout: const Duration(seconds: 6),
    // Any HTTP answer, even an error page, proves the internet works.
    validateStatus: (_) => true,
  ));
  static StreamSubscription<List<ConnectivityResult>>? _sub;
  static Timer? _retryTimer;

  static Future<void> start() async {
    if (_sub != null) return;
    _sub = _connectivity.onConnectivityChanged.listen(_onChanged);
    await _onChanged(await _connectivity.checkConnectivity());
  }

  // Re-checks right now (e.g. a "Retry" button).
  static Future<bool> check() async {
    await _onChanged(await _connectivity.checkConnectivity());
    return isOnline.value;
  }

  static Future<void> _onChanged(List<ConnectivityResult> results) async {
    final bool hasLink = results.any((r) => r != ConnectivityResult.none);
    onCellular.value = results.contains(ConnectivityResult.mobile) &&
        !results.contains(ConnectivityResult.wifi) &&
        !results.contains(ConnectivityResult.ethernet);
    isOnline.value = hasLink && await _reachable();
    // While offline, poll so the banner clears even if the OS doesn't
    // report a change (e.g. mobile credit topped up).
    _retryTimer?.cancel();
    if (!isOnline.value) {
      _retryTimer = Timer(const Duration(seconds: 10), check);
    }
  }

  static Future<bool> _reachable() async {
    try {
      await _dio.head(Constant().baseurl);
      return true;
    } catch (_) {
      return false;
    }
  }
}
