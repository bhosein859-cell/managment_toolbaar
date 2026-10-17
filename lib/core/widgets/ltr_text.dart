import 'package:flutter/material.dart';

/// Isolates formulas / Latin tokens instead of flipping the whole page.
class LtrText extends StatelessWidget {
  const LtrText(this.text, {super.key, this.style});
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Text(text, style: style, textAlign: TextAlign.start),
  );
}
