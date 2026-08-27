import 'package:flutter/material.dart';

import 'design_metrics.dart';

/// Raios e alturas de chrome — delega métricas a [DesignMetrics].
abstract final class AppDimensions {
  AppDimensions._();

  static const double appBarHeight = DesignMetrics.appBarToolbarHeight;
  static const double topBarDesktop = DesignMetrics.topBarDesktop;
  static const double topBarCompact = DesignMetrics.topBarCompact;
  static const double bottomNavHeight = DesignMetrics.bottomNavHeight;
  static const double posHeader = DesignMetrics.posHeader;
  static const double posFooter = DesignMetrics.posFooter;

  static const double sidebarExpanded = DesignMetrics.sidebarExpanded;
  static const double sidebarCollapsed = DesignMetrics.sidebarCollapsed;
  static const double contentMaxWidth = DesignMetrics.contentMaxWidth;

  static const double minTouchTarget = DesignMetrics.minTouchTarget;
  static const double iconLg = DesignMetrics.iconMd;
  static const double avatarMd = DesignMetrics.avatarMd;

  static const EdgeInsets tabletInset = EdgeInsets.all(AppSpacing.xl);
}
