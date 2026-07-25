# UI React (PharmaFlow) → Flutter nativo — guia de arquitectura

Este documento define **como reutilizar a UI do protótipo React/Tailwind** em `pharmaerp-moçambique (2)/` no **pharma_erp** Flutter, **sem** conversão literal de HTML. O React serve só de referência para **identidade visual**, **UX**, **hierarquia de componentes** e **comportamento responsivo**.

Documentação geral de pastas: [estrutura_do_projecto.md](estrutura_do_projecto.md) · [project_structure.md](project_structure.md) (EN).

---

## Princípios

| Fazer | Evitar |
|--------|--------|
| `ThemeData` + `ThemeExtension` (tokens), `ColorScheme`, componentes Material 3 | Copiar `className` e divs para `Column` linha a linha |
| `GoRouter` + layouts por *shell* (sidebar vs PDV fullscreen) | Um único `build()` com milhares de linhas |
| `Riverpod` para estado e DI de serviços | Lógica de negócio em `build()` de widgets |
| `LayoutBuilder` / `ResponsiveBreakpoints` + *breakpoints* explícitos | Valores mágicos de largura espalhados |
| Módulos em `lib/modules/<domínio>/` com camadas clean | Widgets que importam `Dio` ou SQL directamente |

**Referência visual no código:** tokens espelhados do `@theme` em `pharmaerp-moçambique (2)/src/index.css` → `lib/core/theme/design_tokens.dart` (`PharmaTokens`).

---

## 1. Estrutura de widgets (`lib/shared/widgets/`)

Organização sugerida (pastas já existentes; evoluir ficheiro a ficheiro):

| Pasta | Conteúdo típico | Exemplo React equivalente |
|-------|-------------------|---------------------------|
| `buttons/` | `PharmaFilledButton`, `PharmaOutlinedButton`, `IconActionButton` | `button` com variantes Tailwind |
| `inputs/` | `PharmaTextField`, `SearchField` (topbar), `PasswordField` | inputs do `Login.tsx` / topbar `AppLayout` |
| `forms/` | `LabeledField`, `FormSection` | `space-y-*` + labels uppercase |
| `dialogs/` | `ConfirmDialog`, `RegulatoryAlertDialog` | modais reutilizáveis |
| `modals/` | *Sheets* fullscreen mobile (gaveta menu) | drawer mobile `AppLayout` |
| `tables/` | `PharmaDataTable`, `StickyHeaderTable` | listagens inventário / auditoria |
| `cards/` | `EnterpriseCard`, `StatusCard` | `.enterprise-card`, cards dashboard |
| `loaders/` | `PharmaLinearLoader`, `BlockingOverlay` | `loading` login |
| `dropdowns/` | `PharmaDropdown`, `ActionMenu` | menus de acções |
| `dialogs/` vs `modals/` | *Dialog* = overlay centrado; *Modal* = página parcial / bottom sheet | separar por UX |

**Regra de tamanho:** se um ficheiro ultrapassa ~250–400 linhas, extrair *slots* (`header`, `actions`) ou sub-widgets privados (`_SidebarHeader`).

---

## 2. Separação correcta de componentes

### Camadas de UI (enterprise)

1. **Design system** — `lib/core/theme/` (`AppTheme`, `PharmaTokens`, `AppTypography`, `AppSpacing`, `dimensions`). Sem dependência de módulos.
2. **Layouts de casca** — `lib/shared/layouts/` (`AppLayout`, `AuthLayout`, `PosLayout`, `TabletLayout`). Só composição + *slots* (`child`, `navigationShell`).
3. **Blocos compostos** — `shared/widgets/*` (ex.: `EnterpriseCard`).
4. **Funcionalidade** — `lib/modules/<x>/presentation/widgets/` específicos do domínio.
5. **Página** — `.../presentation/pages/` orquestra providers e layout; **mínimo** de UI condicional.

### Onde fica a lógica

| Camada | Riverpod | Conteúdo |
|--------|----------|-----------|
| `presentation/controllers/` ou `presentation/providers/` | `Notifier`, `AsyncNotifier`, `Provider` | Orquestração UI, chamadas a use cases |
| `domain/usecases/` | — | Regras puras (FEFO, validação receita) |
| `data/` | `Repository` + `Dio` | API / cache local |

**Nunca:** `Dio` ou SQL dentro de `shared/widgets/` (excepto adapters explícitos em `data/`).

---

## 3. Organização por módulos

### Mapeamento React → pastas Flutter (`lib/modules/`)

| Rotas React (`App.tsx` / `AppRoute`) | Módulo Flutter sugerido | Notas |
|--------------------------------------|---------------------------|--------|
| `Login` (sem layout app) | `modules/auth/presentation/pages/login_page.dart` | Usar `AuthLayout` + `AuthController` |
| `ExecutiveDashboard` | `modules/dashboard/executive/` | KPIs, gráficos; dados via providers |
| `POS` + `POSLayout` | `modules/sales/pdv/` | Layout fullscreen dedicado (`PosLayout`) |
| `Inventory` | `modules/pharmacy/products/` ou `modules/stock/inventory/` | Separar catálogo vs movimentos se crescer |
| `Regulatory` | `modules/pharmacy/sanitary/` ou módulo `regulatory` dedicado | Alertas ANARME |
| `PsychotropicsBook` | `modules/pharmacy/psychotropics/` | Livro + logs |
| `RecipesBook` | `modules/pharmacy/prescriptions/` | Receitas |
| `Financial` / `Finance` | `modules/finance/` | |
| `Audit` | `modules/audit/` | |
| `PurchasingHub` | `modules/sales/` ou `modules/stock/` (compras) | Ajustar ao vosso domínio |
| `reports` | `modules/finance/reports/` ou `dashboard` | Placeholder React → página real |

### Providers por módulo

- **Globais** (`lib/app/providers/`): sessão, tema, conectividade, endpoint, WebSocket *connection state*.
- **Por módulo** (`modules/<x>/presentation/providers/`): estado do ecrã (filtros, selecção, passo do wizard PDV).
- **Por feature fina** (opcional): sub-pasta `providers/` sob `pdv/` se ficheiros > tamanho razoável.

### Rotas GoRouter

Ficheiro de referência: `lib/app/router/go_app_router.dart` — paths alinhados ao `AppRoute` TypeScript. Próximo passo enterprise: substituir páginas *placeholder* por `ShellRoute` / `StatefulShellRoute` com **sidebar + outlet** (paridade com `AppLayout.tsx`) e ramo **PDV** com `PosLayout` (paridade com `POSLayout.tsx`).

---

## 4. Widgets reutilizáveis — contratos

- **API estável:** parâmetros nomeados, `const` onde possível, evitar `dynamic`.
- **Estilo:** receber `EdgeInsets? padding` opcional; cores **sempre** de `Theme.of(context)` / `context.pharmaTokens` (extensão em `design_tokens.dart`).
- **Acessibilidade:** `Semantics`, `Tooltip` em ícones de acção (PDV, auditoria).
- **Testes:** golden tests opcionais para `EnterpriseCard` e botões primários.

---

## 5. Estratégia responsiva

### Referência do React

- `AppLayout`: sidebar `lg:flex` (≥ **1024**), header mobile, bottom nav `lg:hidden`, drawer.
- Breakpoint prático: **1024** = desktop com sidebar expandida.

### Flutter

1. **`responsive_framework`** — já integrado em `PharmaErpApp` (`MaterialApp.builder`):

   - `MOBILE` 0–599  
   - `TABLET` 600–1023  
   - `DESKTOP` ≥ 1024  

   Afinar números para coincidir com o protótipo (ex.: desktop = 1024 exactamente).

2. **`lib/shared/responsive/breakpoints.dart`** — manter constantes partilhadas (`Breakpoints.desktop = 1024`) e usar em `LayoutBuilder` onde o pacote não chegue.

3. **Padrões por ecrã**

   - **Mobile:** `NavigationBar` inferior + `Drawer` / *modal* para restantes rotas (como React).  
   - **Desktop:** `NavigationRail` ou sidebar custom (`Row` + `ConstrainedBox` largura 256 / 80 colapsado).  
   - **PDV:** prioridade *touch targets* ≥ 48; zona de leitura de código de barras estável.

4. **`TabletLayout`** — ecrãs híbridas (inventário com grelha + painel lateral).

---

## 6. Arquitectura da UI (visão em camadas)

```text
MaterialApp.router (GoRouter)
 └── ResponsiveBreakpoints
      └── Shell (AppLayout | PosLayout | AuthLayout)
           └── Module Page
                └── Feature widgets (módulo)
                     └── Design system widgets (shared)
```

- **Navegação:** `GoRouter` (deep links, *redirect* por auth, `extra` para argumentos).
- **Estado:** `flutter_riverpod` + `ProviderScope` na raiz (`lib/main.dart`).
- **Rede:** `dio` via `lib/core/network/dio/dio_provider.dart` (interceptors auth/tenant/retry depois).
- **Realtime / sync:** UI só consome `StreamProvider` / `AsyncNotifier` expostos a partir de `core/realtime` e `core/sync` (sem sockets em widgets de formulário).

---

## 7. Mapeamento React → Flutter (padrões)

| React / Tailwind | Flutter nativo sugerido |
|------------------|-------------------------|
| `motion/react` (`AnimatePresence`, layoutId) | `AnimatedSwitcher`, `Hero`, `ImplicitlyAnimatedWidget`, `PageTransitionTheme` no `GoRouter` |
| `className={cn(...)}` | composição de `BoxDecoration`, `InputDecoration`, temas; extrair *helpers* mínimos em `core/utils/` |
| `flex`, `gap`, `p-*` | `Flex`, `Wrap`, `Gap` (Dart 3.16+ `Gap` widget ou `SizedBox`), `Padding` |
| `min-h-screen`, `sticky` | `Scaffold`, `SliverAppBar.pinned`, `CustomScrollView` |
| `backdrop-blur`, `glass` | `BackdropFilter` + `ImageFilter.blur` **com moderação** (custo GPU); preferir opacidade sólida em mobile |
| `@tabler/icons-react` | `Icons.*` Material, ou pacote `tabler_icons` / SVG em `assets/icons/` |
| `Inter`, `JetBrains Mono` | `google_fonts` (opcional) ou fontes em `assets/fonts/` + `ThemeData.textTheme` |
| Estado local `useState` em páginas grandes | `ConsumerWidget` + `StateProvider` / `Notifier` local ou widget `Stateful` *mínimo* |
| `activeRoute` + switch | `GoRouter` + `routes`; *shell* lê `GoRouterState.of(context)` |

---

## 8. Design system Flutter (Material 3 + tokens)

### Tokens (`PharmaTokens`)

Ficheiro: `lib/core/theme/design_tokens.dart` — cores e raios alinhados ao `@theme` do `index.css` (fundo `#05060A`, cartão `#11161D`, *brand* `#22C55E`, estados regulatórios, etc.).

Uso:

```dart
final t = context.pharmaTokens;
Container(color: t.card, child: …);
```

### Tema

- `lib/core/theme/app_theme.dart` — `AppTheme.darkEnterprise` (tema por defeito alinhado ao protótipo escuro).
- `InputDecorationTheme`, `CardThemeData` — base para campos “enterprise” como no login React.

### Próximos passos recomendados

1. Carregar **Inter** / **JetBrains Mono** (`google_fonts` ou assets) e mapear para `textTheme`.
2. Componentizar **badges** (`.status-badge`, estados psicotrópico / quarentena) → `shared/widgets/cards/status_badge.dart`.
3. **Scrollbar** — `ScrollBarTheme` + `RawScrollbar` para aproximar `.modern-scrollbar`.

---

## Stack obrigatória (estado actual do repo)

| Pacote | Uso |
|--------|-----|
| `flutter_riverpod` | `ProviderScope` em `main.dart`; providers por módulo + `dioProvider` |
| `go_router` | `lib/app/router/go_app_router.dart` |
| `dio` | `lib/core/network/dio/dio_provider.dart` |
| `responsive_framework` | `PharmaErpApp` → `ResponsiveBreakpoints.builder` |

---

## Domínio ERP (preparação UI)

| Domínio | Implicações de UI |
|---------|-------------------|
| **PDV** | Teclado físico / atalhos, leitura barcode, lista de linhas com *performance* (`ListView.builder`), feedback táctil |
| **Dashboard** | *Widgets* lazy, *shimmer* loading, evitar rebuild global |
| **Stock / FEFO** | Tabelas densas desktop + vista cartão mobile |
| **Psicotrópicos** | *Badges* de estado, trilho de auditoria legível |
| **Relatórios** | `CustomScrollView`, exportação (futuro), *empty states* |
| **Impressão térmica** | UI apenas dispara *use case*; implementação em `lib/platform/printing/` |
| **Multi-terminal / offline** | Indicadores de sync (`ConnectivityProvider` + estado da fila); não bloquear UI thread |

---

## Resumo

1. **Estrutura de widgets** — taxonomia em `shared/widgets/*` + específicos em `modules/*/presentation/widgets/`.  
2. **Separação** — páginas finas; controllers/providers; sem negócio na UI.  
3. **Módulos** — espelhar domínios React nas pastas `modules/`.  
4. **Reutilização** — tokens + componentes com API clara.  
5. **Responsivo** — `responsive_framework` + constantes + layouts distintos (app vs PDV).  
6. **Arquitectura UI** — tema → layout → página → widget → dados via Riverpod.  
7. **Mapeamento** — tabela acima; animações e ícones com equivalentes Flutter.  
8. **Design system** — `PharmaTokens` + `AppTheme.darkEnterprise` + evolução tipografia.

O protótipo React em `pharmaerp-moçambique (2)/` permanece como **galeria de referência**; o produto Flutter evolui em `lib/` com testes, rotas declarativas e separação limpa por módulo.
