import 'package:flutter/material.dart';

/// First-frame loading screen on Windows and Android; no artificial delay.
class AppStartupSplash extends StatelessWidget {
  const AppStartupSplash({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Column(
      key: const Key('app-startup-splash'),
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'assets/branding/logo.png',
            width: 112,
            height: 112,
            semanticLabel: 'نشان جعبه‌ابزار مدیریت',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'جعبه‌ابزار مدیریت',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text('سازنده حسین بختیاری', textAlign: TextAlign.center),
        const SizedBox(height: 20),
        const CircularProgressIndicator(),
        const SizedBox(height: 12),
        const Text('در حال خواندن داده‌های محلی…', textAlign: TextAlign.center),
      ],
    ),
  );
}
