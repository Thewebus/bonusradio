import 'package:flutter/material.dart';
import 'package:myBonus/utils/color.dart';
import 'package:myBonus/utils/dimens.dart';
import 'package:myBonus/widget/mytext.dart';

/// A small dark rounded-square icon button, used for the back/action
/// buttons on LIVE NEON (night-theme) headers — mirrors
/// AbidjanCircleIconButton's role but dark-on-glow instead of white-on-cream.
class LiveNeonCircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color iconColor;

  const LiveNeonCircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 44,
    this.iconColor = white,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size * 0.32),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: liveNeonCardBg,
          borderRadius: BorderRadius.circular(size * 0.32),
          border: Border.all(color: liveNeonBorder),
        ),
        child: Icon(icon, color: iconColor, size: size * 0.45),
      ),
    );
  }
}

/// Flat dark, inline-title header used by every LIVE NEON (night-theme)
/// screen in place of MyAppbar's old gradient-header modes. MyAppbar itself
/// is left untouched — not-yet-migrated night screens keep using it as
/// before, exactly like ABIDJAN's day rollout did.
class LiveNeonHeader extends StatelessWidget {
  final String title;
  final bool multilanguage;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;

  const LiveNeonHeader({
    super.key,
    required this.title,
    this.multilanguage = true,
    this.showBack = false,
    this.onBack,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          if (showBack) ...[
            LiveNeonCircleIconButton(
              icon: Icons.arrow_back,
              onTap: onBack ?? () => Navigator.maybePop(context),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: MyText(
              color: white,
              text: title,
              multilanguage: multilanguage,
              inter: 4,
              fontsize: Dimens.textExtraBig,
              fontwaight: FontWeight.w700,
              maxline: 1,
              textalign: TextAlign.left,
              fontstyle: FontStyle.normal,
            ),
          ),
          for (final action in actions) ...[
            const SizedBox(width: 10),
            action,
          ],
        ],
      ),
    );
  }
}
