import 'package:flutter/material.dart';

import '../../domain/calculator_domain.dart';
import '../formatting/calculator_text.dart';

class CalculatorResultCard extends StatelessWidget {
  const CalculatorResultCard({
    super.key,
    required this.result,
    this.onCopy,
    this.onShare,
    this.actionsBusy = false,
  });
  final CalculationResult? result;
  final VoidCallback? onCopy, onShare;
  final bool actionsBusy;
  static const pdfDisabledReason =
      'خروجی PDF غیرفعال است: آزمون pdf 3.13.1 با قلم محلی، ترتیب متن ترکیبی فارسی/لاتین، واحد دما و پرانتزها را درست نمایش نداد. کپی یا اشتراک متنی در دسترس است.';

  @override
  Widget build(BuildContext context) {
    final value = result;
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      child: Card(
        color: colors.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'نتیجه',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 12),
              if (value == null)
                const Text(
                  'برای محاسبه، ورودی‌های معتبر را تکمیل کنید.',
                  key: Key('no-result'),
                )
              else ...[
                Text(value.primary.label),
                const SizedBox(height: 8),
                Semantics(
                  liveRegion: true,
                  label:
                      '${value.primary.label}: ${resultValueText(value.primary.value)}',
                  excludeSemantics: true,
                  child: SelectableText(
                    resultValueText(value.primary.value),
                    key: const Key('primary-result'),
                    textDirection: value.primary.value is TextResultValue
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(color: colors.onPrimaryContainer),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'نمایش عددی با گرد کردن تا ۶ رقم اعشار؛ مقادیر خیلی کوچک/بزرگ به صورت علمی.',
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('result-copy'),
                      onPressed: actionsBusy ? null : onCopy,
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('کپی سریع'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('result-share'),
                      onPressed: actionsBusy ? null : onShare,
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('اشتراک متنی'),
                    ),
                    const Tooltip(
                      message: pdfDisabledReason,
                      child: OutlinedButton(
                        onPressed: null,
                        child: Text(
                          'PDF (غیرفعال)',
                          key: Key('result-pdf-disabled'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(pdfDisabledReason, key: Key('pdf-disabled-reason')),
                const SizedBox(height: 12),
                for (final metric in value.details) ...[
                  const SizedBox(height: 12),
                  Text(metric.label),
                  SelectableText(
                    resultValueText(metric.value),
                    textDirection: metric.value is TextResultValue
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                  ),
                ],
                for (final warning in value.warnings)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      warning.severity == WarningSeverity.caution
                          ? Icons.warning_amber
                          : Icons.info_outline,
                    ),
                    title: Text(warning.message),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
