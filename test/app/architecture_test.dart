import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/app.dart';
import 'package:management_toolbox/app/theme/app_theme.dart';
import 'package:management_toolbox/core/errors/app_failure.dart';
import 'package:management_toolbox/core/widgets/error_view.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';

void main() {
  test('failure retains a Persian message and machine-readable code', () {
    const failure = AppFailure('ورودی نامعتبر است', code: 'invalid_input');
    expect(failure.message, 'ورودی نامعتبر است');
    expect(failure.code, 'invalid_input');
  });

  test('base themes use Material 3 in both brightness modes', () {
    expect(AppTheme.light().useMaterial3, isTrue);
    expect(AppTheme.light().brightness, Brightness.light);
    expect(AppTheme.dark().brightness, Brightness.dark);
  });

  test('domain stays independent from Flutter, data and presentation', () {
    final files = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.contains('/domain/') && f.path.endsWith('.dart'));
    for (final file in files) {
      expect(file.readAsStringSync(), isNot(contains('package:flutter/')));
      expect(file.readAsStringSync(), isNot(contains('/data/')));
      expect(file.readAsStringSync(), isNot(contains('/presentation/')));
    }
  });

  testWidgets('welcome is RTL, credits creator and navigates to home', (
    tester,
  ) async {
    await tester.pumpWidget(
      ManagementToolboxApp(repository: DriftToolRepository.memory()),
    );
    await tester.pumpAndSettle();
    expect(find.text('سازنده حسین بختیاری'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('ورود به برنامه'))),
      TextDirection.rtl,
    );
    await tester.tap(find.text('ورود به برنامه'));
    await tester.pumpAndSettle();
    expect(find.text('سازنده حسین بختیاری'), findsNothing);
    expect(find.text('دسته‌بندی‌ها'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unknown route provides a safe return home', (tester) async {
    await tester.pumpWidget(
      ManagementToolboxApp(repository: DriftToolRepository.memory()),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.text('ورود به برنامه'));
    Navigator.of(context).pushNamed('/missing');
    await tester.pumpAndSettle();
    expect(find.text('صفحه پیدا نشد'), findsOneWidget);
    await tester.tap(find.text('بازگشت به خانه'));
    await tester.pumpAndSettle();
    expect(find.text('جعبه‌ابزار مدیریت'), findsOneWidget);
  });

  testWidgets('error fallback renders without app dependencies', (
    tester,
  ) async {
    await tester.pumpWidget(const ErrorView());
    expect(find.textContaining('خطایی در نمایش'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
