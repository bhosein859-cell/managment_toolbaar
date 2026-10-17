import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, required this.onEnter});

  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset(
                    'assets/branding/logo.png',
                    width: 168,
                    height: 168,
                    semanticLabel: 'نشان جعبه‌ابزار مدیریت',
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'جعبه‌ابزار مدیریت',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'ابزارهای مدیریتی، همیشه در دسترس و آفلاین',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: onEnter,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('ورود به برنامه'),
                ),
                const SizedBox(height: 32),
                const Text('سازنده حسین بختیاری', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
