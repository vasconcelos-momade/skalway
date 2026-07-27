import 'package:flutter/material.dart';

import '../../../../shared/widgets/layout/enterprise_tab_hub.dart';
import '../../presentation/pages/cashflow_page.dart';
import '../../presentation/pages/expenses_page.dart';
import '../../presentation/pages/financial_page.dart';
import '../../presentation/pages/revenue_page.dart';

enum FinanceHubTab { overview, cashflow, revenue, expenses }

/// Financeiro unificado — visão geral, fluxo de caixa, receita e despesas.
class FinanceHubPage extends StatelessWidget {
  const FinanceHubPage({super.key, this.initialTab = 0});

  final int initialTab;

  static int indexFor(FinanceHubTab tab) => switch (tab) {
        FinanceHubTab.overview => 0,
        FinanceHubTab.cashflow => 1,
        FinanceHubTab.revenue => 2,
        FinanceHubTab.expenses => 3,
      };

  @override
  Widget build(BuildContext context) {
    return EnterpriseTabHub(
      compact: true,
      initialIndex: initialTab,
      tabs: const [
        EnterpriseTabHubTab(
          label: 'Visão Geral',
          icon: Icons.payments_outlined,
          body: FinancialPage(),
        ),
        EnterpriseTabHubTab(
          label: 'Fluxo de Caixa',
          icon: Icons.stacked_line_chart,
          body: CashflowPage(),
        ),
        EnterpriseTabHubTab(
          label: 'Receita/Faturamento',
          icon: Icons.trending_up,
          body: RevenuePage(),
        ),
        EnterpriseTabHubTab(
          label: 'Despesas',
          icon: Icons.money_off_csred_outlined,
          body: ExpensesPage(),
        ),
      ],
    );
  }
}
