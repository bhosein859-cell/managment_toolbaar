import '../calculator_domain.dart';
import '../statistics/tool_numeric.dart';
import 'project_network.dart';

List<ResultMetric> networkMetrics(
  ScheduledNetwork s, {
  required bool includeTimes,
  required bool includeFloat,
}) => [
  seriesMetric(
    'activity_ids',
    'شناسهٔ فعالیت‌ها؛ همهٔ سری‌های زیر هم‌ردیف‌اند',
    s.rows.map((r) => r.activity.id.toDouble()),
  ),
  if (includeTimes) ...[
    seriesMetric(
      'es',
      'شروع زودترین ES به ترتیب شناسه‌های بالا',
      s.rows.map((r) => r.es),
      unit: 'روز',
    ),
    seriesMetric(
      'ef',
      'پایان زودترین EF',
      s.rows.map((r) => r.ef),
      unit: 'روز',
    ),
    seriesMetric('ls', 'شروع دیرترین LS', s.rows.map((r) => r.ls), unit: 'روز'),
    seriesMetric(
      'lf',
      'پایان دیرترین LF',
      s.rows.map((r) => r.lf),
      unit: 'روز',
    ),
  ],
  if (includeFloat) ...[
    metric('project_duration', 'افق مشترک شبکه', s.duration, unit: 'روز'),
    seriesMetric(
      'total_float',
      'شناوری کل TF به ترتیب شناسه‌ها',
      s.rows.map((r) => r.totalFloat),
      unit: 'روز',
    ),
    seriesMetric(
      'free_float',
      'شناوری آزاد FF به ترتیب شناسه‌ها',
      s.rows.map((r) => r.freeFloat),
      unit: 'روز',
    ),
  ],
  seriesMetric(
    'critical_activities',
    'مجموعهٔ فعالیت‌های بحرانی، نه لزوماً یک مسیر',
    s.rows.where((r) => r.critical).map((r) => r.activity.id.toDouble()),
  ),
  seriesMetric(
    'critical_path',
    'یک مسیر بحرانی متصل، از مبدأ تا پایان',
    s.criticalPath.map((id) => id.toDouble()),
  ),
  if (s.criticalPathCount <= BigInt.from(9007199254740991))
    metric(
      'critical_path_count',
      'تعداد همهٔ مسیرهای بحرانی مبدأ تا پایان',
      s.criticalPathCount.toDouble(),
    )
  else
    textMetric(
      'critical_path_count',
      'تعداد مسیرهای بحرانی',
      'بیش از بازهٔ نمایش شمارش دقیق این فرم؛ یک مسیر متصل نمایش داده شده است',
    ),
  metric(
    'critical_tolerance',
    'تلرانس عددی صفرشدن شناوری',
    s.tolerance,
    unit: 'روز',
  ),
];
