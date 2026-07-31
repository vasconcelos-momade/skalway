# Design System — Pharma ERP

O Design System Enterprise do Pharma ERP segue a filosofia visual do Trae AI:
extremamente consistente, minimalista, técnico, moderno, compacto e com alta legibilidade.

## Princípios

1. **Design Tokens only** — componentes consomem apenas tokens; zero valores hardcoded.
2. **Profundidade por superfície** — hierarquia Surface 0–4 via luminosidade subtil (2–4%); sombras mínimas.
3. **Bordas 1px** — baixo contraste; sem caixas pesadas.
4. **Identidade preservada** — cor primária, branding e arquitectura de negócio intactas.
5. **Retrocompatibilidade** — `PharmaTokens` como ponte legacy-to-modern.

## Tokens canónicos

| Ficheiro | Responsabilidade |
|----------|------------------|
| `design_tokens.dart` | `PharmaTokens` + densidade |
| `app_colors.dart` | Brand + paletas dark/light |
| `surface_tokens.dart` | Surface 0–4 |
| `typography_tokens.dart` | Escala tipográfica + pesos 400/500/600 |
| `spacing_tokens.dart` | 4 · 8 · 12 · 16 · 24 · 32 · 40 |
| `radius_tokens.dart` | 4 · 8 · 10 · 9999 |
| `border_tokens.dart` | 1px, default / subtle |
| `motion_tokens.dart` | Fast 150 · Normal 200 · Slow 250 |
| `shadow_tokens.dart` | Sombras mínimas (só floating) |
| `icon_tokens.dart` | sm 18 · md 24 · lg 32 |
| `table_tokens.dart` | Header / zebra / densidade |

## Superfícies

| Nível | Uso |
|-------|-----|
| 0 | Background principal |
| 1 | Sidebar |
| 2 | Cards, containers, data tables |
| 3 | Inputs, search, toolbar, headers |
| 4 | Dialogs, dropdowns, menus, drawers |

## Componentes

Todos os componentes Enterprise devem usar exclusivamente Design Tokens via
`context.pharmaTokens`, `context.colors`, `context.surfaces`, `context.spacing`,
`context.radius`, `MotionTokens`, `ShadowTokens`, etc.

## Acesso rápido

```dart
final t = context.pharmaTokens;
final s = context.spacing;      // DensityTokens
final surfaces = context.surfaces;
final colors = context.colors;
```
