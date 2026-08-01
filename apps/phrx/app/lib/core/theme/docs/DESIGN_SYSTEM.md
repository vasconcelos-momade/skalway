# Design System — Pharma ERP

O Design System Enterprise do Pharma ERP prioriza clareza, hierarquia visual e
usabilidade. Aparência profissional inspirada em SAP Fiori, IBM Carbon,
Microsoft Fluent 2 e Atlassian Design System.

## Princípios

1. **Design Tokens only** — componentes consomem apenas tokens; zero valores hardcoded.
2. **Menos cores, mais contraste** — primária (verde) só em acções primárias, sucesso e elementos realmente importantes.
3. **Tipografia como hierarquia** — peso, tamanho e espaçamento antes de cor.
4. **Menos bordas, mais espaçamento** — bordas 1px de baixo contraste; profundidade via Surface 0–4.
5. **Consistência acima de personalização** — mesmos tokens em todos os componentes.
6. **Retrocompatibilidade** — `PharmaTokens` como ponte legacy-to-modern.

## Tokens canónicos

| Ficheiro | Responsabilidade |
|----------|------------------|
| `design_tokens.dart` | `PharmaTokens` + densidade |
| `app_colors.dart` | Brand + paletas dark/light |
| `surface_tokens.dart` | Surface 0–4 |
| `typography_tokens.dart` | Escala tipográfica + pesos 400/500/600 |
| `spacing_tokens.dart` | 4 · 8 · 12 · 16 · 24 · 32 · 40 |
| `radius_tokens.dart` | 4 · 8 · 10 · 9999 |
| `border_tokens.dart` | 1px · indicator 3px |
| `motion_tokens.dart` | Fast 150 · Normal 200 · Slow 250 |
| `shadow_tokens.dart` | Card leve · floating (dialogs/menus) |
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

## Padrões de componentes

| Componente | Regra |
|------------|-------|
| **Inputs** | Label acima (cinza, 12–13px, w500); borda neutra; primária só no foco |
| **Botões** | Filled = acção principal; outline/ghost = secundárias |
| **Tabelas** | Zebra suave; divisórias discretas; tipografia secundaria no header |
| **Sidebar** | Fundo suave + barra 3px; sem bloco verde sólido |
| **Cards** | Fundo neutro, borda 1px, sombra muito leve |
| **KPIs** | Ícone neutro; cor só em tendência/estado |
| **Chips/Status** | Cor só para sucesso / aviso / erro / info |
| **Dialogs** | Surface 4 + borda subtil + sombra floating |
| **Side sheets (formulários)** | Largura = categorias (480 tablet / 520 desktop); Surface 2; footer fixo Outline+Filled |

## Acesso rápido

```dart
final t = context.pharmaTokens;
final s = context.spacing;      // DensityTokens
final surfaces = context.surfaces;
final colors = context.colors;
```

Antes de hardcodar um valor, verificar se existe token equivalente.
Caso não exista, criar um token reutilizável.
