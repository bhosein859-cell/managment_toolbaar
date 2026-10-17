import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/catalog/form_demo.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/form_demo_engine.dart';
import 'package:management_toolbox/features/calculators/presentation/controllers/calculator_form_controller.dart';

import 'fixtures.dart';

double primary(CalculatorFormController<FormDemoParameters> form) =>
    (form.result!.primary.value as NumericResultValue).value;

void main() {
  test('defaults are shown and computed through the engine', () {
    final form = CalculatorFormController(runner: FormDemo.runner);
    addTearDown(form.dispose);
    expect(form.textFor('quantity'), '۱۰۰');
    expect(form.textFor('reduction'), '۲۰');
    expect(form.textFor('unit'), 'kg');
    expect(primary(form), 80);
    expect(form.issues, isEmpty);
    expect(form.result!.warnings, isNotEmpty);
  });
  for (final text in ['۲۰۰', '٢٠٠', '200']) {
    test('updates live from $text with percentages converted once', () {
      final form = CalculatorFormController(runner: FormDemo.runner);
      addTearDown(form.dispose);
      form.updateField('quantity', RawTextInput(text));
      form.updateField('reduction', const RawTextInput('۲۵'));
      expect(primary(form), 150);
      expect(form.textFor('quantity'), text);
    });
  }
  test('invalid and partial inputs remove stale result immediately', () {
    final form = CalculatorFormController(runner: FormDemo.runner);
    addTearDown(form.dispose);
    var notifications = 0;
    form.addListener(() => notifications++);
    for (final text in ['NaN', 'Infinity', '', '-', '۱۰۱']) {
      form.updateField('reduction', RawTextInput(text));
      expect(form.result, isNull);
      expect(form.issuesFor('reduction'), isNotEmpty);
    }
    expect(notifications, 5);
    form.updateField('reduction', const RawTextInput('۰'));
    expect(primary(form), 100);
  });
  test('examples replace inputs rather than carrying stale values; reset restores defaults', () {
    final form = CalculatorFormController(runner: FormDemo.runner);
    addTearDown(form.dispose);
    form.updateField('quantity', const RawTextInput('300'));
    form.replaceInputs(FormDemo.definition.examples.single.inputs);
    expect(primary(form), 150);
    expect(form.textFor('unit'), 'hours');
    form.reset();
    expect(primary(form), 80);
    expect(form.textFor('unit'), 'kg');
  });
  test(
    'initial inputs are restored and invalid unknown data is surfaced globally',
    () {
      final form = CalculatorFormController(
        runner: FormDemo.runner,
        initialInput: RawCalculatorInput({
          'quantity': const RawTextInput('50'),
          'unknown': const RawTextInput('2'),
        }),
      );
      addTearDown(form.dispose);
      expect(form.textFor('quantity'), '50');
      expect(form.result, isNull);
      expect(form.globalIssues.single.code, 'unknown_field');
      expect(
        () => form.updateField('bad', const RawTextInput('1')),
        throwsArgumentError,
      );
    },
  );
  test('choice validation and blank defaults follow domain rules', () {
    final form = CalculatorFormController(runner: FormDemo.runner);
    addTearDown(form.dispose);
    form.updateField('unit', const RawTextInput('invalid'));
    expect(form.result, isNull);
    expect(form.issuesFor('unit').single.code, 'invalid_choice');
    form.updateField('unit', const RawTextInput('hours'));
    expect((form.result!.primary.value as NumericResultValue).unit, 'h');
    form.updateField('quantity', const RawTextInput(''));
    expect(form.result, isNull);
    expect(form.issuesFor('quantity').single.code, 'required');
  });
  test('structured lists preserve each item and reject malformed elements', () {
    final form = CalculatorFormController(runner: fixtureRunner(list: true));
    addTearDown(form.dispose);
    expect(form.textFor('values'), '۱\n۲');
    form.updateField('values', RawNumberListInput(['۱', '٢', '3']));
    expect((form.result!.primary.value as NumericResultValue).value, 6);
    form.updateField('values', RawNumberListInput(['۱', 'bad']));
    expect(form.result, isNull);
    expect(form.issuesFor('values').single.itemIndex, 1);
  });
  test(
    'domain and unexpected failures do not retain result or interpretation',
    () {
      final form = CalculatorFormController(runner: fixtureRunner());
      addTearDown(form.dispose);
      for (final text in ['7', '9', '11', '13']) {
        form.updateField('value', RawTextInput(text));
        expect(form.result, isNull);
        expect(form.issues, isNotEmpty);
      }
      expect(form.issuesFor('value').single.code, 'reserved');
      form.updateField('value', const RawTextInput('1'));
      expect(form.result, isNotNull);
    },
  );
  test('demo formula examples and endpoint reductions are correct', () {
    final form = CalculatorFormController(runner: FormDemo.runner);
    addTearDown(form.dispose);
    form.updateField('reduction', const RawTextInput('۱۰۰'));
    expect(primary(form), 0);
    form.updateField('reduction', const RawTextInput('۰'));
    expect(primary(form), 100);
    const engine = FormDemoEngine();
    expect(
      engine.calculate(
        const FormDemoParameters(quantity: -1, reduction: 0.2, unit: 'kg'),
      ),
      isA<CalculationFailure>(),
    );
    expect(
      engine.calculate(
        const FormDemoParameters(
          quantity: double.infinity,
          reduction: 0.2,
          unit: 'kg',
        ),
      ),
      isA<CalculationFailure>(),
    );
    expect(
      engine.bind(
        CalculatorInput({
          'quantity': NumberInputValue(1),
          'reduction': NumberInputValue(0.2),
          'unit': ChoiceInputValue('bad'),
        }),
      ),
      isA<RejectedInput<FormDemoParameters>>(),
    );
  });
}
