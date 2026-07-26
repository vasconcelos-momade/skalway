# Theming Guide

O `AppTheme` é o orquestrador que une os Design Tokens, Material 3 e os estilos dos Componentes.

## Light e Dark Mode
O sistema suporta `Light` e `Dark` mode.
A transição é feita alterando o `ThemeMode` do `MaterialApp`.

```dart
theme: AppTheme.lightEnterprise(),
darkTheme: AppTheme.darkEnterprise(),
```

As extensões `ThemeExtension` (como `PharmaColorTokens`) são recriadas no método `fromLegacy()` recebendo as cores base ajustadas para a paleta Dark/Light de forma transparente.
