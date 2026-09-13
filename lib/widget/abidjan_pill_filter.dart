import 'package:flutter/material.dart';
import 'package:myBonus/utils/color.dart';
import 'package:myBonus/widget/mytext.dart';

/// Horizontal row of filter pills for ABIDJAN (day-theme) screens (e.g.
/// Podcast categories). Active pill = solid black / white text, inactive =
/// white / gray outline.
class AbidjanPillFilterRow extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final bool multilanguage;

  const AbidjanPillFilterRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.multilanguage = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final isActive = option == selected;
          return InkWell(
            onTap: () => onSelected(option),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? black : white,
                borderRadius: BorderRadius.circular(20),
                border: isActive ? null : Border.all(color: abidjanPillBorder),
              ),
              child: MyText(
                color: isActive ? white : gray,
                text: option,
                multilanguage: multilanguage,
                inter: 1,
                fontsize: 13,
                fontwaight: isActive ? FontWeight.w600 : FontWeight.w500,
                maxline: 1,
                textalign: TextAlign.center,
                fontstyle: FontStyle.normal,
              ),
            ),
          );
        },
      ),
    );
  }
}
