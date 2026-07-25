import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/auth_session_notifier.dart';
import '../../../../app/providers/connection_notifier.dart' as conn;
import '../../../../app/router/routes.dart';
import '../../../../core/config/api_host_resolver.dart';
import '../../../../core/network/connectivity/connection_mode.dart';
import '../../../../core/network/connectivity/connection_status.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/layouts/auth_layout.dart';
import '../../../../shared/responsive/pharma_screen_layout.dart';
import '../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../shared/widgets/buttons/pharma_button_loader.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final redirect = await ref.read(authSessionProvider.notifier).login(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
    if (!mounted) return;

    if (redirect == null) {
      var msg = ref.read(authSessionProvider).errorMessage;
      if (msg != null) {
        if (msg.contains('Sem ligação ao servidor')) {
          msg = '$msg\n${ApiHostResolver.connectionHintForPlatform()}';
        }
        await PharmaFeedback.criticalError(
          context: context,
          title: 'Falha no início de sessão',
          message: msg,
        );
      }
      return;
    }

    context.go(redirect);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final isMobile = PharmaScreenLayout.isMobile(context);
    final auth = ref.watch(authSessionProvider);
    final connection = ref.watch(conn.connectionNotifierProvider);
    final loading = auth.isLoading || auth.isBootstrapping;
    final showConnectionBanner = connection.isOffline;
    final connectionMessage = switch (connection.status) {
      ConnectionStatus.offline =>
        'Sem ligação ao servidor local nem ao serviço na nuvem. Pode tentar novamente quando a rede estabilizar.',
      _ => null,
    };

    return AuthLayout(
      showOfflineBanner: showConnectionBanner,
      offlineMessage: connectionMessage,
      scrollPadding: isMobile
          ? EdgeInsets.symmetric(horizontal: s.sm, vertical: s.md)
          : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 440,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: isMobile ? s.xl : AppSpacing.xxxl),
              _LoginFormPanel(
                isMobile: isMobile,
                connection: connection,
                loading: loading,
                obscure: _obscure,
                emailCtrl: _emailCtrl,
                passCtrl: _passCtrl,
                onToggleObscure: () => setState(() => _obscure = !_obscure),
                onSubmit: _submit,
                onForgotPassword: () =>
                    context.push(AppRoutePaths.authForgotPassword),
              ),
              SizedBox(height: isMobile ? s.lg : AppSpacing.xxl),
              Text(
                '© 2026 Pharma ERP — Operação crítica com auditoria e rastreio ANARME.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.erpOverline.copyWith(color: t.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginFormPanel extends StatelessWidget {
  const _LoginFormPanel({
    required this.isMobile,
    required this.connection,
    required this.loading,
    required this.obscure,
    required this.emailCtrl,
    required this.passCtrl,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onForgotPassword,
  });

  final bool isMobile;
  final conn.ConnectionState connection;
  final bool loading;
  final bool obscure;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Iniciar sessão',
          style: Theme.of(context).textTheme.erpCardTitle.copyWith(color: t.textMuted),
        ),
        SizedBox(height: s.sm),
        Wrap(
          spacing: s.sm,
          runSpacing: s.sm,
          children: [
            _StatusChip(
              icon: connection.mode == ConnectionMode.cloud
                  ? Icons.cloud_done_outlined
                  : Icons.lan_outlined,
              label: connection.mode == ConnectionMode.cloud
                  ? 'Modo nuvem'
                  : 'Modo local',
              color: connection.mode == ConnectionMode.cloud
                  ? t.brandGreenHover
                  : t.brandGreen,
            ),
            _StatusChip(
              icon: connection.isOffline
                  ? Icons.cloud_off_outlined
                  : Icons.check_circle_outline_rounded,
              label: connection.isOffline
                  ? 'Sem ligação'
                  : (connection.mode == ConnectionMode.cloud
                      ? 'Nuvem activa'
                      : 'Local activo'),
              color: connection.isOffline ? t.posDanger : t.brandGreen,
            ),
          ],
        ),
        SizedBox(height: s.lg),
        TextFormField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'E-mail',
            prefixIcon: Icon(Icons.alternate_email_rounded),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Indique o e-mail';
            }
            if (!v.contains('@')) {
              return 'E-mail inválido';
            }
            return null;
          },
        ),
        SizedBox(height: s.lg),
        TextFormField(
          controller: passCtrl,
          obscureText: obscure,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          enableSuggestions: false,
          onFieldSubmitted: (_) => onSubmit(),
          decoration: InputDecoration(
            labelText: 'Palavra-passe',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              onPressed: onToggleObscure,
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) {
              return 'Indique a palavra-passe';
            }
            return null;
          },
        ),
        SizedBox(height: s.sm),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onForgotPassword,
            child: const Text('Esqueceu-se da palavra-passe?'),
          ),
        ),
        SizedBox(height: s.lg),
        FilledButton(
          onPressed: loading ? null : onSubmit,
          child: loading
              ? PharmaButtonLoader(color: t.bgPrimary)
              : const Text('Entrar'),
        ),
      ],
    );

    if (isMobile) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: s.xs),
        child: content,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: content,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.erpLabel.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
