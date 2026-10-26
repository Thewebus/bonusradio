import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:myBonus/music/musicdetails.dart';
import 'package:myBonus/pages/home.dart';
import 'package:myBonus/utils/constant.dart';

// What the live radio is playing right now, from the AzuraCast public API.
class NowPlayingInfo {
  final String title;
  final String artist;
  final String? art;
  final int listeners;
  final bool isLive;
  final String streamerName;

  const NowPlayingInfo({
    required this.title,
    required this.artist,
    required this.art,
    required this.listeners,
    required this.isLive,
    required this.streamerName,
  });

  // "Artist – Title", or whichever part is known.
  String get songLine {
    if (artist.isNotEmpty && title.isNotEmpty) return "$artist – $title";
    return artist.isNotEmpty ? artist : title;
  }
}

// Null when nothing live is playing or the stream isn't an AzuraCast one.
final ValueNotifier<NowPlayingInfo?> nowPlaying =
    ValueNotifier<NowPlayingInfo?>(null);

// Polls AzuraCast's /api/nowplaying/<station> while a radio stream served
// by AzuraCast (https://host/listen/<station>/...) is the current source.
// The API URL is derived from the stream URL — nothing to configure.
class NowPlayingService {
  NowPlayingService._();

  static Timer? _timer;
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  static const Duration _interval = Duration(seconds: 15);

  static void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(_interval, (_) => refresh());
    // A new stream started: don't wait for the next tick.
    currentlyPlaying.addListener(() {
      Future.delayed(const Duration(seconds: 2), refresh);
    });
    refresh();
  }

  static Future<void> refresh() async {
    final String? apiUrl = _apiUrlForCurrentSource();
    if (apiUrl == null || !audioPlayer.playing) {
      nowPlaying.value = null;
      return;
    }
    try {
      final response = await _dio.get(apiUrl);
      final data = response.data;
      if (data is! Map) return;
      final song = (data['now_playing'] ?? {})['song'] ?? {};
      final live = data['live'] ?? {};
      // The user may have switched to something else meanwhile.
      if (_apiUrlForCurrentSource() != apiUrl) return;
      nowPlaying.value = NowPlayingInfo(
        title: (song['title'] ?? '').toString(),
        artist: (song['artist'] ?? '').toString(),
        art: (song['art'] ?? '').toString().isEmpty
            ? null
            : song['art'].toString(),
        listeners: ((data['listeners'] ?? {})['current'] ?? 0) as int,
        isLive: live['is_live'] == true,
        streamerName: (live['streamer_name'] ?? '').toString(),
      );
    } catch (_) {
      // Keep the last known value on a transient network error.
    }
  }

  static String? _apiUrlForCurrentSource() {
    final source = audioPlayer.sequenceState.currentSource;
    final tag = source?.tag;
    if (tag is! MediaItem || tag.displaySubtitle != Constant.radioType) {
      return null;
    }
    if (source is! UriAudioSource) return null;
    final uri = source.uri;
    final segments = uri.pathSegments;
    final int i = segments.indexOf('listen');
    if (i < 0 || i + 1 >= segments.length) return null;
    return uri
        .replace(path: '/api/nowplaying/${segments[i + 1]}', query: null)
        .toString();
  }
}
