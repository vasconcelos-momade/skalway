import 'package:flutter/material.dart';

import '../../../core/theme/design_metrics.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';

/// Hub com tabs internas — evita rotas separadas para vistas relacionadas.
class EnterpriseTabHub extends StatefulWidget {
  const EnterpriseTabHub({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
    this.title,
    this.subtitle,
    this.tag,
    this.actions,
    this.compact = false,
  });

  final String? title;
  final String? subtitle;
  final String? tag;
  final List<Widget>? actions;
  final List<EnterpriseTabHubTab> tabs;
  final int initialIndex;

  /// Sem cabeçalho próprio — páginas filhas já usam [EnterpriseModuleHub].
  final bool compact;

  @override
  State<EnterpriseTabHub> createState() => _EnterpriseTabHubState();
}

class EnterpriseTabHubTab {
  const EnterpriseTabHubTab({
    required this.label,
    required this.icon,
    required this.body,
  });

  final String label;
  final IconData icon;
  final Widget body;
}

class _EnterpriseTabHubState extends State<EnterpriseTabHub>
    with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: widget.initialIndex.clamp(0, widget.tabs.length - 1),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final textTheme = context.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.compact) ...[
          if (widget.tag != null && widget.tag!.isNotEmpty) ...[
            Text(
              widget.tag!.toUpperCase(),
              style: textTheme.erpOverline.copyWith(color: t.brandBlue),
            ),
            SizedBox(height: s.xs),
          ],
          if (widget.title != null && widget.title!.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title!,
                        style:
                            context.erpPageTitle.copyWith(color: t.textPrimary),
                      ),
                      if (widget.subtitle != null &&
                          widget.subtitle!.isNotEmpty) ...[
                        SizedBox(height: s.xxs),
                        Text(
                          widget.subtitle!,
                          style: textTheme.erpBodySecondary.copyWith(
                            color: t.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.actions != null && widget.actions!.isNotEmpty)
                  Wrap(
                    spacing: s.sm,
                    runSpacing: s.sm,
                    children: widget.actions!,
                  ),
              ],
            ),
          SizedBox(height: s.md),
        ],
        Material(
          color: t.bgSecondary,
          borderRadius: BorderRadius.circular(t.radiusMd),
          child: TabBar(
            controller: _controller,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: t.brandBlue,
            unselectedLabelColor: t.textMuted,
            indicatorColor: t.brandBlue,
            dividerColor: t.border.withValues(alpha: 0.25),
            tabs: widget.tabs
                .map(
                  (tab) => Tab(
                    icon: Icon(tab.icon, size: DesignMetrics.iconSm),
                    text: tab.label,
                    height: DesignMetrics.tabHeightMax,
                  ),
                )
                .toList(),
          ),
        ),
        SizedBox(height: s.md),
        Expanded(
          child: TabBarView(
            controller: _controller,
            children: widget.tabs.map((tab) => tab.body).toList(),
          ),
        ),
      ],
    );
  }
}
