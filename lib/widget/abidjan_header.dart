import 'package:flutter/material.dart';
import 'package:myBonus/utils/color.dart';
import 'package:myBonus/utils/dimens.dart';
import 'package:myBonus/widget/mytext.dart';

/// A small circular white icon button, used for the back/action buttons on
/// ABIDJAN (day-theme) flat-cream headers.
class AbidjanCircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  const AbidjanCircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: black, size: size * 0.45),
      ),
    );
  }
}

/// Flat-cream, inline-title header used by every ABIDJAN (day-theme) screen
/// in place of MyAppbar's gradient-header modes. MyAppbar itself is left
/// untouched — night mode keeps using it exactly as before.
class AbidjanHeader extends StatelessWidget {
  final String title;
  final bool multilanguage;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;

  const AbidjanHeader({
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
            AbidjanCircleIconButton(
              icon: Icons.arrow_back,
              onTap: onBack ?? () => Navigator.maybePop(context),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: MyText(
              color: black,
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
