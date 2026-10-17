import 'package:flutter/material.dart';

import '../../../core/utils/persian_numbers.dart';
import '../../../core/widgets/interaction_support.dart';
import '../../calculators/domain/calculator_domain.dart';
import '../domain/glossary_catalog.dart';

class GlossaryPage extends StatefulWidget {
  const GlossaryPage({
    super.key,
    required this.catalog,
    required this.onOpenCalculator,
  });
  final GlossaryCatalog catalog;
  final ValueChanged<String> onOpenCalculator;
  @override
  State<GlossaryPage> createState() => _GlossaryPageState();
}

class _GlossaryPageState extends State<GlossaryPage> {
  String _query = '';
  CalculatorCategoryId? _category;
  final _focus = FocusNode(debugLabel: 'glossary search');
  final _controller = TextEditingController();
  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.catalog.search(_query, category: _category);
    final search = TextField(
      key: const Key('glossary-search'),
      controller: _controller,
      focusNode: _focus,
      decoration: const InputDecoration(
        labelText: 'جست‌وجوی فارسی یا انگلیسی',
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: (value) => setState(() => _query = value),
    );
    final filter = DropdownButtonFormField<String>(
      key: const Key('glossary-category'),
      initialValue: _category?.name ?? 'all',
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'دستهٔ اصطلاح'),
      items: [
        const DropdownMenuItem(value: 'all', child: Text('همهٔ دسته‌ها')),
        for (final category in widget.catalog.tools.categories)
          DropdownMenuItem(
            value: category.id.name,
            child: Text(
              category.nameFa,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (id) => setState(
        () => _category = id == null || id == 'all'
            ? null
            : CalculatorCategoryId.values.byName(id),
      ),
    );
    return SearchShortcuts(
      focusNode: _focus,
      child: Scaffold(
        appBar: AppBar(title: const Text('واژه‌نامهٔ آفلاین')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: CustomScrollView(
                key: const Key('glossary-list'),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'اصطلاحات فارسی و انگلیسی؛ توضیح کوتاه و پیوند به محاسبه‌گرهای مرتبط. تمام محتوا روی دستگاه است.',
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, box) => box.maxWidth >= 720
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: search),
                                      const SizedBox(width: 16),
                                      Expanded(child: filter),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      search,
                                      const SizedBox(height: 16),
                                      filter,
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 12),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              '${PersianNumbers.format(entries.length)} اصطلاح',
                              key: const Key('glossary-count'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (entries.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'اصطلاحی پیدا نشد.',
                          key: Key('glossary-empty'),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList.builder(
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return Card(
                            key: Key('term-${entry.id}'),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Semantics(
                                    header: true,
                                    child: Text(
                                      entry.nameFa,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ),
                                  Text(
                                    entry.nameEn,
                                    textDirection: TextDirection.ltr,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.catalog.tools
                                        .categoryById(entry.categoryId)!
                                        .nameFa,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(entry.summary),
                                  if (entry.summary != entry.description)
                                    ExpansionTile(
                                      title: const Text('توضیح کامل'),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text(entry.description),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final id in entry.calculatorIds)
                                        OutlinedButton.icon(
                                          key: Key('term-link-${entry.id}-$id'),
                                          onPressed: () =>
                                              widget.onOpenCalculator(id),
                                          icon: const Icon(
                                            Icons.calculate_outlined,
                                          ),
                                          label: Text(
                                            widget.catalog.tools
                                                .toolById(id)!
                                                .nameFa,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
