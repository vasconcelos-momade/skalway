# Design System — Pharma ERP

O Design System Enterprise do Pharma ERP foi arquitetado com inspiração em Carbon Design System, Fluent 2 e Material Design 3.

## Princípios
1. **Modularidade**: Uso extensivo de `ThemeExtension` para agrupar tokens semânticos.
2. **Escalabilidade**: Preparado para novos módulos (Financeiro, Healthcare, CRM) sem inflar a classe principal.
3. **Retrocompatibilidade**: Mantém `PharmaTokens` como ponte legacy-to-modern para que telas antigas não quebrem.
4. **Performance**: Uso de classes `const` sempre que possível, sem rebuilds desnecessários.

## Estrutura
- **Tokens**: Definem as cores e propriedades primitivas.
- **Metrics/Spacing/Radius**: Centralizam valores estruturais.
- **Themes**: Agrupam os estilos dos componentes do Flutter (`component_theme.dart` e específicos).
- **Extensions**: Atalhos via `BuildContext` para facilitar o uso nas telas.
