# Token Guide

## Como utilizar Tokens
O sistema migrou de uma única classe gigante (`PharmaTokens`) para várias extensões. 

No seu Widget, acesse os tokens via `BuildContext` utilizando as extensões disponíveis em `extensions.dart`:

```dart
final colors = context.colors; // PharmaColorTokens
final spacing = context.spacing; // DensityTokens
final tokens = context.tokens; // PharmaTokens (Legacy)
```

## Theme Extensions
- `PharmaColorTokens`: Cores MD3 + Enterprise semânticas.
- `PharmaDashboardTokens`: Estilos para cards analíticos e métricas.
- `PharmaHealthcareTokens`: Cores para receitas, controle de temperatura e medicamentos controlados.
- `PharmaFinanceTokens`: Cores para faturas, lucro e pendências.
- `PharmaNavigationTokens`: Cores para sidebar, drawer e topbar.
- `PharmaBorderTokens` e `PharmaRadiusTokens`: Estilos de borda e arredondamento.
