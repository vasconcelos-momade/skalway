import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';
import 'table_typography.dart';

/// Cabeçalho de coluna — aplica [erpTableHeader].
class TableHeaderCell extends StatelessWidget {
  const TableHeaderCell(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label.toUpperCase(), style: TableTypography.header(context));
  }
}

/// Texto principal da célula — aplica [erpTablePrimary].
class TablePrimaryCell extends StatelessWidget {
  const TablePrimaryCell(
    this.text, {
    super.key,
    this.subtitle,
    this.color,
    this.maxLines = 2,
    this.overflow = TextOverflow.ellipsis,
  });

  final String text;
  final String? subtitle;
  final Color? color;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    if (subtitle != null && subtitle!.trim().isNotEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: s.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TableTypography.primary(context, color: color),
              maxLines: maxLines,
              overflow: overflow,
            ),
            SizedBox(height: s.xxs),
            TableSecondaryCell(subtitle!),
          ],
        ),
      );
    }

    return Text(
      text,
      style: TableTypography.primary(context, color: color),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Informação secundária — aplica [erpTableSecondary].
class TableSecondaryCell extends StatelessWidget {
  const TableSecondaryCell(
    this.text, {
    super.key,
    this.color,
    this.muted = false,
    this.maxLines = 2,
    this.overflow = TextOverflow.ellipsis,
  });

  final String text;
  final Color? color;
  final bool muted;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TableTypography.secondary(
        context,
        color: color,
        muted: muted,
      ),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Códigos, emails, datas e referências — aplica [erpTableMetadata].
class TableMetadataCell extends StatelessWidget {
  const TableMetadataCell(
    this.text, {
    super.key,
    this.emptyPlaceholder = '—',
    this.color,
    this.maxLines = 2,
    this.overflow = TextOverflow.ellipsis,
  });

  final String? text;
  final String emptyPlaceholder;
  final Color? color;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final value = text?.trim();
    final empty = value == null || value.isEmpty;

    return Text(
      empty ? emptyPlaceholder : value,
      style: TableTypography.metadata(
        context,
        color: color,
        muted: empty,
      ),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Valores numéricos e financeiros — aplica [erpTableNumeric].
class TableNumericCell extends StatelessWidget {
  const TableNumericCell(
    this.text, {
    super.key,
    this.color,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  final String text;
  final Color? color;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TableTypography.numeric(context, color: color),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: TextAlign.end,
    );
  }
}

/// Estado com indicador opcional — aplica [erpTableStatus].
class TableStatusCell extends StatelessWidget {
  const TableStatusCell({
    super.key,
    required this.label,
    this.active,
    this.color,
    this.showDot = true,
  });

  final String label;
  final bool? active;
  final Color? color;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final indicatorColor = color ??
        switch (active) {
          true => t.brandGreen,
          false => t.textMuted,
          null => t.textSecondary,
        };

    if (!showDot) {
      return Text(
        label,
        style: TableTypography.status(context, color: indicatorColor),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: SpacingTokens.xs,
          height: SpacingTokens.xs,
          decoration: BoxDecoration(
            color: indicatorColor,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: SpacingTokens.sm),
        Text(
          label,
          style: TableTypography.status(
            context,
            color: t.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Cria [DataColumn] com cabeçalho padronizado.
DataColumn enterpriseDataColumn(
  BuildContext context,
  String label, {
  bool numeric = false,
  String? tooltip,
  void Function(int columnIndex, bool ascending)? onSort,
}) {
  return DataColumn(
    label: TableHeaderCell(label),
    numeric: numeric,
    tooltip: tooltip,
    onSort: onSort,
  );
}
