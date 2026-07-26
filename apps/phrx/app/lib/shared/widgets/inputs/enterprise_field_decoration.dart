import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

/// Decoração canónica de campos enterprise.
///
/// Fonte de verdade: [ThemeData.inputDecorationTheme]
/// ([PharmaComponentTheme.input]).
/// - Altura da caixa = [PharmaTokens.controlHeight] (`isDense: false`)
/// - Label flutuante ([FloatingLabelBehavior.auto]): dentro quando vazio,
///   sobe para a borda ao focar ou preencher.
///
/// Se só [hintText] for passado, promove-o a [labelText].
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
  }) {
    final t = context.pharmaTokens;
    final inputTheme = Theme.of(context).inputDecorationTheme;
    final horizontal = t.density.inputPadding.left;

    final effectiveLabel = labelText ?? hintText;
    final effectiveHint = labelText != null ? hintText : null;

    final decoration = InputDecoration(
      labelText: effectiveLabel,
      hintText: effectiveHint,
      errorText: errorText,
      helperText: helperText,
      suffixText: suffixText,
      enabled: enabled,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    ).applyDefaults(inputTheme).copyWith(
          floatingLabelBehavior: FloatingLabelBehavior.auto,
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
