import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:myBonus/music/musicdetails.dart';
import 'package:myBonus/pages/home.dart';
import 'package:myBonus/widget/myimage.dart';
import 'package:myBonus/widget/mynetworkimg.dart';
import 'package:myBonus/widget/mytext.dart';

// ============= CONFIGURATION DE LA WAVEFORM =============
class WaveformConfig {
  // Couleurs
  static const bool useMultiColor =
      true; // true = multicolore, false = couleur unie
  static const Color solidColor =
      Colors.red; // Couleur unie (si useMultiColor = false)
  static const List<Color> multiColors = [
    Color(0xFF00F5FF), // Cyan
    Color(0xFFFF006E), // Rose
    Color(0xFFFFBE0B), // Orange
    Color(0xFF8338EC), // Violet
    Color(0xFF00D9FF), // Bleu
  ];

  // Opacité
  static const double baseOpacity = 0.1; // Opacité de base (0.0 à 1.0)
  static const double peakOpacity = 0.1; // Opacité maximale lors des pics

  // Animation
  static const int animationSpeed =
      100; // Vitesse en millisecondes (plus petit = plus rapide)
  static const int waveUpdateInterval = 60; // Fréquence de mise à jour (ms)

  // Barres
  static const int barCount = 50; // Nombre de barres
  static const double barWidthRatio = 0.5; // Largeur des barres (0.0 à 1.0)
  static const double minBarHeight =
      0.1; // Hauteur minimale des barres (0.0 à 1.0)
  static const double maxBarHeight =
      1.0; // Hauteur maximale des barres (0.0 à 1.0)

  // Réactivité
  static const double bassBoost =
      1.5; // Amplification des basses (1.0 = normal)
  static const double smoothness = 0.3; // Lissage de l'animation (0.0 à 1.0)
}
// =========================================================

class FloatingPlayer extends StatefulWidget {
  final VoidCallback? onOpenRadio;
  final int currentTabIndex;

  const FloatingPlayer({
    super.key,
    this.onOpenRadio,
    this.currentTabIndex = -1,
  });

  @override
  State<FloatingPlayer> createState() => _FloatingPlayerState();
}

class _WaveAnimation extends StatefulWidget {
  final bool isPlaying;
  final AudioPlayer? player;

  const _WaveAnimation({required this.isPlaying, this.player});

  @override
  State<_WaveAnimation> createState() => _WaveAnimationState();
}

class _WaveAnimationState extends State<_WaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final math.Random _random = math.Random();
  final List<double> _barHeights = [];
  final List<double> _targetHeights = [];

  @override
  void initState() {
    super.initState();
    // Initialiser les hauteurs des barres
    for (int i = 0; i < WaveformConfig.barCount; i++) {
      _barHeights.add(WaveformConfig.minBarHeight);
      _targetHeights.add(WaveformConfig.minBarHeight);
    }

    _controller = AnimationController(
      duration: Duration(milliseconds: WaveformConfig.animationSpeed),
      vsync: this,
    );

    if (widget.isPlaying) {
      _controller.repeat();
      _startWaveformUpdates();
    }
  }

  void _startWaveformUpdates() {
    Future.delayed(Duration(milliseconds: WaveformConfig.waveUpdateInterval),
        () {
      if (mounted && widget.isPlaying) {
        _updateWaveform();
        _startWaveformUpdates();
      }
    });
  }

  void _updateWaveform() {
    setState(() {
      for (int i = 0; i < WaveformConfig.barCount; i++) {
        // Simuler des variations réalistes basées sur la musique
        final bassFrequency =
            i < WaveformConfig.barCount * 0.2; // Premières 20% = basses
        final midFrequency = i >= WaveformConfig.barCount * 0.2 &&
            i < WaveformConfig.barCount * 0.7;
        double amplitude;
        if (bassFrequency) {
          // Basses: variations plus amples et plus lentes
          amplitude = _random.nextDouble() * WaveformConfig.bassBoost;
        } else if (midFrequency) {
          // Médiums: variations modérées
          amplitude = _random.nextDouble() * 0.8;
        } else {
          // Aigus: variations rapides et légères
          amplitude = _random.nextDouble() * 0.6;
        }

        // Ajouter des pics occasionnels pour simuler les beats
        if (_random.nextDouble() > 0.85) {
          amplitude *= 1.5;
        }

        final targetHeight = WaveformConfig.minBarHeight +
            (amplitude *
                (WaveformConfig.maxBarHeight - WaveformConfig.minBarHeight));

        _targetHeights[i] = targetHeight;

        // Lissage de l'animation
        _barHeights[i] = _barHeights[i] +
            ((_targetHeights[i] - _barHeights[i]) * WaveformConfig.smoothness);
      }
    });
  }

  @override
  void didUpdateWidget(_WaveAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
      _startWaveformUpdates();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
      // Réinitialiser les barres
      for (int i = 0; i < WaveformConfig.barCount; i++) {
        _barHeights[i] = WaveformConfig.minBarHeight;
        _targetHeights[i] = WaveformConfig.minBarHeight;
      }
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
          painter: RealtimeWaveformPainter(
            barHeights: _barHeights,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class RealtimeWaveformPainter extends CustomPainter {
  final List<double> barHeights;

  RealtimeWaveformPainter({required this.barHeights});

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / WaveformConfig.barCount;
    final centerY = size.height / 2;

    for (int i = 0; i < barHeights.length; i++) {
      // Déterminer la couleur
      Color barColor;
      if (WaveformConfig.useMultiColor) {
        final colorIndex = i % WaveformConfig.multiColors.length;
        barColor = WaveformConfig.multiColors[colorIndex];
      } else {
        barColor = WaveformConfig.solidColor;
      }

      // Calculer l'opacité basée sur la hauteur (plus haut = plus opaque)
      final heightRatio = barHeights[i] / WaveformConfig.maxBarHeight;
      final opacity = WaveformConfig.baseOpacity +
          (heightRatio *
              (WaveformConfig.peakOpacity - WaveformConfig.baseOpacity));

      final height = barHeights[i] * size.height;

      final paint = Paint()
        ..color = barColor.withOpacity(opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill
        ..strokeCap = StrokeCap.round;

      // Dessiner la barre (rectangle arrondi)
      final barRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(i * barWidth + barWidth / 2, centerY),
          width: barWidth * WaveformConfig.barWidthRatio,
          height: height,
        ),
        Radius.circular(barWidth * 0.4),
      );

      canvas.drawRRect(barRect, paint);
    }
  }

  @override
  bool shouldRepaint(RealtimeWaveformPainter oldDelegate) {
    return true; // Toujours repeindre pour l'animation en temps réel
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
        final AudioPlayer? effectivePlayer =
            player ?? (audioPlayer.audioSource != null ? audioPlayer : null);

        // Ensure _visible is true if player exists and current source is set
        if (player != null &&
            player.sequenceState.currentSource != null &&
            !_visible) {
          _visible = true;
        }
        // Hide mini-player if on Radio tab (index 0)
        if (effectivePlayer == null ||
            !_visible ||
            widget.currentTabIndex == 0) {
          return const SizedBox.shrink();
        }

        final tag = effectivePlayer.sequenceState.currentSource?.tag;
        String title = '';
        String subtitle = '';
        String artUri = '';
        if (tag is MediaItem) {
          title = tag.title;
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
              // Expand the miniplayer to full height before opening radio tab
              try {
                playerExpandProgress.value = MediaQuery.of(context).size.height;
              } catch (_) {}
              widget.onOpenRadio?.call();
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
                    stream: effectivePlayer.playingStream,
                    builder: (context, snapshot) {
                      final isPlaying =
                          snapshot.data ?? effectivePlayer.playing;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 70,
                          child: _WaveAnimation(
                            isPlaying: isPlaying,
                            player: effectivePlayer,
                          ),
                        ),
                      );
                    },
                  ),
                  // Main content
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                ? MyNetworkImage(
                                    imgWidth: 54,
                                    imgHeight: 54,
                                    fit: BoxFit.cover,
                                    imageUrl: artUri)
                                : MyImage(
                                    width: 54,
                                    height: 54,
                                    imagePath: 'appicon.png'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MyText(
                                color:
                                    Theme.of(context).colorScheme.onBackground,
                                text: title,
                                multilanguage: false,
                                fontsize: 14,
                                fontwaight: FontWeight.w600,
                                maxline: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              MyText(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
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
                          stream: effectivePlayer.playingStream,
                          builder: (context, snapshot) {
                            final isPlaying =
                                snapshot.data ?? effectivePlayer.playing;
                            return IconButton(
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_fill,
                                size: 34,
                              ),
                              onPressed: () {
                                if (isPlaying) {
                                  effectivePlayer.pause();
                                } else {
                                  effectivePlayer.play();
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
