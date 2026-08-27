import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/extensions.dart';
import '../../modules/sales/pdv/presentation/providers/caixa_sessao_provider.dart';
import '../../modules/sales/pdv/presentation/widgets/abrir_caixa_dialog.dart';
import '../../platform/desktop/desktop_title_bar.dart';
import '../responsive/pharma_screen_layout.dart';
import '../widgets/buttons/pharma_button_loader.dart';
import '../widgets/sync/sync_status_strip.dart';

/// Chrome PDV ultra-rápido: atalhos, scanner, sync e saída segura.
class PosLayout extends ConsumerWidget {
  const PosLayout({super.key, required this.child});

  final Widget child;

  Future<void> _onCaixaPressed(
    BuildContext context,
    WidgetRef ref,
    CaixaSessaoState caixaState,
  ) async {
    if (caixaState.hasSessaoAberta && caixaState.sessaoAtual != null) {
      await showFecharCaixaDialog(context, sessao: caixaState.sessaoAtual!);
      return;
    }

    await showAbrirCaixaDialog(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final isMobile = PharmaScreenLayout.isMobile(context);
    final horizontalInset = isMobile
        ? PharmaScreenLayout.mobileHorizontalInset(context)
        : t.density.gutter;
    final caixaState = ref.watch(caixaSessaoProvider);
    final sessaoAtual = caixaState.sessaoAtual;
    final caixaAberto = sessaoAtual != null;
    final caixaLabel = caixaAberto ? 'Caixa Aberto' : 'Abrir Caixa';
    final caixaIcon =
        caixaAberto ? Icons.lock_open_rounded : Icons.lock_outline_rounded;
    final caixaColor = caixaAberto ? t.brandGreen : t.posDanger;

    return Scaffold(
      backgroundColor: t.bgPrimary,
      body: Column(
        children: [
          // Fundo do header pinta o status bar; toolbar = 56.
          DecoratedBox(
            decoration: BoxDecoration(
              color: t.bgSecondary,
              border: Border(bottom: BorderSide(color: t.border)),
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: t.posHeader,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalInset),
                  child: LayoutBuilder(
                    builder: (context, bx) {
                      final narrow = bx.maxWidth < Breakpoints.mobile;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: DesktopWindowDragArea(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'PhRx — PDV',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      Theme.of(context).textTheme.erpAppName,
                                ),
                              ),
                            ),
                          ),
                          if (!narrow && caixaState.isLoading)
                            Padding(
                              padding: EdgeInsets.only(right: s.sm),
                              child: const PharmaButtonLoader(),
                            ),
                          Tooltip(
                            message: caixaLabel,
                            child: narrow
                                ? SizedBox.square(
                                    dimension: t.controlHeight,
                                    child: IconButton(
                                      onPressed: caixaState.isSubmitting
                                          ? null
                                          : () => _onCaixaPressed(
                                                context,
                                                ref,
                                                caixaState,
                                              ),
                                      icon:
                                          Icon(caixaIcon, color: caixaColor),
                                    ),
                                  )
                                : OutlinedButton.icon(
                                    onPressed: caixaState.isSubmitting
                                        ? null
                                        : () => _onCaixaPressed(
                                              context,
                                              ref,
                                              caixaState,
                                            ),
                                    icon: caixaState.isSubmitting
                                        ? const PharmaButtonLoader()
                                        : Icon(caixaIcon, color: caixaColor),
                                    label: Text(
                                      caixaLabel,
                                      style: Theme.of(context)
                                          .textTheme
                                          .erpButtonSecondary
                                          .copyWith(color: caixaColor),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color:
                                            caixaColor.withValues(alpha: 0.45),
                                      ),
                                    ),
                                  ),
                          ),
                          SizedBox(width: narrow ? s.sm : s.md),
                          SyncStatusStrip(
                            state: SyncVisualState.online,
                            pendingCount: 0,
                            compact: narrow,
                          ),
                          SizedBox(width: narrow ? s.sm : s.lg),
                          if (narrow)
                            SizedBox.square(
                              dimension: t.controlHeight,
                              child: IconButton(
                                tooltip: 'Sair PDV',
                                onPressed: () =>
                                    context.go(AppRoutePaths.dashboard),
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: t.textSecondary,
                                ),
                              ),
                            )
                          else
                            TextButton.icon(
                              onPressed: () =>
                                  context.go(AppRoutePaths.dashboard),
                              icon: Icon(
                                Icons.arrow_back_rounded,
                                color: t.textSecondary,
                                size: t.iconSm,
                              ),
                              label: Text(
                                'Sair do PDV',
                                style: Theme.of(context)
                                    .textTheme
                                    .erpLabel
                                    .copyWith(color: t.textSecondary),
                              ),
                            ),
                          const DesktopWindowControls(),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalInset),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
