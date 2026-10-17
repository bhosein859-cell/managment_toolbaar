import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/interaction_support.dart';

import '../../domain/calculator_domain.dart';
import '../controllers/calculator_form_controller.dart';
import '../formatting/calculator_text.dart';
import '../formatting/result_text_export.dart';
import '../services/result_actions.dart';
import '../widgets/calculator_field.dart';
import '../widgets/calculator_formula.dart';
import '../widgets/calculator_result_card.dart';

class CalculatorPage<I extends CalculatorParameters> extends StatefulWidget {
  const CalculatorPage({
    super.key,
    required this.runner,
    this.initialInput,
    this.isFavorite = false,
    this.storageBusy = false,
    this.storageError,
    this.onToggleFavorite,
    this.onSaveCalculation,
    this.resultActions = const PlatformResultActions(),
  });
  final CalculatorRunner<I> runner;
  final ResultActions resultActions;
  final RawCalculatorInput? initialInput;
  final bool isFavorite;
  final bool storageBusy;
  final String? storageError;
  final VoidCallback? onToggleFavorite;
  final void Function(RawCalculatorInput inputs, CalculationResult result)?
  onSaveCalculation;

  @override
  State<CalculatorPage<I>> createState() => _CalculatorPageState<I>();
}

class _CalculatorPageState<I extends CalculatorParameters>
    extends State<CalculatorPage<I>> {
  late CalculatorFormController<I> _form;
  bool _exportBusy = false;
  final _textControllers = <String, TextEditingController>{};
  final _fieldFocus = <String, FocusNode>{};

  @override
  void initState() {
    super.initState();
    _configure();
  }

  void _configure() {
    _form = CalculatorFormController(
      runner: widget.runner,
      initialInput: widget.initialInput,
    );
    for (final field in _form.definition.fields) {
      _fieldFocus[field.id] = FocusNode(debugLabel: field.label);
      if (field is! ChoiceFieldDefinition) {
        _textControllers[field.id] = TextEditingController(
          text: _form.textFor(field.id),
        );
      }
    }
  }

  void _disposeControllers() {
    _form.dispose();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    _textControllers.clear();
    for (final node in _fieldFocus.values) {
      node.dispose();
    }
    _fieldFocus.clear();
  }

  @override
  void didUpdateWidget(covariant CalculatorPage<I> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.runner, widget.runner) ||
        !identical(oldWidget.initialInput, widget.initialInput)) {
      _disposeControllers();
      _configure();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _syncText() {
    FocusManager.instance.primaryFocus?.unfocus();
    for (final entry in _textControllers.entries) {
      final text = _form.textFor(entry.key);
      entry.value.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  void _focusInputs() {
    if (_fieldFocus.isEmpty) return;
    final node = _fieldFocus.values.first;
    node.requestFocus();
    if (node.context != null) {
      Scrollable.ensureVisible(
        node.context!,
        duration: interactionDuration(context),
        alignment: .2,
      );
    }
  }

  void _saveCurrent() {
    final result = _form.result;
    if (result != null && !widget.storageBusy) {
      widget.onSaveCalculation?.call(_form.inputs, result);
    }
  }

  Future<void> _exportResult(bool share) async {
    // Snapshot all three together at tap time, never from an older built frame.
    final current = _form.result;
    if (_exportBusy || current == null) return;
    final definition = _form.definition, inputs = _form.inputs;
    setState(() => _exportBusy = true);
    String message;
    try {
      final text = ResultTextExport.format(definition, inputs, current);
      if (share) {
        final box = context.findRenderObject();
        final origin = box is RenderBox && box.hasSize
            ? box.localToGlobal(Offset.zero) & box.size
            : null;
        final status = await widget.resultActions.shareText(
          text,
          origin: origin,
        );
        message = switch (status) {
          ResultShareStatus.shared =>
            'نتیجه به رابط اشتراک سیستم تحویل شد؛ دریافت آن تأیید نمی‌شود.',
          ResultShareStatus.dismissed => 'اشتراک لغو شد.',
          ResultShareStatus.unavailable => 'سیستم وضعیت اشتراک را گزارش نکرد؛ ممکن است برنامهٔ مقصد باز شده باشد. در صورت نیاز از کپی استفاده کنید.',
        };
      } else {
        await widget.resultActions.copyText(text);
        message = 'متن نتیجه کپی شد.';
      }
    } catch (_) {
      message = share
          ? 'اشتراک متنی انجام نشد؛ از کپی نتیجه استفاده کنید.'
          : 'کپی انجام نشد؛ دسترسی به کلیپ‌بورد را بررسی کنید.';
    }
    if (!mounted) return;
    setState(() => _exportBusy = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _section(BuildContext context, String title, List<Widget> children) =>
      Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _form,
    builder: (context, _) {
      final definition = _form.definition;
      final result = _form.result;
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(
            LogicalKeyboardKey.keyI,
            alt: true,
            includeRepeats: false,
          ): _focusInputs,
          const SingleActivator(
            LogicalKeyboardKey.enter,
            control: true,
            includeRepeats: false,
          ): _saveCurrent,
        },
        child: Focus(
          autofocus: true,
          skipTraversal: true,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                definition.nameFa,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                if (widget.onToggleFavorite != null)
                  IconButton(
                    key: const Key('calculator-favorite'),
                    tooltip: widget.isFavorite
                        ? 'حذف از علاقه‌مندی‌ها'
                        : 'افزودن به علاقه‌مندی‌ها',
                    onPressed: widget.storageBusy
                        ? null
                        : widget.onToggleFavorite,
                    icon: Icon(
                      widget.isFavorite
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                    ),
                  ),
                if (widget.onSaveCalculation != null)
                  IconButton(
                    key: const Key('calculator-save'),
                    tooltip: 'ثبت در آخرین محاسبات',
                    onPressed: result == null || widget.storageBusy
                        ? null
                        : _saveCurrent,
                    icon: const Icon(Icons.bookmark_add_outlined),
                  ),
                IconButton(
                  key: const Key('focus-inputs'),
                  tooltip: 'رفتن به اولین ورودی (Alt+I)',
                  icon: const Icon(Icons.edit_note),
                  onPressed: _focusInputs,
                ),
                IconButton(
                  tooltip: 'بازنشانی ورودی‌ها',
                  icon: const Icon(Icons.restart_alt),
                  onPressed: () {
                    _form.reset();
                    _syncText();
                  },
                ),
              ],
            ),
            body: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: SingleChildScrollView(
                    key: const Key('calculator-scroll'),
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      20,
                      16,
                      20,
                      32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.storageError != null)
                          Text(
                            widget.storageError!,
                            key: const Key('calculator-storage-error'),
                          ),
                        Text(definition.description),
                        const SizedBox(height: 16),
                        CalculatorResultCard(
                          result: result,
                          onCopy: () => _exportResult(false),
                          onShare: () => _exportResult(true),
                          actionsBusy: _exportBusy,
                        ),
                        if (_form.globalIssues.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              _form.globalIssues
                                  .map((issue) => issue.message)
                                  .join('\n'),
                              key: const Key('global-errors'),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        _section(context, 'ورودی‌ها', [
                          for (final field in definition.fields)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: CalculatorField(
                                field: field,
                                rawText: _form.textFor(field.id),
                                textController: _textControllers[field.id],
                                focusNode: _fieldFocus[field.id],
                                errors: _form.issuesFor(field.id),
                                onChanged: (value) =>
                                    _form.updateField(field.id, value),
                              ),
                            ),
                        ]),
                        _section(context, 'فرمول', [
                          CalculatorFormula(latex: definition.formulaLatex),
                        ]),
                        _section(context, 'توضیح پارامترها', [
                          for (final field in definition.fields)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    field.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (field.unit != null)
                                    Text('واحد: \u2066${field.unit}\u2069'),
                                  if (fieldGuidance(field).isNotEmpty)
                                    Text(fieldGuidance(field)),
                                ],
                              ),
                            ),
                        ]),
                        if (definition.assumptions.isNotEmpty)
                          _section(context, 'فرض‌ها و محدودیت‌ها', [
                            Text(definition.assumptions),
                          ]),
                        _section(context, 'مثال', [
                          if (definition.examples.isEmpty)
                            const Text(
                              'برای این ابزار هنوز مثالی ثبت نشده است.',
                            ),
                          for (
                            var index = 0;
                            index < definition.examples.length;
                            index++
                          )
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      definition.examples[index].title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    Text(
                                      definition.examples[index].explanation,
                                    ),
                                    if (definition
                                            .examples[index]
                                            .expectedResult !=
                                        null)
                                      Text(
                                        'نتیجهٔ مورد انتظار مثال: \u2066${resultValueText(definition.examples[index].expectedResult!.primary.value)}\u2069',
                                      ),
                                    const SizedBox(height: 8),
                                    OutlinedButton(
                                      key: Key('load-example-$index'),
                                      onPressed: () {
                                        _form.replaceInputs(
                                          definition.examples[index].inputs,
                                        );
                                        _syncText();
                                      },
                                      child: const Text(
                                        'قرار دادن ورودی‌های مثال',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ]),
                        _section(context, 'تفسیر', [
                          Text(
                            result == null
                                ? 'تفسیر پس از معتبر شدن ورودی‌ها نمایش داده می‌شود.'
                                : result.interpretation.isEmpty
                                ? 'تفسیری برای این نتیجه ثبت نشده است.'
                                : result.interpretation,
                            key: const Key('result-interpretation'),
                          ),
                        ]),
                        if (definition.relatedTerms.isNotEmpty)
                          _section(context, 'واژه‌های مرتبط', [
                            for (final term in definition.relatedTerms)
                              Text('${term.nameFa}: ${term.description}'),
                          ]),
                      ],
                    ),
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
