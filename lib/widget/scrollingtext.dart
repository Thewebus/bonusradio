import 'package:flutter/material.dart';
import 'package:text_scroll/text_scroll.dart';

// One line of text that scrolls (marquee) only when it doesn't fit its
// width; otherwise a plain, still Text. Used for song titles/artists in the
// players (musicdetails.dart, floating_player.dart).
class ScrollingText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  const ScrollingText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      if (painter.width <= constraints.maxWidth) {
        return Text(text, style: style, maxLines: 1, textAlign: textAlign);
      }
      return TextScroll(
        text,
        // A new text restarts from the beginning.
        key: ValueKey(text),
        style: style,
        mode: TextScrollMode.endless,
        intervalSpaces: 8,
        delayBefore: const Duration(seconds: 2),
        pauseBetween: const Duration(seconds: 2),
        velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
        fadedBorder: true,
        fadeBorderSide: FadeBorderSide.both,
        fadeBorderVisibility: FadeBorderVisibility.auto,
      );
    });
  }
}
