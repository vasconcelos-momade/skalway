import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

typedef ResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  BoxConstraints constraints,
);

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.builder});

  final ResponsiveWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return builder(context, constraints);
      },
    );
  }
}

extension BoxConstraintsBreakpoint on BoxConstraints {
  bool get isTabletOrWider => maxWidth >= Breakpoints.tablet;
  bool get isDesktopOrWider => maxWidth >= Breakpoints.desktop;
}
