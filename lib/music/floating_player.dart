import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:myBonus/music/musicdetails.dart';
import 'package:myBonus/pages/home.dart';
import 'package:myBonus/utils/color.dart';
import 'package:myBonus/widget/myimage.dart';
import 'package:myBonus/widget/mynetworkimg.dart';
import 'package:myBonus/widget/mytext.dart';

class FloatingPlayer extends StatefulWidget {
  const FloatingPlayer({super.key});

  @override
  State<FloatingPlayer> createState() => _FloatingPlayerState();
}

class _FloatingPlayerState extends State<FloatingPlayer> {
  bool _visible = true;

  void _stopPlayer() async {
    try {
      await audioPlayer.stop();
      await audioPlayer.pause();
      currentlyPlaying.value = null;
    } catch (e) {
      // ignore
    }
    setState(() {
      _visible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioPlayer?>(
      valueListenable: currentlyPlaying,
      builder: (context, player, child) {
        if (player == null || !_visible) return const SizedBox.shrink();

        final tag = player.sequenceState?.currentSource?.tag;
        String title = '';
        String subtitle = '';
        String artUri = '';
        if (tag is MediaItem) {
          title = tag.title ?? '';
          subtitle = tag.artist ?? '';
          artUri = tag.artUri?.toString() ?? '';
        } else if (tag is Map) {
          title = (tag['title'] ?? '').toString();
          subtitle = (tag['artist'] ?? '').toString();
          artUri = (tag['artUri'] ?? tag['image'] ?? '').toString();
        } else if (tag != null) {
          try {
            final dynamic t = tag;
            title = (t.title ?? '').toString();
            subtitle = (t.artist ?? '').toString();
            artUri = (t.artUri ?? '').toString();
          } catch (_) {}
        }

        return Positioned(
          left: 16,
          right: 16,
          bottom: 76, // leave space above bottom nav
          child: GestureDetector(
            onTap: () async {
              // Open full player page
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MusicDetails(ishomepage: false),
                ),
              );
              setState(() {});
            },
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).cardColor,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 54,
                        height: 54,
                        child: artUri.isNotEmpty
                            ? MyNetworkImage(imgWidth: 54, imgHeight: 54, fit: BoxFit.cover, imageUrl: artUri)
                            : MyImage(width: 54, height: 54, imagePath: 'appicon.png'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MyText(
                            color: Theme.of(context).colorScheme.onBackground,
                            text: title,
                            multilanguage: false,
                            fontsize: 14,
                            fontwaight: FontWeight.w600,
                            maxline: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          MyText(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            text: subtitle,
                            multilanguage: false,
                            fontsize: 12,
                            fontwaight: FontWeight.w500,
                            maxline: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(player.playing ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 34, color: colorPrimary),
                      onPressed: () {
                        if (player.playing) {
                          player.pause();
                        } else {
                          player.play();
                        }
                        setState(() {});
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: _stopPlayer,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
