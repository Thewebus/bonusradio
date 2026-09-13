import 'package:flutter/material.dart';
import 'package:myBonus/utils/color.dart';

/// Pink-to-blue gradient pill button (primary CTA), used across LIVE NEON
/// (night-theme) screens for "Écouter"/"Regarder"/"En écoute"-style actions.
class LiveNeonGradientButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;
  final Color textColor;

  const LiveNeonGradientButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = white,
    this.textColor = white,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: liveNeonGradient),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dark translucent outline pill button (secondary action), used alongside
/// LiveNeonGradientButton for "Regarder"/"Ma liste"-style secondary CTAs.
class LiveNeonOutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const LiveNeonOutlineButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: liveNeonBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
