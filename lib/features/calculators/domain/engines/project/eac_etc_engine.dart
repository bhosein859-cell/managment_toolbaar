import 'dart:math' as math;

import '../../calculator_domain.dart';
import '../../statistics/tool_numeric.dart';

final class EacEtcParameters implements CalculatorParameters {
  const EacEtcParameters({
    required this.bac,
    required this.pv,
    required this.ev,
    required this.ac,
    required this.newEtc,
    this.method = 'cpi',
  });
  final double bac;
  final double pv;
  final double ev;
  final double ac;
  final double newEtc;
  final String method;
}

final class EacEtcEngine implements CalculatorEngine<EacEtcParameters> {
  const EacEtcEngine();
  static const basis =
      'دامنه و مبنای بودجه ثابت‌اند؛ BAC مثبت، ۰≤PV,EV≤BAC و AC نامنفی است. روش CPI: ETC=(BAC−EV)/CPI؛ بودجه‌ای: ETC=BAC−EV؛ ترکیبی: ETC=(BAC−EV)/(CPI×SPI)؛ پایین‌به‌بالا: ETC ورودی جدید. همیشه EAC=AC+ETC. روش‌های نسبتی برای باقی‌ماندهٔ مثبت به EV و AC مثبت و روش ترکیبی به PV مثبت هم نیاز دارند. با EV=BAC، ETC روش‌های غیرپایین‌به‌بالا صفر است و شاخص نامعین لازم نمی‌شود؛ پایین‌به‌بالا برآورد ورودی را حفظ می‌کند. اثر SPI بر هزینه یک فرض انتخابی است نه قانون عمومی؛ این اعداد پیش‌بینی مشروط‌اند، نه تعهد قطعی.';
  @override
  String get calculatorId => 'eac_etc';
  @override
  InputBinding<EacEtcParameters> bind(CalculatorInput input) {
    final p = EacEtcParameters(
      bac: input.requireNumber('bac'),
      pv: input.requireNumber('pv'),
      ev: input.requireNumber('ev'),
      ac: input.requireNumber('ac'),
      newEtc: input.requireNumber('new_etc'),
      method: input.requireChoice('method'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(EacEtcParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final remaining = p.bac - p.ev;
    double etc;
    if (p.method == 'bottom_up') {
      etc = p.newEtc;
    } else if (remaining == 0) {
      etc = 0;
    } else if (p.method == 'budget') {
      etc = remaining;
    } else {
      etc = positiveFromLog(
        math.log(remaining) +
            math.log(p.ac) -
            math.log(p.ev) +
            (p.method == 'cpi_spi' ? math.log(p.pv) - math.log(p.ev) : 0),
      );
      if (invalidNumeric(etc, nonzero: true)) return toolRange();
    }
    final eac = p.ac + etc;
    if (!eac.isFinite || (p.ac > 0 && etc > 0 && (eac == p.ac || eac == etc))) {
      return toolRange();
    }
    return toolResult(
      id: calculatorId,
      label: 'برآورد هزینهٔ نهایی EAC',
      value: eac,
      unit: 'ریال',
      basis: basis,
      details: [
        metric('etc', 'برآورد هزینهٔ باقی‌مانده ETC', etc, unit: 'ریال'),
        metric(
          'remaining_budget',
          'ارزش بودجه‌ای باقی‌مانده، نه ETC لزوماً',
          remaining,
          unit: 'ریال',
        ),
        metric(
          'vac',
          'انحراف پیش‌بینی‌شدهٔ بودجه VAC',
          p.bac - eac,
          unit: 'ریال',
        ),
        textMetric(
          'selected_method',
          'فرض پیش‌بینی انتخابی',
          switch (p.method) {
            'cpi' => 'ادامهٔ CPI',
            'budget' => 'کار باقی‌مانده طبق بودجه',
            'cpi_spi' => 'اثر مشترک CPI و SPI',
            _ => 'پایین‌به‌بالا',
          },
        ),
      ],
    );
  }

  List<CalculationIssue> _validate(EacEtcParameters p) {
    final issues = toolValidate([
      ToolNumber('bac', 'بودجهٔ مصوب کل BAC', p.bac, min: 0, strictMin: true),
      ToolNumber('pv', 'ارزش برنامه‌ریزی‌شده PV', p.pv, min: 0),
      ToolNumber('ev', 'ارزش کسب‌شده EV', p.ev, min: 0),
      ToolNumber('ac', 'هزینهٔ واقعی AC', p.ac, min: 0),
      ToolNumber('new_etc', 'برآورد جدید کار باقی‌مانده', p.newEtc, min: 0),
    ]);
    if (issues.isNotEmpty) return issues;
    if (!['cpi', 'budget', 'cpi_spi', 'bottom_up'].contains(p.method)) {
      issues.add(
        CalculationIssue(
          code: 'invalid_method',
          fieldId: 'method',
          message: 'روش پیش‌بینی معتبر نیست.',
        ),
      );
    }
    for (final (id, value) in [('pv', p.pv), ('ev', p.ev)]) {
      if (value > p.bac) {
        issues.add(
          CalculationIssue(
            code: 'above_bac',
            fieldId: id,
            message: 'با فرض دامنهٔ ثابت، PV و EV نباید از BAC بیشتر باشند.',
          ),
        );
      }
    }
    if (p.ev < p.bac && ['cpi', 'cpi_spi'].contains(p.method)) {
      for (final (id, value) in [
        ('ev', p.ev),
        ('ac', p.ac),
        if (p.method == 'cpi_spi') ('pv', p.pv),
      ]) {
        if (value == 0) {
          issues.add(
            CalculationIssue(
              code: 'undefined_forecast',
              fieldId: id,
              message: 'برای روش نسبتی و کار باقی‌مانده، این ورودی باید مثبت باشد؛ روش بودجه‌ای/پایین‌به‌بالا را فقط با فرض مناسب انتخاب کنید.',
            ),
          );
        }
      }
    }
    return issues;
  }
}
