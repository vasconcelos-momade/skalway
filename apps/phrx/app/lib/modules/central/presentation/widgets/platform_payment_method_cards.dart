import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../domain/entities/platform_entities.dart';

/// Radio cards de método de pagamento (API Central).
class PlatformPaymentMethodCards extends StatelessWidget {
  const PlatformPaymentMethodCards({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  IconData _iconFor(String method) {
    switch (method.toUpperCase()) {
      case PlatformPaymentMethods.cash:
        return Icons.payments_outlined;
      case PlatformPaymentMethods.bankTransfer:
        return Icons.account_balance_outlined;
      case PlatformPaymentMethods.mpesa:
        return Icons.phone_android_outlined;
      case PlatformPaymentMethods.emola:
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.payment_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final method in PlatformPaymentMethods.all) ...[
          if (method != PlatformPaymentMethods.all.first)
            const SizedBox(height: 8),
          _MethodCard(
            selected: value == method,
            enabled: enabled,
            icon: _iconFor(method),
            label: PlatformPaymentMethods.label(method),
            onTap: enabled ? () => onChanged(method) : null,
            selectedBorder: t.brandGreen,
            selectedFill: t.brandGreen.withValues(alpha: 0.08),
            border: t.borderSubtle,
            textStyle: theme.textTheme.titleSmall,
            mutedStyle: theme.textTheme.bodySmall?.copyWith(color: t.textMuted),
          ),
        ],
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.selected,
    required this.enabled,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.selectedBorder,
    required this.selectedFill,
    required this.border,
    required this.textStyle,
    required this.mutedStyle,
  });

  final bool selected;
  final bool enabled;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color selectedBorder;
  final Color selectedFill;
  final Color border;
  final TextStyle? textStyle;
  final TextStyle? mutedStyle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? selectedFill : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? selectedBorder : border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? selectedBorder : mutedStyle?.color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: textStyle),
                    Text(
                      selected ? 'Seleccionado' : 'Toque para seleccionar',
                      style: mutedStyle,
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? selectedBorder : mutedStyle?.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cards de selecção de meses (pagamento antecipado).
class PlatformPrepaidMonthsCards extends StatelessWidget {
  const PlatformPrepaidMonthsCards({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final months in PlatformPrepaidMonths.options)
          ChoiceChip(
            label: Text(
              months == 1 ? '1 mês' : '$months meses',
              style: theme.textTheme.labelLarge,
            ),
            selected: value == months,
            onSelected: enabled
                ? (selected) {
                    if (selected) onChanged(months);
                  }
                : null,
            selectedColor: t.brandGreen.withValues(alpha: 0.16),
            side: BorderSide(
              color: value == months ? t.brandGreen : t.borderSubtle,
            ),
          ),
      ],
    );
  }
}
