import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:myBonus/utils/color.dart';

/// A rounded card filled with one of [liveNeonBokehGradients] plus a soft
/// blurred glow blob for extra depth — used for "Tendances"/"Rubriques"
/// style featured cards on LIVE NEON (night-theme) screens. Mirrors
/// AbidjanBokehCard's structure with a darker, more saturated palette.
class LiveNeonBokehCard extends StatelessWidget {
  final int index;
  final Widget? child;
  final BorderRadius? borderRadius;

  const LiveNeonBokehCard({
    super.key,
    required this.index,
    this.child,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        liveNeonBokehGradients[index % liveNeonBokehGradients.length];
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -30,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.first.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}
