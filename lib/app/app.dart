import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/storage/open_local_database.dart';
import '../core/widgets/app_startup_splash.dart';
import '../features/history/data/drift_tool_repository.dart';
import '../features/history/domain/tool_repository.dart';
import '../features/home/presentation/controllers/tool_session_controller.dart';
import 'catalog/app_catalog.dart';
import 'routing/app_router.dart';
import 'state/tool_session_scope.dart';
import 'theme/app_theme.dart';
import 'theme/theme_settings.dart';

class ManagementToolboxApp extends StatefulWidget {
  const ManagementToolboxApp({super.key, this.repository});

  /// An injected repository is owned and closed by this app instance.
  final ToolRepository? repository;
  @override
  State<ManagementToolboxApp> createState() => _ManagementToolboxAppState();
}

class _ManagementToolboxAppState extends State<ManagementToolboxApp> {
  final _settings = ThemeSettings();
  final _navigator = GlobalKey<NavigatorState>();
  late final ToolSessionController _session;
  @override
  void initState() {
    super.initState();
    _session = ToolSessionController(
      catalog: AppCatalog.catalog,
      repository:
          widget.repository ??
          DriftToolRepository(
            openApplicationDatabase(),
            reopen: openApplicationDatabase,
          ),
    );
    unawaited(_session.initialize());
  }

  @override
  void dispose() {
    _session.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ThemeScope(
    settings: _settings,
    child: ToolSessionScope(
      session: _session,
      child: Builder(
        builder: (context) => MaterialApp(
          navigatorKey: _navigator,
          title: 'جعبه‌ابزار مدیریت',
          debugShowCheckedModeBanner: false,
          locale: const Locale('fa', 'IR'),
          supportedLocales: const [Locale('fa', 'IR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeScope.of(context).mode,
          initialRoute: AppRoutes.welcome,
          onGenerateRoute: AppRouter.onGenerateRoute,
          builder: (context, child) => ListenableBuilder(
            listenable: _session,
            builder: (context, _) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations:
                    MediaQuery.disableAnimationsOf(context) ||
                    ThemeScope.of(context).reduceMotion,
              ),
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(
                    LogicalKeyboardKey.arrowLeft,
                    alt: true,
                    includeRepeats: false,
                  ): () {
                    if (_session.isReady) {
                      _navigator.currentState?.maybePop();
                    }
                  },
                  const SingleActivator(
                    LogicalKeyboardKey.keyH,
                    control: true,
                    includeRepeats: false,
                  ): () {
                    if (_session.isReady && _navigator.currentContext != null) {
                      _navigator.currentState!.pushNamed(AppRoutes.history);
                    }
                  },
                },
                child: FocusTraversalGroup(
                  policy: ReadingOrderTraversalPolicy(),
                  child: _session.isReady
                      ? child!
                      : _StorageStartup(session: _session),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _StorageStartup extends StatelessWidget {
  const _StorageStartup({required this.session});
  final ToolSessionController session;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (session.isBusy) ...[
                const AppStartupSplash(),
              ] else ...[
                Text(
                  session.lastError ?? 'پایگاه داده آماده نیست',
                  key: const Key('storage-startup-error'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('storage-retry'),
                  onPressed: () => session.initialize(),
                  child: const Text('تلاش دوباره'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
