import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/errors/api_failure.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/layouts/auth_layout.dart';
import '../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../shared/widgets/buttons/pharma_button_loader.dart';
import '../../data/repositories/auth_repository_impl.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(
            email: _email.text.trim(),
          );
      if (!mounted) return;
      PharmaFeedback.success(
        context,
        'Se o e-mail estiver registado, receberá instruções de recuperação em breve.',
      );
      if (!mounted) return;
      context.go(AppRoutePaths.login);
    } on ApiFailure catch (e) {
      if (!mounted) return;
      await PharmaFeedback.criticalError(
        context: context,
        title: 'Falha ao solicitar recuperação',
        message: e.message,
      );
    } catch (e) {
      if (!mounted) return;
      await PharmaFeedback.criticalError(
        context: context,
        title: 'Falha ao solicitar recuperação',
        message: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return AuthLayout(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Recuperar acesso',
                style: Theme.of(context).textTheme.erpSectionTitle,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Enviaremos instruções para o e-mail corporativo registado.',
                style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
              ),
              const SizedBox(height: AppSpacing.xxl),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'E-mail'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Indique o e-mail';
                  }
                  if (!value.contains('@')) {
                    return 'E-mail inválido';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? PharmaButtonLoader(color: t.bgPrimary)
                    : const Text('Enviar ligação'),
              ),
              TextButton(
                onPressed: _loading ? null : () => context.go(AppRoutePaths.login),
                child: const Text('Voltar ao login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
