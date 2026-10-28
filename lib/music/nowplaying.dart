import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:myBonus/music/musicdetails.dart';
import 'package:myBonus/pages/home.dart';
import 'package:myBonus/utils/audioquality.dart';
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

  // From an /api/nowplaying/<station> response.
  factory NowPlayingInfo.fromJson(Map data) {
    final song = (data['now_playing'] ?? {})['song'] ?? {};
    final live = data['live'] ?? {};
    return NowPlayingInfo(
      title: capitalizeWords((song['title'] ?? '').toString()),
      artist: formatArtists((song['artist'] ?? '').toString()),
      art: (song['art'] ?? '').toString().isEmpty
          ? null
          : song['art'].toString(),
      listeners: ((data['listeners'] ?? {})['current'] ?? 0) as int,
      isLive: live['is_live'] == true,
      streamerName: capitalizeWords((live['streamer_name'] ?? '').toString()),
    );
  }

  // "Artist – Title", or whichever part is known.
  String get songLine {
    if (artist.isNotEmpty && title.isNotEmpty) return "$artist – $title";
    return artist.isNotEmpty ? artist : title;
  }
}

// AzuraCast artist field: "Flo Rida; T-Pain" -> "Flo Rida / T-Pain".
String formatArtists(String text) => capitalizeWords(text
    .split(';')
    .map((a) => a.trim())
    .where((a) => a.isNotEmpty)
    .join(' / '));

// "MAGIC SYSTEM" / "salif keita" -> "Magic System" / "Salif Keita": words
// typed all in capitals or all in lowercase get a capital then lowercase
// (also after - ( / " '). Words already in mixed case are an artist's own
// spelling and stay as they are (OneRepublic, OutKast, T-Pain). French
// elisions stay lowercase inside a title ("L'Amour d'Abidjan", "C'est"),
// and a few abbreviations keep their usual spelling. Extra spaces go.
String capitalizeWords(String text) {
  const Map<String, String> keep = {
    'dj': 'DJ',
    'mc': 'MC',
    'feat': 'feat',
    'feat.': 'feat.',
    'ft.': 'ft.',
    'vs': 'vs',
    'vs.': 'vs.',
  };
  const Set<String> elisions = {'l', 'd', 'j', 'm', 'n', 's', 't', 'c', 'qu'};
  final String source = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  final String lower = source.toLowerCase();
  return source.splitMapJoin(
    RegExp(r'''[^\s\-(/"'’]+'''),
    onMatch: (m) {
      final String word = m[0]!;
      final String low = word.toLowerCase();
      final String up = word.toUpperCase();
      if (keep.containsKey(low)) return keep[low]!;
      // Mixed case (and not just a capital first letter): leave it.
      if (word != low && word != up && word.substring(1) != low.substring(1)) {
        return word;
      }
      final bool elided = m.end < lower.length &&
          "'’".contains(lower[m.end]) &&
          elisions.contains(low);
      if (elided && lower.substring(0, m.start).trim().isNotEmpty) {
        return low;
      }
      // After a pronoun elision the verb stays lowercase: C'est, Qu'on.
      final Match? before = RegExp(r"(?:^|[\s(])(c|qu|j|m|n|s|t)['’]$")
          .firstMatch(lower.substring(0, m.start));
      if (before != null) return low;
      return low[0].toUpperCase() + low.substring(1);
    },
  );
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
  // Station fetched by the Splash before anything plays: its info is shown
  // on the Radios screen right away and kept while the stream buffers.
  static String? _primedApiUrl;

  // Splash: fetches the radio's now-playing info (and its stream qualities)
  // ahead of the first play, and pre-downloads the cover.
  static Future<void> prefetch(String streamUrl, BuildContext context) async {
    final String? apiUrl = _apiUrlFor(Uri.tryParse(streamUrl));
    if (apiUrl == null) return;
    try {
      final data = (await _dio.get(apiUrl)).data;
      if (data is! Map) return;
      AudioQuality.cacheMounts(streamUrl, data);
      if (!Constant.showRadioMetadata) return;
      final info = NowPlayingInfo.fromJson(data);
      _primedApiUrl = apiUrl;
      nowPlaying.value = info;
      // The now-playing card draws it with Image.network.
      if (info.art != null && context.mounted) {
        await precacheImage(NetworkImage(info.art!), context)
            .catchError((_) {});
      }
    } catch (_) {}
  }

  static void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(_interval, (_) => refresh());
    // A new stream started: don't wait for the next tick.
    currentlyPlaying.addListener(() {
      Future.delayed(const Duration(milliseconds: 500), refresh);
    });
    refresh();
  }

  static Future<void> refresh() async {
    // Nothing loaded yet (first launch): the station primed by the Splash.
    final String? apiUrl = _apiUrlForCurrentSource() ??
        (audioPlayer.sequenceState.currentSource == null
            ? _primedApiUrl
            : null);
    // Paused (not merely still buffering) clears the info, as before.
    final bool paused = !audioPlayer.playing &&
        audioPlayer.sequenceState.currentSource != null &&
        audioPlayer.processingState == ProcessingState.ready;
    // Turned off in admin Settings > App: the screens keep their plain
    // station info.
    if (!Constant.showRadioMetadata || apiUrl == null || paused) {
      nowPlaying.value = null;
      return;
    }
    try {
      final response = await _dio.get(apiUrl);
      final data = response.data;
      if (data is! Map) return;
      AudioQuality.cacheMounts(
          apiUrl.replaceFirst('/api/nowplaying/', '/listen/'), data);
      // The user may have switched to something else meanwhile.
      if ((_apiUrlForCurrentSource() ?? _primedApiUrl) != apiUrl) return;
      nowPlaying.value = NowPlayingInfo.fromJson(data);
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
    return _apiUrlFor(source.uri);
  }

  static String? _apiUrlFor(Uri? uri) {
    if (uri == null) return null;
    final segments = uri.pathSegments;
    final int i = segments.indexOf('listen');
    if (i < 0 || i + 1 >= segments.length) return null;
    return uri
        .replace(path: '/api/nowplaying/${segments[i + 1]}', query: null)
        .toString();
  }
}
