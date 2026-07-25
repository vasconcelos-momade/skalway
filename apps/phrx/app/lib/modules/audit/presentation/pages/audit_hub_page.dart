import 'package:flutter/material.dart';

import '../../../../shared/widgets/layout/enterprise_tab_hub.dart';
import 'audit_logs_page.dart';
import 'audit_page.dart';
import 'audit_psychotropics_page.dart';
import 'audit_timeline_page.dart';

enum AuditHubTab { overview, timeline, logs, psychotropics }

/// Auditoria unificada — substitui 4 entradas de menu por tabs.
class AuditHubPage extends StatelessWidget {
  const AuditHubPage({super.key, this.initialTab = 0});

  final int initialTab;

  static int indexFor(AuditHubTab tab) => switch (tab) {
        AuditHubTab.overview => 0,
        AuditHubTab.timeline => 1,
        AuditHubTab.logs => 2,
        AuditHubTab.psychotropics => 3,
      };

  @override
  Widget build(BuildContext context) {
    return EnterpriseTabHub(
      compact: true,
      initialIndex: initialTab,
      tabs: const [
        EnterpriseTabHubTab(
          label: 'Visão Geral',
          icon: Icons.gavel_outlined,
          body: AuditPage(),
        ),
        EnterpriseTabHubTab(
          label: 'Cronologia',
          icon: Icons.timeline,
          body: AuditTimelinePage(),
        ),
        EnterpriseTabHubTab(
          label: 'Logs',
          icon: Icons.terminal,
          body: AuditLogsPage(),
        ),
        EnterpriseTabHubTab(
          label: 'Psicotrópicos',
          icon: Icons.verified_user_outlined,
          body: AuditPsychotropicsPage(),
        ),
      ],
    );
  }
}
