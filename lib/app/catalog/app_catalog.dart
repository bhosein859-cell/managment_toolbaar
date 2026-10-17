import '../../features/calculators/domain/calculator_domain.dart';
import '../../features/home/domain/tool_catalog.dart';
import 'decision_calculators.dart';
import 'engineering_economics_calculators.dart';
import 'finance_calculators.dart';
import 'hr_calculators.dart';
import 'inventory_calculators.dart';
import 'production_calculators.dart';
import 'project_calculators.dart';
import 'quality_calculators.dart';
import 'utility_calculators.dart';

abstract final class AppCatalog {
  static final catalog = ToolCatalog(
    categories: [
      CalculatorCategory(
        id: CalculatorCategoryId.production,
        nameFa: 'تولید',
        nameEn: 'Production',
        description: 'بهره‌وری، ظرفیت و عملکرد تولید',
      ),
      CalculatorCategory(
        id: CalculatorCategoryId.finance,
        nameFa: 'مالی',
        nameEn: 'Finance',
        description: 'جریان نقدی، هزینه و شاخص‌های مالی',
      ),
      CalculatorCategory(
        id: CalculatorCategoryId.quality,
        nameFa: 'کیفیت',
        nameEn: 'Quality',
        description: 'قابلیت فرایند و شاخص‌های کیفیت',
      ),
      CalculatorCategory(
        id: CalculatorCategoryId.inventory,
        nameFa: 'انبار',
        nameEn: 'Inventory',
        description: 'موجودی و برنامه‌ریزی سفارش',
      ),
      CalculatorCategory(
        id: CalculatorCategoryId.project,
        nameFa: 'پروژه',
        nameEn: 'Project',
        description: 'زمان‌بندی، هزینه و پیشرفت پروژه',
      ),
      CalculatorCategory(
        id: CalculatorCategoryId.humanResources,
        nameFa: 'منابع انسانی',
        nameEn: 'Human resources',
        description: 'شاخص‌های سازمانی و منابع انسانی',
      ),
      CalculatorCategory(
        id: CalculatorCategoryId.decisionMaking,
        nameFa: 'تصمیم‌گیری',
        nameEn: 'Decision making',
        description: 'مقایسه و ارزیابی ساختاریافتهٔ گزینه‌ها',
      ),
      CalculatorCategory(
        id: CalculatorCategoryId.engineeringEconomics,
        nameFa: 'اقتصاد مهندسی',
        nameEn: 'Engineering economics',
        description: 'ارزش زمانی پول و عوامل اقتصاد مهندسی',
      ),
      CalculatorCategory(
        id: CalculatorCategoryId.utilities,
        nameFa: 'ابزارهای عمومی',
        nameEn: 'Utilities',
        description: 'درصد، تخفیف و تبدیل واحدهای مشخص',
      ),
    ],
    tools: [
      ...ProductionCalculators.definitions,
      ...FinanceCalculators.definitions,
      ...QualityCalculators.definitions,
      ...InventoryCalculators.definitions,
      ...ProjectCalculators.definitions,
      ...HrCalculators.definitions,
      ...DecisionCalculators.definitions,
      ...EngineeringEconomicsCalculators.definitions,
      ...UtilityCalculators.definitions,
    ],
  );
}
