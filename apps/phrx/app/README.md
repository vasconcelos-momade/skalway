# pharma_erp

ERP para farmácia em **Flutter** — arranque modular (auth, farmácia, vendas/PDV, stock, finanças, auditoria, etc.).

## Documentação da estrutura

- **Português:** [docs/estrutura_do_projecto.md](docs/estrutura_do_projecto.md) — guia completo, diagrama de dependências e **índice em árvore** de `lib/`.
- **English:** [docs/project_structure.md](docs/project_structure.md) — same guide in English (including the tree).
- **UI React → Flutter:** [docs/ui_react_para_flutter.md](docs/ui_react_para_flutter.md) — design system, responsividade, mapeamento do protótipo `pharmaerp-moçambique (2)/`.
- **Feedback do utilizador:** [docs/pharma_feedback.md](docs/pharma_feedback.md) — `PharmaFeedback` (SnackBar, QuickAlert, Dialog Material); API única para notificações e confirmações.

## Arranque rápido

```bash
# Uma vez (ou após mudar pubspec.yaml / pubspec.lock)
flutter pub get

# Web Chrome — SEM baixar pacotes de novo (use sempre --no-pub no dia-a-dia)
bash scripts/run_web.sh
# equivalente:
flutter run -d chrome --web-port=5000 --no-pub

# Evite isto no dia-a-dia (resolve/baixa pacotes em cada arranque):
# flutter run -d chrome --web-port=5000

# Após alterar dependências (pub get + arranque):
bash scripts/dev_web.sh --deps

# Análise estática (pub get + flutter analyze)
bash scripts/analyze.sh
```

Variáveis locais: copie ou crie um ficheiro **`.env`** na raiz (não é versionado; ver `.gitignore`). Os valores podem ser lidos em `lib/core/config/env.dart` à medida que configurar o projecto.

## Testes

```bash
flutter test
flutter test integration_test/
```

`test/ui_shell_test.dart` cobre o fluxo de **login → dashboard** e **navegação para inventário** (GoRouter + Riverpod).

## Recursos Flutter

- [Documentação Flutter](https://docs.flutter.dev/)
- [Codelab inicial](https://docs.flutter.dev/get-started/codelab)
- [Cookbook](https://docs.flutter.dev/cookbook)
