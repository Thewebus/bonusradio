import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:myBonus/music/musicdetails.dart';
import 'package:myBonus/utils/audioquality.dart';
import 'package:myBonus/utils/constant.dart';
import 'package:myBonus/utils/network.dart';
import 'package:myBonus/utils/sharedpref.dart';

// Estimates the mobile data this session spends on audio (bitrate × time
// played on cellular) and raises a discreet reminder once it passes the
// admin threshold (Settings > App), then at most once per reminder interval.
// The user can turn reminders off in Settings > Données mobiles.
class MobileDataWatcher {
  MobileDataWatcher._();

  static const String _prefKey = 'mobile_data_alert';
  static const Duration _tick = Duration(seconds: 5);
  // Uploaded songs/podcasts: bitrate isn't known, assume a typical MP3.
  static const int _defaultKbps = 128;

  // Message currently shown by NetworkBanner, null when hidden.
  static final ValueNotifier<String?> warning = ValueNotifier<String?>(null);
  static final ValueNotifier<bool> userEnabled = ValueNotifier<bool>(true);

  static double _bytes = 0;
  static DateTime? _lastWarning;
  static Timer? _timer;
  static Timer? _hideTimer;

  static Future<void> start() async {
    userEnabled.value = await SharedPref().read(_prefKey) != '0';
    _timer ??= Timer.periodic(_tick, (_) => _onTick());
  }

  static Future<void> setUserEnabled(bool value) async {
    userEnabled.value = value;
    if (!value) dismiss();
    await SharedPref().save(_prefKey, value ? '1' : '0');
  }

  static void dismiss() {
    _hideTimer?.cancel();
    warning.value = null;
  }

  static void _onTick() {
    if (!audioPlayer.playing || !NetworkService.onCellular.value) return;
    final source = audioPlayer.sequenceState.currentSource;
    final int kbps = source is UriAudioSource
        ? AudioQuality.bitrateOf(source.uri.toString()) ?? _defaultKbps
        : _defaultKbps;
    _bytes += kbps * 1000 / 8 * _tick.inSeconds;

    if (!Constant.mobileDataWarning || !userEnabled.value) return;
    final int mb = (_bytes / 1000000).round();
    if (mb < Constant.mobileDataWarningMb) return;
    final DateTime now = DateTime.now();
    if (_lastWarning != null &&
        now.difference(_lastWarning!).inMinutes <
            Constant.mobileDataWarningInterval) {
      return;
    }
    _lastWarning = now;
    warning.value = AudioQuality.mode.value == AudioQuality.low
        ? "Données mobiles · environ $mb Mo utilisés. Passez en Wi-Fi pour économiser."
        : "Données mobiles · environ $mb Mo utilisés. Passez en Wi-Fi ou baissez la qualité audio.";
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 10), dismiss);
  }
}
