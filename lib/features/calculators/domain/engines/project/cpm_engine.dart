import '../../calculator_domain.dart';
import '../../project/network_metrics.dart';
import '../../project/project_network.dart';
import '../../statistics/tool_numeric.dart';

final class CpmParameters implements CalculatorParameters {
  CpmParameters(Iterable<ProjectActivity> activities)
    : activities = List.unmodifiable(activities);
  final List<ProjectActivity> activities;
}

final class CpmEngine implements CalculatorEngine<CpmParameters> {
  const CpmEngine();
  static const basis =
      'شبکهٔ Activity-on-Node با وابستگی پایان‌به‌شروع، lag صفر، مدت قطعی نامنفی و تقویم مشترک فرض شده است؛ محدودیت منابع، تعطیلات، تقدم‌های SS/FF/SF، تاریخ اجباری و احتمال در این مدل نیستند. شروع مجازی صفر و پایان مجازی مشترک برابر افق شبکه است؛ برای گره پایانی FF=افق−EF. گذر پیشرو/پسرو ES/EF/LS/LF و TF=LS−ES و FF=min(ES پس‌نیاز)−EF را می‌دهند. چند مبدأ/پایان و مدت صفر مجاز است؛ شناسه، ارجاع، یال تکراری/خودی و چرخه اعتبارسنجی می‌شوند. شناوری در تلرانس ۸ اپسیلون ماشین ضربدر افق صفر تلقی می‌شود؛ اعداد بسیار نزدیک ممکن است در این دقت بحرانی محسوب شوند. مجموعهٔ فعالیت‌های بحرانی لزوماً یک مسیر نیست؛ یک مسیر متصل کامل و تعداد مسیرهای بیشینهٔ گذر پیشرو با تساوی دقیق یال/پایان در دقت محاسبه گزارش می‌شود؛ تلرانس بر شمارش مسیرها اعمال نمی‌شود، نه فهرست نمایی همهٔ مسیرها. مسیر انتخابی در تساوی با ترتیب ورودی قطعی است. بحرانی بودن حکم کیفیت یا الزام منابع نیست.';
  @override
  String get calculatorId => 'cpm';
  @override
  InputBinding<CpmParameters> bind(CalculatorInput input) =>
      switch (bindNetwork(input)) {
        BoundNetwork(:final activities) => BoundInput(
          CpmParameters(activities),
        ),
        RejectedNetwork(:final issues) => RejectedInput(issues),
      };
  @override
  CalculationOutcome calculate(CpmParameters p) {
    final outcome = scheduleProject(p.activities);
    if (outcome is InvalidNetwork) return CalculationFailure(outcome.issues);
    final s = outcome as ScheduledNetwork;
    return toolResult(
      id: calculatorId,
      label: 'مدت قطعی شبکهٔ CPM',
      value: s.duration,
      unit: 'روز',
      basis: basis,
      details: networkMetrics(s, includeTimes: true, includeFloat: false),
    );
  }
}
