import 'package:flutter/material.dart';

/// Safe replacement UI: never displays stack traces or sensitive details.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key});

  @override
  Widget build(BuildContext context) => const Directionality(
    textDirection: TextDirection.rtl,
    child: ColoredBox(
      color: Color(0xFFF4F7FA),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'خطایی در نمایش صفحه رخ داد. لطفاً برنامه را دوباره باز کنید.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              color: Color(0xFF163047),
              fontSize: 16,
            ),
          ),
        ),
      ),
    ),
  );
}
