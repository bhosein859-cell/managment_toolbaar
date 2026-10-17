import 'package:flutter/material.dart';

import '../../../../core/utils/persian_numbers.dart';
import '../../../calculators/domain/calculator_domain.dart';
import '../../../calculators/presentation/formatting/calculator_text.dart';
import '../../../home/domain/tool_catalog.dart';
import '../../../home/presentation/controllers/tool_session_controller.dart';
import '../../../home/presentation/widgets/tool_tile.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({
    super.key,
    required this.catalog,
    required this.session,
    required this.onOpen,
  });
  final ToolCatalog catalog;
  final ToolSessionController session;
  final void Function(String, RawCalculatorInput) onOpen;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('تاریخچهٔ محاسبات')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
              key: const Key('history-list'),
              padding: const EdgeInsets.all(20),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    '${PersianNumbers.format(session.recent.length)} ثبت از حداکثر ۱۰ محاسبهٔ اخیر',
                    key: const Key('history-count'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'جدیدترین ثبت در ابتداست. با انتخاب هر مورد، همان ورودی‌های ذخیره‌شده باز می‌شوند. تاریخ و ساعت بر اساس ساعت محلی دستگاه و تقویم میلادی‌اند.',
                ),
                if (session.lastError != null)
                  Semantics(liveRegion: true, child: Text(session.lastError!)),
                const SizedBox(height: 16),
                if (session.recent.isEmpty)
                  const Text(
                    'هنوز محاسبه‌ای ثبت نشده است.',
                    key: Key('history-empty'),
                  ),
                for (final record in session.recent)
                  ToolTile(
                    tool: catalog.toolById(record.calculatorId)!,
                    prefix: 'history-${record.sequence}',
                    isFavorite: session.isFavorite(record.calculatorId),
                    onFavorite: session.isBusy
                        ? null
                        : () => session.toggleFavorite(record.calculatorId),
                    onOpen: () => onOpen(record.calculatorId, record.inputs),
                    subtitle:
                        'ثبت ${PersianNumbers.format(record.sequence)} · \u2066${_localDate(record.createdAt)}\u2069\nنتیجهٔ ثبت‌شده: \u2068${resultValueText(record.result.primary.value)}\u2069',
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  static String _localDate(DateTime time) {
    final t = time.toLocal();
    String pad(int x) => x.toString().padLeft(2, '0');
    return PersianNumbers.toPersian(
      '${t.year}/${pad(t.month)}/${pad(t.day)}  ${pad(t.hour)}:${pad(t.minute)}',
    );
  }
}
