import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/widgets/error_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = FlutterError.presentError;
  ErrorWidget.builder = (_) => const ErrorView();
  PlatformDispatcher.instance.onError = (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stack),
    );
    // Do not silently mark unexpected platform failures as handled.
    return false;
  };
  runApp(const ManagementToolboxApp());
}
