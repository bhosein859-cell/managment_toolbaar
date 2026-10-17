import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class CalculatorFormula extends StatelessWidget {
  const CalculatorFormula({super.key, required this.latex});
  final String latex;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('فرمول صرفاً نمایشی است و کدی از آن اجرا نمی‌شود.'),
      const SizedBox(height: 12),
      Semantics(
        label: 'فرمول ریاضی؛ توضیح محاسبه در بخش فرض‌ها و توضیح پارامترها آمده است.',
        excludeSemantics: true,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Math.tex(
              latex,
              key: const Key('formula-display'),
              mathStyle: MathStyle.display,
              textStyle: Theme.of(context).textTheme.titleLarge,
              onErrorFallback: (_) => const Text(
                'نمایش ریاضی ممکن نیست؛ متن فرمول در بخش زیر در دسترس است.',
              ),
            ),
          ),
        ),
      ),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text('متن LaTeX و کپی فرمول'),
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: SelectableText(latex, key: const Key('formula-text')),
          ),
        ],
      ),
    ],
  );
}
