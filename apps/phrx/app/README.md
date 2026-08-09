# Skalway PhRx

ERP farmacêutico **Flutter** — arranque modular (auth, farmácia, vendas/PDV, stock, finanças, auditoria, etc.).

## Documentação da estrutura

- **Português:** [docs/estrutura_do_projecto.md](docs/estrutura_do_projecto.md) — guia completo, diagrama de dependências e **índice em árvore** de `lib/`.
- **English:** [docs/project_structure.md](docs/project_structure.md) — same guide in English (including the tree).
- **UI React → Flutter:** [docs/ui_react_para_flutter.md](docs/ui_react_para_flutter.md) — design system, responsividade, mapeamento do protótipo React.
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

## Instaladores (padrão Scalway Gastro)

```bash
# APK Release (split por ABI) — em apps/phrx/app
./build-apk.sh
# produção:
ENVIRONMENT=prod ./build-apk.sh

# Ou a partir de apps/phrx (clean + split + validação):
./build-prod-apk.sh
./build-dev-apk.sh

# Pacote Debian (.deb)
./build_deb.sh

# AppImage (opcional)
./build_appimage.sh
```

Saídas:
- APKs: `build/app/outputs/flutter-apk/SkalwayPhRx-v1.0.0-*.apk`
- Deb: `skalway-phrx_1.0.0_amd64.deb` (na raiz do app)
- AppImage: `SkalwayPhRx-1.0.0-x86_64.AppImage`
