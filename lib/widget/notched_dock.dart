import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

class NotchedDockItem {
  final IconData icon;
  final String label;
  const NotchedDockItem(this.icon, this.label);
}

// Bottom nav bar with a bubble sitting in a notch cut into its top edge, and
// optionally a bar above it (the mini-player) notched around the same bubble.
// On selection the bubble and both notches slide together to the tapped item.
class NotchedDock extends StatelessWidget {
  final List<NotchedDockItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color barColor;
  final Color borderColor;
  final double borderWidth;
  final Gradient bubbleGradient;
  final Color bubbleIconColor;
  final Color iconColor;
  final Color labelColor;
  final Color selectedLabelColor;
  // Shown above the nav. Must keep its bottom [aboveNotchDepth] free of
  // content: that's where the notch cuts in.
  final Widget? above;
  // Hides [above] by sucking it into the bubble (and back out when false).
  final bool aboveHidden;

  const NotchedDock({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.barColor,
    required this.borderColor,
    required this.borderWidth,
    required this.bubbleGradient,
    required this.bubbleIconColor,
    required this.iconColor,
    required this.labelColor,
    required this.selectedLabelColor,
    this.above,
    this.aboveHidden = false,
  });

  static const double _bubbleRadius = 23;
  static const double _notchGap = 5;
  static const double _notchRadius = _bubbleRadius + _notchGap;
  // Between the bar above and the nav. The bubble rises over this gap, into
  // the bar above's notch (same circle as the nav's, centered on its top edge).
  static const double _aboveGap = 8;
  static const double aboveNotchDepth = _notchRadius - _aboveGap;
  static const double _barHeight = 56;
  static const double _sideInset = 12;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double width = constraints.maxWidth;
      final double itemWidth = (width - 2 * _sideInset) / items.length;
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(end: selectedIndex.toDouble()),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
        builder: (context, position, _) {
          final double center = _sideInset + (position + 0.5) * itemWidth;
          return Material(
            type: MaterialType.transparency,
            // The bubble is positioned in this outer Stack, and the space
            // above the nav is at least as tall as what it rises by, so all
            // of it stays inside and takes taps even with nothing above.
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                          minHeight: _bubbleRadius + 1 - _aboveGap),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        heightFactor: 1,
                        child: above == null ? null : _buildAbove(center),
                      ),
                    ),
                    const SizedBox(height: _aboveGap),
                    SizedBox(
                      height: _barHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _NotchedBarPainter(
                                center: center,
                                color: barColor,
                                borderColor: borderColor,
                                borderWidth: borderWidth,
                              ),
                            ),
                          ),
                          for (int i = 0; i < items.length; i++)
                            _buildItem(i, position, itemWidth),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: center - _bubbleRadius,
                  bottom: _barHeight - _bubbleRadius,
                  child: _buildBubble(position),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildAbove(double center) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: aboveHidden ? 1 : 0),
      duration: const Duration(milliseconds: 420),
      // Accelerates into the bubble, and pops out of it quickly on the way back.
      curve: aboveHidden ? Curves.easeInCubic : Curves.easeOutCubic,
      child: CustomPaint(
        painter: _AboveBarShadowPainter(center: center),
        child: ClipPath(
          clipper: _AboveBarClipper(center: center),
          child: above,
        ),
      ),
      builder: (context, suck, bar) {
        // Flattens first, then narrows: drawn in rather than merely shrunk.
        final double scaleY = 1 - suck;
        final double scaleX = 1 - suck * suck;
        return Offstage(
          offstage: suck >= 1,
          child: Opacity(
            opacity: (1 - (suck - 0.6) / 0.4).clamp(0.0, 1.0),
            child: Transform(
              // Relative to the bar's bottom-left corner: converges on the
              // bubble's center, wherever it is on its way.
              alignment: Alignment.bottomLeft,
              transform: Matrix4.diagonal3Values(scaleX, scaleY, 1)
                ..setTranslationRaw(
                    center * (1 - scaleX), _aboveGap * (1 - scaleY), 0),
              child: bar,
            ),
          ),
        );
      },
    );
  }

  // How much the bubble covers item [index]: 1 on it, 0 from one slot away.
  double _coverage(int index, double position) =>
      (1 - (position - index).abs()).clamp(0.0, 1.0);

  Widget _buildItem(int index, double position, double itemWidth) {
    final double covered = _coverage(index, position);
    return Positioned(
      left: _sideInset + index * itemWidth,
      width: itemWidth,
      top: 0,
      bottom: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelected(index),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Opacity(
              opacity: 1 - covered,
              child: Icon(items[index].icon, size: 22, color: iconColor),
            ),
            const SizedBox(height: 2),
            Text(
              items[index].label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: covered > 0.5 ? FontWeight.w700 : FontWeight.w500,
                color: Color.lerp(labelColor, selectedLabelColor, covered),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(double position) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        width: _bubbleRadius * 2,
        height: _bubbleRadius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: bubbleGradient,
        ),
        // The icons of the items it travels between crossfade inside it.
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (int i = 0; i < items.length; i++)
              if (_coverage(i, position) > 0)
                Opacity(
                  opacity: _coverage(i, position),
                  child: Icon(items[i].icon, size: 22, color: bubbleIconColor),
                ),
          ],
        ),
      ),
    );
  }
}

const double _cornerRadius = 16;
const double _minCornerRadius = 6;
const double _shoulderRadius = 10;

// A rounded rect of [size] with a notch cut into its top edge: part of a
// circle whose center is [centerAbove] above that edge, at x = [center]. Its
// rounded shoulders tighten near a side so the bar's corner still has room.
Path _notchedBarPath(Size size, double center, double centerAbove) {
  const double radius = NotchedDock._notchRadius;
  final double w = size.width, h = size.height;

  double shoulderFor(double room) {
    final double available = room - _minCornerRadius;
    final double fit =
        (available * available - radius * radius + centerAbove * centerAbove) /
            (2 * (radius - centerAbove));
    return fit.clamp(2.0, _shoulderRadius);
  }

  double reachOf(double shoulder) => math.sqrt(
      math.pow(radius + shoulder, 2) - math.pow(shoulder + centerAbove, 2));

  // Where a shoulder meets the notch circle.
  Offset tangent(double reach, double shoulder, double side) {
    final double ratio = radius / (radius + shoulder);
    return Offset(center + side * reach * ratio,
        -centerAbove + (shoulder + centerAbove) * ratio);
  }

  final double leftShoulder = shoulderFor(center);
  final double rightShoulder = shoulderFor(w - center);
  final double leftReach = reachOf(leftShoulder);
  final double rightReach = reachOf(rightShoulder);
  final double leftCorner =
      (center - leftReach).clamp(_minCornerRadius, _cornerRadius);
  final double rightCorner =
      (w - center - rightReach).clamp(_minCornerRadius, _cornerRadius);

  return Path()
    ..moveTo(0, leftCorner)
    ..arcToPoint(Offset(leftCorner, 0), radius: Radius.circular(leftCorner))
    ..lineTo(center - leftReach, 0)
    ..arcToPoint(tangent(leftReach, leftShoulder, -1),
        radius: Radius.circular(leftShoulder))
    ..arcToPoint(tangent(rightReach, rightShoulder, 1),
        radius: const Radius.circular(radius), clockwise: false)
    ..arcToPoint(Offset(center + rightReach, 0),
        radius: Radius.circular(rightShoulder))
    ..lineTo(w - rightCorner, 0)
    ..arcToPoint(Offset(w, rightCorner), radius: Radius.circular(rightCorner))
    ..lineTo(w, h - _cornerRadius)
    ..arcToPoint(Offset(w - _cornerRadius, h),
        radius: const Radius.circular(_cornerRadius))
    ..lineTo(_cornerRadius, h)
    ..arcToPoint(Offset(0, h - _cornerRadius),
        radius: const Radius.circular(_cornerRadius))
    ..close();
}

// Same soft shadow under both bars, following their notches.
void _paintBarShadow(Canvas canvas, Path path) {
  canvas.drawPath(
    path.shift(const Offset(0, 4)),
    Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
  );
}

// The bar above: the same shape upside down, notched on its bottom edge.
Path _aboveBarPath(Size size, double center) {
  // Hidden (the mini-player on the Radios tab): nothing to shape.
  if (size.height <= NotchedDock.aboveNotchDepth) return Path();
  final Float64List flipped = Float64List.fromList(
      [1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 0, size.height, 0, 1]);
  return _notchedBarPath(size, center, NotchedDock._aboveGap)
      .transform(flipped);
}

class _AboveBarClipper extends CustomClipper<Path> {
  final double center;

  const _AboveBarClipper({required this.center});

  @override
  Path getClip(Size size) => _aboveBarPath(size, center);

  @override
  bool shouldReclip(_AboveBarClipper oldClipper) => oldClipper.center != center;
}

class _AboveBarShadowPainter extends CustomPainter {
  final double center;

  const _AboveBarShadowPainter({required this.center});

  @override
  void paint(Canvas canvas, Size size) =>
      _paintBarShadow(canvas, _aboveBarPath(size, center));

  @override
  bool? hitTest(Offset position) => false;

  @override
  bool shouldRepaint(_AboveBarShadowPainter oldDelegate) =>
      oldDelegate.center != center;
}

class _NotchedBarPainter extends CustomPainter {
  final double center;
  final Color color;
  final Color borderColor;
  final double borderWidth;

  const _NotchedBarPainter({
    required this.center,
    required this.color,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = _notchedBarPath(size, center, 0);
    _paintBarShadow(canvas, path);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..color = borderColor,
    );
  }

  // The bar's own paint takes no taps, only the items and the bubble do.
  @override
  bool? hitTest(Offset position) => false;

  @override
  bool shouldRepaint(_NotchedBarPainter oldDelegate) =>
      oldDelegate.center != center ||
      oldDelegate.color != color ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderWidth != borderWidth;
}
