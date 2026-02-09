import 'dart:math' as math;
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

class _WaveAnimation extends StatefulWidget {
  final bool isPlaying;
  
  const _WaveAnimation({required this.isPlaying});

  @override
  State<_WaveAnimation> createState() => _WaveAnimationState();
}

class _WaveAnimationState extends State<_WaveAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(_WaveAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: WavePainter(
            progress: _controller.value,
            color: colorPrimary.withOpacity(0.1),
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double progress;
  final Color color;

  WavePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const waveCount = 3;
    final waveWidth = size.width / waveCount;
    const waveHeight = 4.0;

    path.moveTo(0, size.height / 2);

    for (int i = 0; i <= waveCount * 2; i++) {
      final waveX = i * waveWidth / 2;
      final waveY = size.height / 2 +
          math.sin((i * 1.5 + progress * 4 * math.pi)) * waveHeight;
      if (i == 0) {
        path.moveTo(waveX, waveY);
      } else {
        path.lineTo(waveX, waveY);
      }
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
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
        // Ensure _visible is true if player exists and current source is set
        if (player != null && player.sequenceState?.currentSource != null && !_visible) {
          _visible = true;
        }
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
              // Expand the miniplayer to full height before opening full player
              try {
                playerExpandProgress.value = MediaQuery.of(context).size.height;
              } catch (_) {}
              // Open full player page
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MusicDetails(ishomepage: false),
                ),
              );
              // When returning, collapse back to mini height
              try {
                playerExpandProgress.value = playerMinHeight;
              } catch (_) {}
              setState(() {});
            },
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).cardColor,
              child: Stack(
                children: [
                  // Wave animation background
                  StreamBuilder<bool>(
                    stream: player.playingStream,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data ?? player.playing ?? false;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 70,
                          child: _WaveAnimation(isPlaying: isPlaying),
                        ),
                      );
                    },
                  ),
                  // Main content
                  Container(
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
                        StreamBuilder<bool>(
                          stream: player.playingStream,
                          builder: (context, snapshot) {
                            final isPlaying = snapshot.data ?? player.playing ?? false;
                            return IconButton(
                              icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 34, color: colorPrimary),
                              onPressed: () {
                                if (isPlaying) {
                                  player.pause();
                                } else {
                                  player.play();
                                }
                                setState(() {});
                              },
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: _stopPlayer,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
