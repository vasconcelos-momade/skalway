# Component Guide

Os componentes do Flutter são estilizados de forma centralizada em `component_theme.dart` (para componentes Material base) e `app_theme.dart`.

## Adicionando novos Componentes
Sempre que precisar criar um componente reutilizável, avalie se ele pode ser apenas uma estilização do componente Material existente usando a `ThemeData`. 

Por exemplo:
- **Botões**: Já customizados via `FilledButtonTheme`, `OutlinedButtonTheme`.
- **Inputs**: Customizados via `InputDecorationTheme`.
- **Cards e Dialogs**: Usam os raios e bordas do design system de forma automática.

## Componentes Específicos
Componentes que não existem no Material (como KpiCard, MedicineCard) devem buscar suas cores e métricas nas ThemeExtensions correspondentes (`PharmaDashboardTokens`, `PharmaHealthcareTokens`).
