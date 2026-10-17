import 'package:flutter/widgets.dart';

import '../../features/home/presentation/controllers/tool_session_controller.dart';

class ToolSessionScope extends InheritedNotifier<ToolSessionController> {
  const ToolSessionScope({
    super.key,
    required ToolSessionController session,
    required super.child,
  }) : super(notifier: session);
  static ToolSessionController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ToolSessionScope>();
    assert(scope != null, 'ToolSessionScope is required');
    return scope!.notifier!;
  }
}
