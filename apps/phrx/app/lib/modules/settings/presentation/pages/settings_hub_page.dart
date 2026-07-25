import 'package:flutter/material.dart';

import '../../../../shared/widgets/layout/enterprise_tab_hub.dart';
import 'printers_page.dart';
import 'settings_page.dart';
import 'sync_settings_page.dart';
import 'terminals_page.dart';

enum SettingsHubTab { general, printers, terminals, sync }

/// Definições do sistema unificadas.
class SettingsHubPage extends StatelessWidget {
  const SettingsHubPage({super.key, this.initialTab = 0});

  final int initialTab;

  static int indexFor(SettingsHubTab tab) => switch (tab) {
        SettingsHubTab.general => 0,
        SettingsHubTab.printers => 1,
        SettingsHubTab.terminals => 2,
        SettingsHubTab.sync => 3,
      };

  @override
  Widget build(BuildContext context) {
    return EnterpriseTabHub(
      compact: true,
      initialIndex: initialTab,
      tabs: const [
        EnterpriseTabHubTab(
          label: 'Geral',
          icon: Icons.settings_outlined,
          body: SettingsPage(),
        ),
        EnterpriseTabHubTab(
          label: 'Impressoras',
          icon: Icons.print_outlined,
          body: PrintersPage(),
        ),
        EnterpriseTabHubTab(
          label: 'Terminais',
          icon: Icons.devices_other_outlined,
          body: TerminalsPage(),
        ),
        EnterpriseTabHubTab(
          label: 'Sincronização',
          icon: Icons.sync_alt,
          body: SyncSettingsPage(),
        ),
      ],
    );
  }
}
