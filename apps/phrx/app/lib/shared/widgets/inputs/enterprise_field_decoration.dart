import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';

/// Decoração canónica de campos enterprise.
///
/// Fonte de verdade: [ThemeData.inputDecorationTheme]
/// ([PharmaComponentTheme.input]).
/// - Altura da caixa = [PharmaTokens.controlHeight] (`isDense: true` +
///   padding vertical calculado a partir da tipografia)
/// - Label flutuante ([FloatingLabelBehavior.auto]): dentro quando vazio,
///   sobe para a borda ao focar ou preencher.
///
/// Se só [hintText] for passado e [floatingLabel] for true, promove-o a
/// [labelText].
abstract final class EnterpriseFieldDecoration {
  EnterpriseFieldDecoration._();

  static InputDecoration of(
    BuildContext context, {
    String? labelText,
    String? hintText,
    String? errorText,
    String? helperText,
    String? suffixText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool enabled = true,
    bool multiline = false,
    bool floatingLabel = true,
  }) {
    final t = context.pharmaTokens;
    final inputTheme = Theme.of(context).inputDecorationTheme;
    final horizontal = t.density.inputPadding.left;

    final String? effectiveLabel;
    final String? effectiveHint;
    if (floatingLabel) {
      effectiveLabel = labelText ?? hintText;
      effectiveHint = labelText != null ? hintText : null;
    } else {
      effectiveLabel = labelText;
      effectiveHint = hintText ?? labelText;
    }

    final decoration = InputDecoration(
      labelText: effectiveLabel,
      hintText: effectiveHint,
      errorText: errorText,
      helperText: helperText,
      suffixText: suffixText,
      enabled: enabled,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      floatingLabelBehavior: floatingLabel
          ? FloatingLabelBehavior.auto
          : FloatingLabelBehavior.never,
    ).applyDefaults(inputTheme).copyWith(
          floatingLabelBehavior: floatingLabel
              ? FloatingLabelBehavior.auto
              : FloatingLabelBehavior.never,
        );

    if (!multiline) return decoration;

    return decoration.copyWith(
      contentPadding: EdgeInsets.symmetric(
        horizontal: horizontal,
        vertical: t.density.inputPadding.top,
      ),
    );
  }
}

class EnterpriseFieldGroup extends StatelessWidget {
  const EnterpriseFieldGroup({
    super.key,
    this.labelText,
    required this.child,
  });

  final String? labelText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final label = labelText?.trim();
    if (label == null || label.isEmpty) return child;

    final t = context.pharmaTokens;
    final s = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(left: s.xxs, bottom: s.xs),
          child: Text(
            label,
            style: Theme.of(context).textTheme.erpFieldLabel.copyWith(
                  color: t.textSecondary,
                ),
          ),
        ),
        child,
      ],
    );
  }
}
