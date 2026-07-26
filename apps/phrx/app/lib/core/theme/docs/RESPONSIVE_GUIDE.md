# Responsive Guide

O sistema é construído para rodar em Mobile, Tablet, Desktop, Desktop Large e UltraWide.

## Breakpoints
Definidos em `breakpoints.dart`:
- **Mobile**: < 600px
- **Tablet**: 600px a 1199px
- **Desktop**: 1200px a 1535px
- **Desktop Large**: >= 1536px

## Como usar
Evite `MediaQuery.of(context).size.width` espalhado pelo código. Utilize as extensões em `BuildContext`:

```dart
if (context.isMobile) {
  // renderizar UI compacta
}

// ou usar o helper responsivo:
final padding = context.responsiveValue(
  mobile: 16.0,
  tablet: 24.0,
  desktop: 32.0,
);
```
