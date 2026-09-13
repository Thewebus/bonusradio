import 'package:flutter/material.dart';
import 'package:myBonus/utils/color.dart';
import 'package:myBonus/utils/dimens.dart';
import 'package:myBonus/widget/mytext.dart';

class LiveNeonStat {
  final String value;
  final String label;

  const LiveNeonStat({required this.value, required this.label});
}

/// Row of stats separated by thin vertical dividers (bold white value, gray
/// label underneath) — used on the LIVE NEON (night-theme) Compte screen.
/// Mirrors AbidjanStatRow with the neon palette instead of black/gray.
class LiveNeonStatRow extends StatelessWidget {
  final List<LiveNeonStat> stats;

  const LiveNeonStatRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < stats.length; i++) {
      if (i > 0) {
        children.add(Container(width: 1, height: 32, color: liveNeonBorder));
      }
      children.add(
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyText(
                color: white,
                text: stats[i].value,
                multilanguage: false,
                inter: 1,
                fontsize: Dimens.textBig,
                fontwaight: FontWeight.w700,
                maxline: 1,
                textalign: TextAlign.center,
                fontstyle: FontStyle.normal,
              ),
              const SizedBox(height: 2),
              MyText(
                color: liveNeonTextSecondary,
                text: stats[i].label,
                multilanguage: false,
                inter: 1,
                fontsize: Dimens.textSmall,
                fontwaight: FontWeight.w500,
                maxline: 1,
                textalign: TextAlign.center,
                fontstyle: FontStyle.normal,
              ),
            ],
          ),
        ),
      );
    }
    return Row(children: children);
  }
}
