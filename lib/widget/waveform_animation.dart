import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

// ============= CONFIGURATION DE LA WAVEFORM =============
// Shared by floating_player.dart (mini-player preview) and
// musicdetails.dart (LIVE NEON/ABIDJAN Radios "grand lecteur" hero card)
// so every waveform in the app animates with the same look: the sound bars
// of the myBonus logo — mirrored around a taller center, in the logo's
// colors (black on ABIDJAN, the splash cream on LIVE NEON, yellow peaks).
class WaveformConfig {
  // Couleurs (logo myBonus + fond du splash)
  static const Color dayColor = Color(0xFF111111); // ABIDJAN (jour)
  static const Color nightColor = Color(0xFFFFFED6); // LIVE NEON (nuit)
  static const Color peakColor = Color(0xFFF5C400); // Jaune du logo
  static const double peakThreshold = 0.55; // Au-delà : barre jaune

  // Barres
  static const int barCount = 23; // Par défaut (impair : barre centrale)
  static const double barWidthRatio = 0.55; // Largeur des barres (0.0 à 1.0)
  static const double minBarHeight = 0.12; // Hauteur minimale (0.0 à 1.0)
  static const double edgeLevel = 0.35; // Hauteur max aux bords vs centre

  // Animation
  static const int targetInterval = 140; // Nouveau « beat » toutes les X ms
  static const double smoothness = 0.16; // Lissage par image (0.0 à 1.0)
}
// =========================================================

class WaveAnimation extends StatefulWidget {
  final bool isPlaying;
  final AudioPlayer? player;
  // Odd, so there's a center bar. Fewer for small sizes (mini-player).
  final int barCount;
  // Bar color; defaults to the theme's (black by day, cream by night).
  final Color? color;

  const WaveAnimation({
    super.key,
    required this.isPlaying,
    this.player,
    this.barCount = WaveformConfig.barCount,
    this.color,
  });

  @override
  State<WaveAnimation> createState() => WaveAnimationState();
}

class WaveAnimationState extends State<WaveAnimation>
    with SingleTickerProviderStateMixin {
  // Runs every frame while playing; heights ease toward random targets that
  // are redrawn every [WaveformConfig.targetInterval].
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..addListener(_onFrame);
  final math.Random _random = math.Random();
  late final int _half = widget.barCount ~/ 2 + 1;
  late final List<double> _heights =
      List.filled(_half, WaveformConfig.minBarHeight);
  late final List<double> _targets =
      List.filled(_half, WaveformConfig.minBarHeight);
  Duration _lastTarget = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.isPlaying) _start();
  }

  void _start() {
    _lastTarget = Duration.zero;
    _controller.repeat();
  }

  void _stop() {
    _controller.stop();
    for (int i = 0; i < _half; i++) {
      _heights[i] = WaveformConfig.minBarHeight;
      _targets[i] = WaveformConfig.minBarHeight;
    }
  }

  // Envelope of the logo's bars: 1 at the center, edgeLevel at the edges.
  double _envelope(int i) {
    final double d = (_half - 1 - i) / (_half - 1); // 0 au centre, 1 au bord
    return WaveformConfig.edgeLevel +
        (1 - WaveformConfig.edgeLevel) * math.cos(d * math.pi / 2);
  }

  void _onFrame() {
    // Frame clock since the animation started (ticker time, not wall time).
    final Duration now = _controller.lastElapsedDuration ?? Duration.zero;
    if (now - _lastTarget >=
        const Duration(milliseconds: WaveformConfig.targetInterval)) {
      _lastTarget = now;
      for (int i = 0; i < _half; i++) {
        // Occasional stronger beat, as on a real track.
        final double beat = _random.nextDouble() > 0.85 ? 1.0 : 0.75;
        _targets[i] = math.max(WaveformConfig.minBarHeight,
            _envelope(i) * beat * (0.35 + 0.65 * _random.nextDouble()));
      }
    }
    for (int i = 0; i < _half; i++) {
      _heights[i] += (_targets[i] - _heights[i]) * WaveformConfig.smoothness;
    }
  }

  @override
  void didUpdateWidget(WaveAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _start();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: RealtimeWaveformPainter(
            halfHeights: _heights,
            baseColor: widget.color ??
                (isNight ? WaveformConfig.nightColor : WaveformConfig.dayColor),
            playing: widget.isPlaying,
            barCount: widget.barCount,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class RealtimeWaveformPainter extends CustomPainter {
  // Left half including the center bar; the right half mirrors it.
  final List<double> halfHeights;
  final Color baseColor;
  final bool playing;
  final int barCount;

  RealtimeWaveformPainter({
    required this.halfHeights,
    required this.baseColor,
    required this.playing,
    required this.barCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final int count = barCount;
    final double slot = size.width / count;
    final double barWidth = slot * WaveformConfig.barWidthRatio;
    final double centerY = size.height / 2;
    final int center = count ~/ 2;

    for (int i = 0; i < count; i++) {
      final double h = halfHeights[center - (i - center).abs()];
      final bool peak = playing && h >= WaveformConfig.peakThreshold;
      final paint = Paint()
        ..color = peak
            ? WaveformConfig.peakColor
            : baseColor.withValues(alpha: playing ? 0.9 : 0.45);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(i * slot + slot / 2, centerY),
            width: barWidth,
            height: math.max(barWidth, h * size.height),
          ),
          Radius.circular(barWidth / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(RealtimeWaveformPainter oldDelegate) => true;
}
