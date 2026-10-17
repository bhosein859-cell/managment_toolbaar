import 'package:management_toolbox/app/catalog/prototype_calculators.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';

final input = PrototypeCalculators.oee.examples.single.inputs;
final result =
    (PrototypeCalculators.oeeRunner.run(input) as CalculationSuccess).result;
final clock = DateTime.utc(2026, 10, 16, 12, 30, 45, 123, 456);
