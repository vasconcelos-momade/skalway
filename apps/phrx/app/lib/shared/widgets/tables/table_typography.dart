import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';

/// Tipografia unificada de tabelas (14px — alinhada à sidebar).
abstract final class TableTypography {
  TableTypography._();

  static TextStyle header(BuildContext context, {Color? color}) {
    final t = context.pharmaTokens;
    return Theme.of(context).textTheme.erpTableHeader.copyWith(
          color: color ?? t.textMuted,
        );
  }

  static TextStyle primary(BuildContext context, {Color? color}) {
    final t = context.pharmaTokens;
    return Theme.of(context).textTheme.erpTablePrimary.copyWith(
          color: color ?? t.textPrimary,
        );
  }

  static TextStyle cell(
    BuildContext context, {
    Color? color,
    bool muted = false,
  }) {
    final t = context.pharmaTokens;
    return Theme.of(context).textTheme.erpTableSecondary.copyWith(
          color: color ?? (muted ? t.textMuted : t.textPrimary),
        );
  }

  static TextStyle meta(BuildContext context, {Color? color}) {
    final t = context.pharmaTokens;
    return Theme.of(context).textTheme.erpTableMeta.copyWith(
          color: color ?? t.textMuted,
        );
  }

  static Widget headerLabel(BuildContext context, String label) {
    return Text(label.toUpperCase(), style: header(context));
  }

  static Widget cellText(
    BuildContext context,
    String text, {
    bool muted = false,
    TextStyle? style,
  }) {
    return Text(
      text,
      style: style ?? cell(context, muted: muted),
    );
  }
}
