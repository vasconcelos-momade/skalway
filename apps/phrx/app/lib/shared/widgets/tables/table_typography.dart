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

  static TextStyle secondary(
    BuildContext context, {
    Color? color,
    bool muted = false,
  }) {
    final t = context.pharmaTokens;
    return Theme.of(context).textTheme.erpTableSecondary.copyWith(
          color: color ?? (muted ? t.textMuted : t.textSecondary),
        );
  }

  static TextStyle metadata(
    BuildContext context, {
    Color? color,
    bool muted = false,
  }) {
    final t = context.pharmaTokens;
    return Theme.of(context).textTheme.erpTableMetadata.copyWith(
          color: color ?? (muted ? t.textMuted : t.textMuted),
        );
  }

  /// Legado — preferir [metadata].
  static TextStyle meta(BuildContext context, {Color? color}) =>
      metadata(context, color: color);

  static TextStyle numeric(BuildContext context, {Color? color}) {
    final t = context.pharmaTokens;
    return Theme.of(context).textTheme.erpTableNumeric.copyWith(
          color: color ?? t.textPrimary,
        );
  }

  static TextStyle status(BuildContext context, {Color? color}) {
    final t = context.pharmaTokens;
    return Theme.of(context).textTheme.erpTableStatus.copyWith(
          color: color ?? t.textSecondary,
        );
  }

  /// Legado — preferir [secondary].
  static TextStyle cell(
    BuildContext context, {
    Color? color,
    bool muted = false,
  }) =>
      secondary(context, color: color, muted: muted);

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
      style: style ?? secondary(context, muted: muted),
    );
  }
}
