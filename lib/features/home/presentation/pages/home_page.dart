import 'package:flutter/material.dart';

import '../../../../core/utils/persian_numbers.dart';
import '../../../../core/widgets/interaction_support.dart';
import '../../../calculators/calculators.dart';
import '../../domain/catalog_search.dart';
import '../../domain/tool_catalog.dart';
import '../controllers/tool_session_controller.dart';
import '../widgets/category_grid.dart';
import '../widgets/tool_tile.dart';

typedef OpenCalculator = void Function(String id, [RawCalculatorInput? inputs]);

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.catalog,
    required this.session,
    required this.onOpenCalculator,
    required this.onOpenCategory,
    required this.onAllCategories,
  });
  final ToolCatalog catalog;
  final ToolSessionController session;
  final OpenCalculator onOpenCalculator;
  final ValueChanged<CalculatorCategoryId> onOpenCategory;
  final VoidCallback onAllCategories;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _query = TextEditingController();
  final _searchFocus = FocusNode(debugLabel: 'home search');
  late CatalogSearch _search;
  List<CatalogSearchHit> _hits = const [];
  @override
  void initState() {
    super.initState();
    _search = CatalogSearch(widget.catalog);
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.catalog, widget.catalog)) {
      _search = CatalogSearch(widget.catalog);
      _hits = _search.search(_query.text);
    }
  }

  @override
  void dispose() {
    _query.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Widget _heading(String text, {Widget? action}) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(0, 24, 0, 12),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      children: [
        Semantics(
          header: true,
          child: Text(text, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?action,
      ],
    ),
  );

  Widget _tile(
    CalculatorDefinition tool,
    String prefix, {
    bool fuzzy = false,
  }) => ToolTile(
    tool: tool,
    prefix: prefix,
    isFavorite: widget.session.isFavorite(tool.id),
    approximate: fuzzy,
    onOpen: () => widget.onOpenCalculator(tool.id),
    onFavorite: widget.session.isBusy
        ? null
        : () => widget.session.toggleFavorite(tool.id),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.session,
    builder: (context, _) {
      final session = widget.session;
      final favorites = widget.catalog.tools
          .where((tool) => session.isFavorite(tool.id))
          .toList();
      final searching = _query.text.trim().isNotEmpty;
      return SearchShortcuts(
        focusNode: _searchFocus,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'جعبه‌ابزار مدیریت',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                key: const Key('open-glossary'),
                tooltip: 'واژه‌نامهٔ آفلاین',
                icon: const Icon(Icons.menu_book_outlined),
                onPressed: () => Navigator.of(context).pushNamed('/glossary'),
              ),
              IconButton(
                tooltip: 'آزمایش فرم ماشین‌حساب',
                icon: const Icon(Icons.calculate_outlined),
                onPressed: () =>
                    Navigator.of(context).pushNamed('/calculator-demo'),
              ),
              IconButton(
                tooltip: 'آزمایش فارسی',
                icon: const Icon(Icons.text_fields),
                onPressed: () => Navigator.of(context).pushNamed('/typography'),
              ),
              IconButton(
                tooltip: 'تنظیمات',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.of(context).pushNamed('/settings'),
              ),
            ],
          ),
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1140),
                child: SingleChildScrollView(
                  key: const Key('home-scroll'),
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!searching) ...[
                        Card(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'امروز چه چیزی محاسبه می‌کنید؟',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${PersianNumbers.format(widget.catalog.tools.length)} ابزار آماده در ${PersianNumbers.format(widget.catalog.categories.length)} دسته · کاملاً آفلاین',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        key: const Key('home-search'),
                        controller: _query,
                        focusNode: _searchFocus,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          labelText: 'جستجوی ابزار',
                          hintText: 'نام فارسی، انگلیسی یا مترادف',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _query.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'پاک کردن جستجو',
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _query.clear();
                                    setState(() => _hits = const []);
                                  },
                                ),
                        ),
                        onChanged: (text) =>
                            setState(() => _hits = _search.search(text)),
                      ),
                      if (searching) ...[
                        _heading(
                          'نتایج جستجو (${PersianNumbers.format(_hits.length)})',
                        ),
                        if (_hits.isEmpty)
                          const Text(
                            'موردی پیدا نشد؛ نام، مخفف یا مترادف دیگری را امتحان کنید.',
                            key: Key('empty-search'),
                          ),
                        for (final hit in _hits)
                          _tile(
                            hit.tool,
                            'search',
                            fuzzy: hit.match == SearchMatch.fuzzy,
                          ),
                        if (_hits.length == 20)
                          const Text(
                            'حداکثر ۲۰ نتیجه نمایش داده می‌شود؛ عبارت را دقیق‌تر کنید.',
                          ),
                      ] else ...[
                        _heading(
                          'دسته‌بندی‌ها',
                          action: TextButton(
                            onPressed: widget.onAllCategories,
                            child: const Text('همهٔ دسته‌ها'),
                          ),
                        ),
                        CategoryGrid(
                          catalog: widget.catalog,
                          onOpen: widget.onOpenCategory,
                        ),
                        if (session.lastError != null)
                          Text(
                            session.lastError!,
                            key: const Key('storage-write-error'),
                          ),
                        _heading('علاقه‌مندی‌ها'),
                        if (favorites.isEmpty)
                          const Text(
                            'با زدن ستارهٔ کنار ابزار، آن را به علاقه‌مندی‌ها اضافه کنید.',
                            key: Key('empty-favorites'),
                          ),
                        for (final tool in favorites) _tile(tool, 'favorite'),
                        _heading(
                          'آخرین محاسبات',
                          action: TextButton.icon(
                            key: const Key('open-history'),
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/history'),
                            icon: const Icon(Icons.history),
                            label: const Text('نمایش تاریخچه'),
                          ),
                        ),
                        if (session.recent.isEmpty)
                          const Text(
                            'هنوز محاسبه‌ای ثبت نشده است؛ در صفحهٔ ابزار، دکمهٔ ثبت محاسبه را بزنید.',
                            key: Key('empty-recent'),
                          ),
                        for (final record in session.recent)
                          ToolTile(
                            tool: widget.catalog.toolById(record.calculatorId)!,
                            prefix: 'recent-${record.sequence}',
                            subtitle:
                                'نتیجهٔ ثبت‌شده: \u2066${resultValueText(record.result.primary.value)}\u2069',
                            isFavorite: session.isFavorite(record.calculatorId),
                            onFavorite: session.isBusy
                                ? null
                                : () => session.toggleFavorite(
                                    record.calculatorId,
                                  ),
                            onOpen: () => widget.onOpenCalculator(
                              record.calculatorId,
                              record.inputs,
                            ),
                          ),
                        _heading(
                          'ابزارهای آماده (${PersianNumbers.format(widget.catalog.tools.length)})',
                        ),
                        for (final tool in widget.catalog.tools)
                          _tile(tool, 'available'),
                        const SizedBox(height: 20),
                        const Text(
                          'علاقه‌مندی‌ها و حداکثر ۱۰ محاسبهٔ اخیر روی همین دستگاه ذخیره می‌شوند. بازکردن تاریخچه، ورودی‌های قبلی را با موتور فعلی دوباره محاسبه می‌کند.',
                          key: Key('local-storage-notice'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
