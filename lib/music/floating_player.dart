import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:myBonus/music/musicdetails.dart';
import 'package:myBonus/pages/home.dart';
import 'package:myBonus/utils/color.dart';
import 'package:myBonus/utils/constant.dart';
import 'package:myBonus/widget/mytext.dart';
import 'package:myBonus/widget/waveform_animation.dart';

class FloatingPlayer extends StatefulWidget {
  final int currentTabIndex;
  final VoidCallback? onExpand;

  const FloatingPlayer({
    super.key,
    this.currentTabIndex = -1,
    this.onExpand,
  });

  @override
  State<FloatingPlayer> createState() => _FloatingPlayerState();
}

class _FloatingPlayerState extends State<FloatingPlayer> {
  bool _visible = true;

  void _expandPlayer() {
    setPlayerExpansion(MediaQuery.of(context).size.height);
    widget.onExpand?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioPlayer?>(
      valueListenable: currentlyPlaying,
      builder: (context, player, child) {
        final AudioPlayer? effectivePlayer =
            player ?? (audioPlayer.audioSource != null ? audioPlayer : null);

        // Ensure _visible is true if player exists and current source is set
        if (player != null &&
            player.sequenceState.currentSource != null &&
            !_visible) {
          _visible = true;
        }
        // Hide mini-player if on the Radio tab (its own full-screen panel
        // already shows the "now playing" info).
        if (effectivePlayer == null ||
            !_visible ||
            widget.currentTabIndex == radioTabIndex) {
          return const SizedBox.shrink();
        }

        final tag = effectivePlayer.sequenceState.currentSource?.tag;
        String title = '';
        String subtitle = '';
        String playType = '';
        if (tag is MediaItem) {
          title = tag.title;
          subtitle = tag.displayDescription ?? '';
          playType = tag.displaySubtitle ?? '';
        } else if (tag is Map) {
          title = (tag['title'] ?? '').toString();
          subtitle = (tag['displayDescription'] ?? '').toString();
          playType = (tag['displaySubtitle'] ?? '').toString();
        } else if (tag != null) {
          try {
            final dynamic t = tag;
            title = (t.title ?? '').toString();
            subtitle = (t.displayDescription ?? '').toString();
            playType = (t.displaySubtitle ?? '').toString();
          } catch (_) {}
        }
        final bool isLive = playType == Constant.radioType;
        final bool isNight = Theme.of(context).brightness == Brightness.dark;
        final String? artUri = tag is MediaItem ? tag.artUri?.toString() : null;

        return isNight
            ? _buildNightContent(effectivePlayer, title, subtitle, isLive, artUri)
            : _buildAbidjanContent(
                effectivePlayer, title, subtitle, isLive, artUri);
      },
    );
  }

  // LIVE NEON (night theme) — solid dark bar, thumbnail, small colorful
  // waveform preview, gradient play/pause button. Mirrors
  // _buildAbidjanContent's structure (including the Material wrapper an
  // earlier bug taught us InkWell needs here), recolored for the neon
  // palette instead of flat black/colorPrimary.
  Widget _buildNightContent(AudioPlayer effectivePlayer, String title,
      String subtitle, bool isLive, String? artUri) {
    final String displaySubtitle =
        isLive && subtitle.isNotEmpty ? "En direct · $subtitle" : subtitle;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: _expandPlayer,
        focusColor: transparent,
        splashColor: transparent,
        hoverColor: transparent,
        highlightColor: transparent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: artUri != null && artUri.isNotEmpty
                    ? Image.network(
                        artUri,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                          width: 40,
                          height: 40,
                          color: liveNeonIconChipBg,
                          child:
                              const Icon(Icons.radio, color: white, size: 20),
                        ),
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        color: liveNeonIconChipBg,
                        child: const Icon(Icons.radio, color: white, size: 20),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MyText(
                      color: white,
                      text: title,
                      multilanguage: false,
                      fontsize: 14,
                      fontwaight: FontWeight.w700,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    MyText(
                      color: liveNeonTextSecondary,
                      text: displaySubtitle,
                      multilanguage: false,
                      fontsize: 12,
                      fontwaight: FontWeight.w500,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              StreamBuilder<bool>(
                stream: effectivePlayer.playingStream,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data ?? effectivePlayer.playing;
                  return SizedBox(
                    width: 28,
                    height: 28,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: WaveAnimation(
                        isPlaying: isPlaying,
                        player: effectivePlayer,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              StreamBuilder<bool>(
                stream: effectivePlayer.playingStream,
                builder: (context, snap) {
                  final isPlaying = snap.data ?? effectivePlayer.playing;
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      if (isPlaying) {
                        effectivePlayer.pause();
                      } else {
                        effectivePlayer.play();
                      }
                      setState(() {});
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: liveNeonGradient),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: white,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ABIDJAN (day theme) — solid black bar, thumbnail, filled red play/pause
  // button, matching the mockups. No waveform/chevron/close clutter — the
  // whole row expands the player on tap, same _expandPlayer as before.
  Widget _buildAbidjanContent(AudioPlayer effectivePlayer, String title,
      String subtitle, bool isLive, String? artUri) {
    final String displaySubtitle =
        isLive && subtitle.isNotEmpty ? "En direct · $subtitle" : subtitle;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: _expandPlayer,
        focusColor: transparent,
        splashColor: transparent,
        hoverColor: transparent,
        highlightColor: transparent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: artUri != null && artUri.isNotEmpty
                    ? Image.network(
                        artUri,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 40,
                          height: 40,
                          color: white.withValues(alpha: 0.15),
                          child:
                              const Icon(Icons.radio, color: white, size: 20),
                        ),
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        color: white.withValues(alpha: 0.15),
                        child: const Icon(Icons.radio, color: white, size: 20),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MyText(
                      color: white,
                      text: title,
                      multilanguage: false,
                      fontsize: 14,
                      fontwaight: FontWeight.w700,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    MyText(
                      color: white.withValues(alpha: 0.6),
                      text: displaySubtitle,
                      multilanguage: false,
                      fontsize: 12,
                      fontwaight: FontWeight.w500,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              StreamBuilder<bool>(
                stream: effectivePlayer.playingStream,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data ?? effectivePlayer.playing;
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      if (isPlaying) {
                        effectivePlayer.pause();
                      } else {
                        effectivePlayer.play();
                      }
                      setState(() {});
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: colorPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: white,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
