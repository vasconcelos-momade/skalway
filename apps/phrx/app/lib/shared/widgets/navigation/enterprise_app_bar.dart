import 'package:flutter/material.dart';

import '../../../core/theme/design_metrics.dart';

/// AppBar Material do ERP — altura e estilo do [AppBarTheme] / [DesignMetrics].
///
/// Altura canónica: [DesignMetrics.appBarToolbarHeight] (56) em todos os breakpoints.
/// O Scaffold trata o Safe Area do status bar.
class EnterpriseAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EnterpriseAppBar({
    super.key,
    this.title,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.actions,
    this.bottom,
    this.centerTitle,
    this.titleSpacing,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.scrolledUnderElevation,
    this.flexibleSpace,
    this.toolbarHeight,
  });

  final Widget? title;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool? centerTitle;
  final double? titleSpacing;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final double? scrolledUnderElevation;
  final Widget? flexibleSpace;
  final double? toolbarHeight;

  static double toolbarHeightFor(BuildContext context) =>
      DesignMetrics.appBarToolbarHeight;

  double get _toolbarHeight =>
      toolbarHeight ?? DesignMetrics.appBarToolbarHeight;

  @override
  Size get preferredSize => Size.fromHeight(
        _toolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions,
      bottom: bottom,
      centerTitle: centerTitle,
      titleSpacing: titleSpacing,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      scrolledUnderElevation: scrolledUnderElevation,
      flexibleSpace: flexibleSpace,
      toolbarHeight: _toolbarHeight,
    );
  }
}
