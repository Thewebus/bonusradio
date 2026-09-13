import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:myBonus/utils/color.dart';

/// A rounded card filled with one of [abidjanBokehGradients] plus a soft
/// blurred color blob for extra depth — used for the "Tendances"/"Rubriques"
/// style featured cards on ABIDJAN (day-theme) screens.
class AbidjanBokehCard extends StatelessWidget {
  final int index;
  final Widget? child;
  final BorderRadius? borderRadius;

  const AbidjanBokehCard({
    super.key,
    required this.index,
    this.child,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colors = abidjanBokehGradients[index % abidjanBokehGradients.length];
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
                    color: colors.last.withValues(alpha: 0.5),
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
