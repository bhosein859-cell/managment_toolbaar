import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/catalog/app_catalog.dart';
import 'package:management_toolbox/app/catalog/utility_calculators.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/utilities/domain/discount.dart';
import 'package:management_toolbox/features/utilities/domain/percentage_base.dart';
import 'package:management_toolbox/features/utilities/domain/percentage_change.dart';
import 'package:management_toolbox/features/utilities/domain/percentage_of.dart';
import 'package:management_toolbox/features/utilities/domain/unit_conversion.dart';

double primary(CalculationOutcome o) =>
    ((o as CalculationSuccess).result.primary.value as NumericResultValue)
        .value;
CalculationOutcome convert(double value, String from, String to) =>
    const UnitConversionEngine().calculate(
      UnitConversionParameters(amount: value, fromUnit: from, toUnit: to),
    );
void main() {
  final references = <String, (String, double)>{
    'mm': ('m', .001),
    'cm': ('m', .01),
    'm': ('m', 1),
    'km': ('m', 1000),
    'inch': ('m', .0254),
    'foot': ('m', .3048),
    'yard': ('m', .9144),
    'cm2': ('m2', .0001),
    'm2': ('m2', 1),
    'hectare': ('m2', 10000),
    'km2': ('m2', 1000000),
    'ml': ('m3', .000001),
    'litre': ('m3', .001),
    'm3': ('m3', 1),
    'mg': ('kg', .000001),
    'g': ('kg', .001),
    'kg': ('kg', 1),
    'tonne': ('kg', 1000),
    'pound': ('kg', .45359237),
    'second': ('second', 1),
    'minute': ('second', 60),
    'hour': ('second', 3600),
    'day': ('second', 86400),
    'metres_second': ('metres_second', 1),
    'km_hour': ('metres_second', .2777777777777778),
    'feet_second': ('metres_second', .3048),
    'pa': ('pa', 1),
    'kpa': ('pa', 1000),
    'mpa': ('pa', 1000000),
    'bar': ('pa', 100000),
    'psi': ('pa', 6894.757293168361),
    'joule': ('joule', 1),
    'kilojoule': ('joule', 1000),
    'megajoule': ('joule', 1000000),
    'watt_hour': ('joule', 3600),
    'kilowatt_hour': ('joule', 3600000),
    'watt': ('watt', 1),
    'kilowatt': ('watt', 1000),
    'megawatt': ('watt', 1000000),
    'celsius': ('kelvin', 274.15),
    'fahrenheit': ('kelvin', 255.92777777777778),
    'kelvin': ('kelvin', 1),
  };
  test('42 explicitly supported units, 10 dimensions and 73 real tools', () {
    expect(
      UnitRegistry.units.map((u) => u.id).toSet(),
      references.keys.toSet(),
    );
    expect(
      UnitRegistry.units.map((u) => u.dimension).toSet(),
      UnitDimension.values.toSet(),
    );
    expect(AppCatalog.catalog.tools, hasLength(73));
    expect(UtilityCalculators.runners, hasLength(5));
    expect(() => UnitRegistry.units.clear(), throwsUnsupportedError);
    expect(() => UnitRegistry.byId.clear(), throwsUnsupportedError);
  });
  for (final ref in references.entries) {
    test('${ref.key}: independent forward and reverse reference', () {
      final (base, expected) = ref.value;
      expect(
        primary(convert(1, ref.key, base)),
        closeTo(expected, expected.abs() * 1e-12 + 1e-12),
      );
      expect(primary(convert(expected, base, ref.key)), closeTo(1, 1e-10));
      expect(primary(convert(1, ref.key, ref.key)), 1);
    });
  }
  for (final from in UnitRegistry.units) {
    for (final to in UnitRegistry.units) {
      if (from.dimension != to.dimension) continue;
      test('${from.id} -> ${to.id}: same-dimension round trip', () {
        final input = from.dimension == UnitDimension.temperature
            ? 1000.0
            : 123.456;
        final value = primary(convert(input, from.id, to.id));
        expect(primary(convert(value, to.id, from.id)), closeTo(input, 1e-8));
      });
    }
  }
  test('freezing, boiling, negative coincidence and exact absolute zero', () {
    expect(primary(convert(32, 'fahrenheit', 'celsius')), 0);
    expect(primary(convert(0, 'celsius', 'fahrenheit')), 32);
    expect(primary(convert(100, 'celsius', 'fahrenheit')), closeTo(212, 1e-12));
    expect(primary(convert(-40, 'fahrenheit', 'celsius')), -40);
    expect(primary(convert(273.15, 'kelvin', 'celsius')), 0);
    for (final u in ['celsius', 'fahrenheit', 'kelvin']) {
      final zero = UnitRegistry.byId[u]!.zero;
      expect(primary(convert(zero, u, 'kelvin')), 0);
      expect(convert(zero - 1e-10, u, 'kelvin'), isA<CalculationFailure>());
    }
  });
  test('invalid dimensions, unknown units, negatives and nonfinite', () {
    for (final o in [
      convert(1, 'm', 'kg'),
      convert(1, 'unknown', 'kg'),
      convert(-1, 'm', 'm'),
      convert(double.nan, 'm', 'cm'),
      convert(double.infinity, 'm', 'm'),
      convert(double.negativeInfinity, 'celsius', 'kelvin'),
    ]) {
      expect(o, isA<CalculationFailure>());
    }
  });
  test(
    'conversion overflow/underflow rejected; same-unit maximal value valid',
    () {
      expect(convert(1e308, 'km', 'mm'), isA<CalculationFailure>());
      expect(convert(5e-324, 'mg', 'tonne'), isA<CalculationFailure>());
      expect(primary(convert(double.maxFinite, 'km', 'km')), double.maxFinite);
      expect(primary(convert(0, 'km', 'mm')), 0);
      expect(primary(convert(1e308, 'mm', 'km')), closeTo(1e302, 1e290));
    },
  );
  test('percent of, over 100%, zero, overflow and underflow', () {
    const e = PercentageOfEngine();
    expect(
      primary(e.calculate(const PercentageOfParameters(amount: 250, rate: .2))),
      50,
    );
    expect(
      primary(e.calculate(const PercentageOfParameters(amount: 10, rate: 1.5))),
      15,
    );
    expect(
      primary(e.calculate(const PercentageOfParameters(amount: 0, rate: 0))),
      0,
    );
    for (final p in [
      const PercentageOfParameters(amount: -1, rate: .2),
      const PercentageOfParameters(amount: 1, rate: -.1),
      const PercentageOfParameters(amount: double.nan, rate: 1),
      const PercentageOfParameters(amount: 1e308, rate: 100),
      const PercentageOfParameters(amount: 5e-324, rate: .01),
    ]) {
      expect(e.calculate(p), isA<CalculationFailure>());
    }
  });
  test('percent change rise, fall, unchanged and zero/negative baseline', () {
    const e = PercentageChangeEngine();
    expect(
      primary(
        e.calculate(
          const PercentageChangeParameters(previous: 100, current: 125),
        ),
      ),
      .25,
    );
    expect(
      primary(
        e.calculate(
          const PercentageChangeParameters(previous: 100, current: 0),
        ),
      ),
      -1,
    );
    expect(
      primary(
        e.calculate(
          const PercentageChangeParameters(previous: 100, current: 100),
        ),
      ),
      0,
    );
    for (final p in [
      const PercentageChangeParameters(previous: 0, current: 0),
      const PercentageChangeParameters(previous: 0, current: 1),
      const PercentageChangeParameters(previous: -100, current: 20),
      const PercentageChangeParameters(previous: 100, current: -1),
      const PercentageChangeParameters(previous: 1e-308, current: 1e308),
      const PercentageChangeParameters(previous: 1, current: double.infinity),
    ]) {
      expect(e.calculate(p), isA<CalculationFailure>());
    }
  });
  test('base from percentage, zero part, above 100%, invalid denominators and range', () {
    const e = PercentageBaseEngine();
    expect(
      primary(e.calculate(const PercentageBaseParameters(part: 50, rate: .2))),
      250,
    );
    expect(
      primary(e.calculate(const PercentageBaseParameters(part: 0, rate: .2))),
      0,
    );
    expect(
      primary(e.calculate(const PercentageBaseParameters(part: 200, rate: 2))),
      100,
    );
    for (final p in [
      const PercentageBaseParameters(part: 0, rate: 0),
      const PercentageBaseParameters(part: 1, rate: -1),
      const PercentageBaseParameters(part: -1, rate: .2),
      const PercentageBaseParameters(part: 1e308, rate: .01),
      const PercentageBaseParameters(part: 5e-324, rate: 100),
      const PercentageBaseParameters(part: 1, rate: double.nan),
    ]) {
      expect(e.calculate(p), isA<CalculationFailure>());
    }
  });
  test('discount has explicit rial unit, saving, 0/100% and zero price', () {
    const e = DiscountEngine();
    final o = e.calculate(const DiscountParameters(price: 100000, rate: .2));
    expect(primary(o), 80000);
    final result = (o as CalculationSuccess).result;
    expect((result.primary.value as NumericResultValue).unit, 'ریال');
    expect(
      (result.details.singleWhere((d) => d.id == 'saving').value
              as NumericResultValue)
          .value,
      20000,
    );
    expect(
      primary(e.calculate(const DiscountParameters(price: 100, rate: 0))),
      100,
    );
    expect(
      primary(e.calculate(const DiscountParameters(price: 100, rate: 1))),
      0,
    );
    expect(
      primary(e.calculate(const DiscountParameters(price: 0, rate: 1))),
      0,
    );
    for (final p in [
      const DiscountParameters(price: -1, rate: 0),
      const DiscountParameters(price: 1, rate: 1.01),
      const DiscountParameters(price: 1, rate: -.01),
      const DiscountParameters(price: double.infinity, rate: .2),
      const DiscountParameters(price: 5e-324, rate: .01),
    ]) {
      expect(e.calculate(p), isA<CalculationFailure>());
    }
  });
  for (final runner in UtilityCalculators.runners) {
    test('${runner.definition.id}: metadata, example, strict binding', () {
      final d = runner.definition;
      expect(d.assumptions, isNotEmpty);
      expect(d.relatedTerms, isNotEmpty);
      final example = d.examples.single;
      expect(
        primary(runner.run(example.inputs)),
        closeTo(
          (example.expectedResult!.primary.value as NumericResultValue).value,
          1e-10,
        ),
      );
      expect(runner.run(RawCalculatorInput({})), isA<CalculationFailure>());
      final broken = RawCalculatorInput({
        ...example.inputs.values,
        d.fields.first.id: const RawTextInput('NaN'),
      });
      expect(runner.run(broken), isA<CalculationFailure>());
    });
  }
  test('Persian/Arabic percentage normalization does not divide twice', () {
    expect(
      primary(
        UtilityCalculators.percentageOfRunner.run(
          RawCalculatorInput({
            'amount': const RawTextInput('۲۵۰'),
            'rate': const RawTextInput('٢٠'),
          }),
        ),
      ),
      50,
    );
    expect(
      UtilityCalculators.discountRunner.run(
        RawCalculatorInput({
          'price': const RawTextInput('100'),
          'rate': const RawTextInput('101'),
        }),
      ),
      isA<CalculationFailure>(),
    );
    expect(
      UtilityCalculators.unitConversionRunner.run(
        RawCalculatorInput({
          'amount': const RawTextInput('1'),
          'from_unit': const RawTextInput('m'),
          'to_unit': const RawTextInput('kg'),
        }),
      ),
      isA<CalculationFailure>(),
    );
  });
}
