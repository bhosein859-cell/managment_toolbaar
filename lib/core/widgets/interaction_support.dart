import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// No animation may override the OS accessibility preference.
Duration interactionDuration(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 140);

class SearchShortcuts extends StatelessWidget {
  const SearchShortcuts({
    super.key,
    required this.focusNode,
    required this.child,
  });
  final FocusNode focusNode;
  final Widget child;
  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
        focusNode.requestFocus();
        final target = focusNode.context;
        if (target != null) {
          Scrollable.ensureVisible(
            target,
            duration: interactionDuration(context),
          );
        }
      },
    },
    child: Focus(autofocus: true, skipTraversal: true, child: child),
  );
}

/// Small route fade, no result cross-fade: invalid input must hide output at once.
class ToolboxTransitions extends PageTransitionsBuilder {
  const ToolboxTransitions();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return FadeTransition(
      opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
      child: child,
    );
  }
}
