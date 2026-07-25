import 'package:flutter/material.dart';

import '../../../../shared/widgets/layout/enterprise_tab_hub.dart';
import '../../prescriptions/presentation/pages/recipes_book_page.dart';
import '../../psychotropics/presentation/pages/psychotropics_book_page.dart';
import '../../sanitary/presentation/pages/regulatory_page.dart';

enum RegulatoryHubTab { recipes, psychotropics, sanitary }

/// Módulo regulatório unificado.
class RegulatoryHubPage extends StatelessWidget {
  const RegulatoryHubPage({super.key, this.initialTab = 0});

  final int initialTab;

  static int indexFor(RegulatoryHubTab tab) => switch (tab) {
        RegulatoryHubTab.recipes => 0,
        RegulatoryHubTab.psychotropics => 1,
        RegulatoryHubTab.sanitary => 2,
      };

  @override
  Widget build(BuildContext context) {
    return EnterpriseTabHub(
      compact: true,
      initialIndex: initialTab,
      tabs: const [
        EnterpriseTabHubTab(
          label: 'Receitas',
          icon: Icons.description_outlined,
          body: RecipesBookPage(),
        ),
        EnterpriseTabHubTab(
          label: 'Psicotrópicos',
          icon: Icons.medical_information_outlined,
          body: PsychotropicsBookPage(),
        ),
        EnterpriseTabHubTab(
          label: 'Sanitário',
          icon: Icons.health_and_safety_outlined,
          body: RegulatoryPage(),
        ),
      ],
    );
  }
}
