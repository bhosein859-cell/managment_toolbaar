import '../../calculators/domain/calculator_domain.dart';
import '../../calculators/domain/statistics/tool_numeric.dart';

enum UnitDimension {
  length,
  area,
  volume,
  mass,
  time,
  speed,
  pressure,
  energy,
  power,
  temperature,
}

extension UnitDimensionTitle on UnitDimension {
  String get title => switch (this) {
    UnitDimension.length => 'طول',
    UnitDimension.area => 'مساحت',
    UnitDimension.volume => 'حجم',
    UnitDimension.mass => 'جرم',
    UnitDimension.time => 'زمان',
    UnitDimension.speed => 'سرعت',
    UnitDimension.pressure => 'فشار مطلق',
    UnitDimension.energy => 'انرژی',
    UnitDimension.power => 'توان',
    UnitDimension.temperature => 'دمای مطلق',
  };
}

final class SupportedUnit {
  const SupportedUnit(
    this.id,
    this.title,
    this.symbol,
    this.dimension,
    this.scale, {
    this.zero = 0,
  });
  final String id, title, symbol;
  final UnitDimension dimension;
  final double scale, zero;
  String get label => '${dimension.title}: $title ($symbol)';
  double get freezing => id == 'fahrenheit'
      ? 32
      : id == 'kelvin'
      ? 273.15
      : 0;
  double get minimum => dimension == UnitDimension.temperature ? zero : 0;
}

abstract final class UnitRegistry {
  static const units = <SupportedUnit>[
    SupportedUnit('mm', 'میلی‌متر', 'mm', UnitDimension.length, 0.001),
    SupportedUnit('cm', 'سانتی‌متر', 'cm', UnitDimension.length, 0.01),
    SupportedUnit('m', 'متر', 'm', UnitDimension.length, 1),
    SupportedUnit('km', 'کیلومتر', 'km', UnitDimension.length, 1000),
    SupportedUnit(
      'inch',
      'اینچ بین‌المللی',
      'in',
      UnitDimension.length,
      0.0254,
    ),
    SupportedUnit('foot', 'فوت بین‌المللی', 'ft', UnitDimension.length, 0.3048),
    SupportedUnit(
      'yard',
      'یارد بین‌المللی',
      'yd',
      UnitDimension.length,
      0.9144,
    ),
    SupportedUnit('cm2', 'سانتی‌متر مربع', 'cm²', UnitDimension.area, 0.0001),
    SupportedUnit('m2', 'متر مربع', 'm²', UnitDimension.area, 1),
    SupportedUnit('hectare', 'هکتار', 'ha', UnitDimension.area, 10000),
    SupportedUnit('km2', 'کیلومتر مربع', 'km²', UnitDimension.area, 1000000),
    SupportedUnit('ml', 'میلی‌لیتر', 'mL', UnitDimension.volume, 0.000001),
    SupportedUnit('litre', 'لیتر', 'L', UnitDimension.volume, 0.001),
    SupportedUnit('m3', 'متر مکعب', 'm³', UnitDimension.volume, 1),
    SupportedUnit('mg', 'میلی‌گرم', 'mg', UnitDimension.mass, 0.000001),
    SupportedUnit('g', 'گرم', 'g', UnitDimension.mass, 0.001),
    SupportedUnit('kg', 'کیلوگرم', 'kg', UnitDimension.mass, 1),
    SupportedUnit('tonne', 'تن متریک', 't', UnitDimension.mass, 1000),
    SupportedUnit(
      'pound',
      'پوند جرمی بین‌المللی',
      'lb',
      UnitDimension.mass,
      0.45359237,
    ),
    SupportedUnit('second', 'ثانیه', 's', UnitDimension.time, 1),
    SupportedUnit('minute', 'دقیقه', 'min', UnitDimension.time, 60),
    SupportedUnit('hour', 'ساعت', 'h', UnitDimension.time, 3600),
    SupportedUnit('day', 'روز ۲۴ساعته', 'd', UnitDimension.time, 86400),
    SupportedUnit(
      'metres_second',
      'متر بر ثانیه',
      'm/s',
      UnitDimension.speed,
      1,
    ),
    SupportedUnit(
      'km_hour',
      'کیلومتر بر ساعت',
      'km/h',
      UnitDimension.speed,
      1 / 3.6,
    ),
    SupportedUnit(
      'feet_second',
      'فوت بر ثانیه',
      'ft/s',
      UnitDimension.speed,
      0.3048,
    ),
    SupportedUnit('pa', 'پاسکال', 'Pa', UnitDimension.pressure, 1),
    SupportedUnit('kpa', 'کیلوپاسکال', 'kPa', UnitDimension.pressure, 1000),
    SupportedUnit('mpa', 'مگاپاسکال', 'MPa', UnitDimension.pressure, 1000000),
    SupportedUnit('bar', 'بار', 'bar', UnitDimension.pressure, 100000),
    SupportedUnit(
      'psi',
      'پوند نیرو بر اینچ مربع',
      'psi',
      UnitDimension.pressure,
      4.4482216152605 / (0.0254 * 0.0254),
    ),
    SupportedUnit('joule', 'ژول', 'J', UnitDimension.energy, 1),
    SupportedUnit('kilojoule', 'کیلوژول', 'kJ', UnitDimension.energy, 1000),
    SupportedUnit('megajoule', 'مگاژول', 'MJ', UnitDimension.energy, 1000000),
    SupportedUnit('watt_hour', 'وات‌ساعت', 'Wh', UnitDimension.energy, 3600),
    SupportedUnit(
      'kilowatt_hour',
      'کیلووات‌ساعت',
      'kWh',
      UnitDimension.energy,
      3600000,
    ),
    SupportedUnit('watt', 'وات', 'W', UnitDimension.power, 1),
    SupportedUnit('kilowatt', 'کیلووات', 'kW', UnitDimension.power, 1000),
    SupportedUnit('megawatt', 'مگاوات', 'MW', UnitDimension.power, 1000000),
    SupportedUnit(
      'celsius',
      'سلسیوس',
      '°C',
      UnitDimension.temperature,
      1,
      zero: -273.15,
    ),
    SupportedUnit(
      'fahrenheit',
      'فارنهایت',
      '°F',
      UnitDimension.temperature,
      5 / 9,
      zero: -459.67,
    ),
    SupportedUnit('kelvin', 'کلوین', 'K', UnitDimension.temperature, 1),
  ];
  static final Map<String, SupportedUnit> byId = Map.unmodifiable({
    for (final u in units) u.id: u,
  });
  static final String summary = [
    for (final d in UnitDimension.values)
      '${d.title}: ${units.where((u) => u.dimension == d).map((u) => u.symbol).join('، ')}',
  ].join('؛ ');
}

final class UnitConversionParameters implements CalculatorParameters {
  const UnitConversionParameters({
    required this.amount,
    required this.fromUnit,
    required this.toUnit,
  });
  final double amount;
  final String fromUnit, toUnit;
}

final class UnitConversionEngine
    implements CalculatorEngine<UnitConversionParameters> {
  const UnitConversionEngine();
  static const basis =
      'تبدیل فقط بین واحدهای فهرست‌شده و هم‌بعد است؛ تبدیل ارز، ماه/سال تقویمی، گالن/تن مبهم و دمای اختلافی نداریم. اعداد قدر مطلق کمیت‌اند و جز سلسیوس/فارنهایت زیر صفر، مقدار منفی پذیرفته نیست. دما پایین‌تر از صفر مطلق رد می‌شود؛ فشار، مطلق است نه گیج. واحدهای انگلیسی تعریف بین‌المللی دارند. خروجی به همان کمیت تعلق دارد؛ واحد ورودی و مقصد را بررسی کنید.';
  @override
  String get calculatorId => 'unit_conversion';
  @override
  InputBinding<UnitConversionParameters> bind(CalculatorInput input) {
    final p = UnitConversionParameters(
      amount: input.requireNumber('amount'),
      fromUnit: input.requireChoice('from_unit'),
      toUnit: input.requireChoice('to_unit'),
    );
    final errors = _validate(p);
    return errors.isEmpty ? BoundInput(p) : RejectedInput(errors);
  }

  List<CalculationIssue> _validate(UnitConversionParameters p) {
    final from = UnitRegistry.byId[p.fromUnit],
        to = UnitRegistry.byId[p.toUnit];
    return [
      if (!p.amount.isFinite)
        CalculationIssue(
          code: 'invalid_number',
          fieldId: 'amount',
          message: 'مقدار باید متناهی باشد.',
        ),
      if (from == null || to == null)
        CalculationIssue(
          code: 'unknown_unit',
          fieldId: 'to_unit',
          message: 'واحد انتخابی در فهرست پشتیبانی‌شده نیست.',
        ),
      if (from != null && to != null && from.dimension != to.dimension)
        CalculationIssue(
          code: 'dimension_mismatch',
          fieldId: 'to_unit',
          message: 'واحد مبدا و مقصد باید از یک گروه کمیت باشند.',
        ),
      if (from != null && p.amount < from.minimum)
        CalculationIssue(
          code: 'below_minimum',
          fieldId: 'amount',
          message: from.dimension == UnitDimension.temperature
              ? 'دما نمی‌تواند پایین‌تر از صفر مطلق باشد.'
              : 'این تبدیل قدر مطلق کمیت نامنفی می‌خواهد.',
        ),
    ];
  }

  @override
  CalculationOutcome calculate(UnitConversionParameters p) {
    final errors = _validate(p);
    if (errors.isNotEmpty) return CalculationFailure(errors);
    final from = UnitRegistry.byId[p.fromUnit]!,
        to = UnitRegistry.byId[p.toUnit]!;
    final value = p.fromUnit == p.toUnit
        ? p.amount
        : from.dimension == UnitDimension.temperature
        ? (p.amount == from.zero
              ? to.zero
              : ((p.amount - from.zero) < 1
                    ? (p.amount - from.zero) * (from.scale / to.scale) + to.zero
                    : (p.amount - from.freezing) * (from.scale / to.scale) +
                          to.freezing))
        : p.amount * (from.scale / to.scale);
    if (invalidNumeric(
      value,
      nonzero: from.dimension != UnitDimension.temperature && p.amount > 0,
    )) {
      return toolRange();
    }
    return toolResult(
      id: calculatorId,
      label: 'مقدار در واحد مقصد: ${to.title}',
      value: value,
      unit: to.symbol,
      basis: basis,
      details: [
        metric(
          'source_amount',
          'مقدار در واحد مبدا',
          p.amount,
          unit: from.symbol,
        ),
        textMetric('dimension', 'گروه کمیت', from.dimension.title),
      ],
    );
  }
}
