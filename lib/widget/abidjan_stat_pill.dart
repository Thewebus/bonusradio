import 'package:flutter/material.dart';
import 'package:myBonus/utils/color.dart';
import 'package:myBonus/utils/dimens.dart';
import 'package:myBonus/widget/mytext.dart';

class AbidjanStat {
  final String value;
  final String label;

  const AbidjanStat({required this.value, required this.label});
}

/// Row of stats separated by thin vertical dividers (bold value, gray label
/// underneath) — used on the ABIDJAN (day-theme) Compte screen.
class AbidjanStatRow extends StatelessWidget {
  final List<AbidjanStat> stats;

  const AbidjanStatRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < stats.length; i++) {
      if (i > 0) {
        children.add(Container(width: 1, height: 32, color: lightgray));
      }
      children.add(
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyText(
                color: black,
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
                color: gray,
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
