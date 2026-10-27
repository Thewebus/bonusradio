import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:myBonus/utils/network.dart';
import 'package:myBonus/utils/sharedpref.dart';

// Live radio quality (Settings > Qualité audio): "auto" (highest bitrate on
// Wi-Fi, the station's default mount on mobile data), "high", "standard"
// (the default mount) or "low". The bitrates come from the
// AzuraCast station's mounts (/api/nowplaying/<station> -> station.mounts),
// so adding a mount in AzuraCast is all it takes to offer a new one. With a
// single mount the choice has no effect. Uploaded songs/podcasts exist in one
// quality only and are never rewritten.
class AudioQuality {
  AudioQuality._();

  static const String auto = 'auto';
  static const String high = 'high';
  static const String standard = 'standard';
  static const String low = 'low';
  static const String _prefKey = 'audio_quality';

  static final ValueNotifier<String> mode = ValueNotifier<String>(auto);
  // Bitrates (kbps, ascending) of the last station seen — for Settings.
  static final ValueNotifier<List<int>> bitrates = ValueNotifier<List<int>>([]);

  static final Map<String, List<_Mount>> _mountsByStation = {};
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 6),
    receiveTimeout: const Duration(seconds: 6),
  ));

  static Future<void> load() async {
    mode.value = await SharedPref().read(_prefKey) ?? auto;
  }

  static Future<void> setMode(String value) async {
    mode.value = value;
    await SharedPref().save(_prefKey, value);
  }

  // AzuraCast streams look like https://host/listen/<station>/<mount>.
  static String? _station(Uri uri) {
    final int i = uri.pathSegments.indexOf('listen');
    if (i < 0 || i + 1 >= uri.pathSegments.length) return null;
    return '${uri.host}/${uri.pathSegments[i + 1]}';
  }

  // Fetches the station's mounts ahead of the first play (splash).
  static Future<void> prefetch(String streamUrl) async {
    final Uri? uri = Uri.tryParse(streamUrl);
    if (uri == null || _station(uri) == null) return;
    final int i = uri.pathSegments.indexOf('listen');
    try {
      final response = await _dio.get(uri
          .replace(
              path: '/api/nowplaying/${uri.pathSegments[i + 1]}', query: null)
          .toString());
      cacheMounts(streamUrl, response.data);
    } catch (_) {}
  }

  // Called with any /api/nowplaying response (splash, NowPlayingService).
  static void cacheMounts(String streamUrl, dynamic data) {
    final Uri? uri = Uri.tryParse(streamUrl);
    final String? station = uri == null ? null : _station(uri);
    if (station == null || data is! Map) return;
    final List mounts = ((data['station'] ?? {})['mounts'] ?? []) as List;
    final list = <_Mount>[
      for (final m in mounts)
        if (m is Map && m['url'] != null && m['bitrate'] is int)
          _Mount(m['url'].toString(), m['bitrate'] as int,
              m['is_default'] == true),
    ]..sort((a, b) => a.bitrate.compareTo(b.bitrate));
    if (list.isEmpty) return;
    _mountsByStation[station] = list;
    _lastStation = station;
    bitrates.value = list.map((m) => m.bitrate).toList();
  }

  // The stream URL to actually play for [streamUrl] given the current mode
  // and network. Unknown stations play as-is.
  static String streamUrlFor(String streamUrl) {
    final _Mount? mount = _pick(streamUrl);
    return mount?.url ?? streamUrl;
  }

  // Bitrate (kbps) of the stream being played, null if unknown.
  static int? bitrateOf(String playedUrl) {
    final Uri? uri = Uri.tryParse(playedUrl);
    final String? station = uri == null ? null : _station(uri);
    for (final m in _mountsByStation[station] ?? const <_Mount>[]) {
      if (m.url == playedUrl) return m.bitrate;
    }
    return null;
  }

  static String? _lastStation;

  // Bitrate (kbps) [value] would play on the last station seen — for the
  // Settings picker. Null with fewer than two mounts.
  static int? bitrateForMode(String value, {required bool cellular}) =>
      _choose(_mountsByStation[_lastStation], value, cellular)?.bitrate;

  static _Mount? _pick(String streamUrl) {
    final Uri? uri = Uri.tryParse(streamUrl);
    final String? station = uri == null ? null : _station(uri);
    return _choose(
        _mountsByStation[station], mode.value, NetworkService.onCellular.value);
  }

  static _Mount? _choose(List<_Mount>? mounts, String value, bool cellular) {
    if (mounts == null || mounts.length < 2) return null;
    // Standard = the mount marked default in AzuraCast, else the middle one.
    final _Mount standardMount = mounts.firstWhere((m) => m.isDefault,
        orElse: () => mounts[mounts.length ~/ 2]);
    switch (value) {
      case high:
        return mounts.last;
      case low:
        return mounts.first;
      case standard:
        return standardMount;
      default:
        return cellular ? standardMount : mounts.last;
    }
  }
}

class _Mount {
  final String url;
  final int bitrate;
  final bool isDefault;
  const _Mount(this.url, this.bitrate, this.isDefault);
}
