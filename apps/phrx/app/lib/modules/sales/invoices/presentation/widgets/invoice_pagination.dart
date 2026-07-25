import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/responsive/pharma_screen_layout.dart';

class InvoicePagination extends StatelessWidget {
  const InvoicePagination({
    super.key,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    required this.isBusy,
    this.onPrev,
    this.onNext,
    this.onPageSizeChanged,
  });

  final int page;
  final int pageSize;
  final bool hasMore;
  final bool isBusy;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final ValueChanged<int>? onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final screen = context.pharmaScreen;
    final pageSizeOptions = const [10, 25, 50, 100];

    if (screen == PharmaScreenSize.mobile) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Text(
          'Página $page',
          style: Theme.of(context).textTheme.erpTableSecondary,
        ),
        SizedBox(width: s.lg),
        Text(
          hasMore ? 'Mais resultados disponíveis' : 'Fim da lista',
          style: Theme.of(context).textTheme.erpTableSecondary.copyWith(
                color: context.pharmaTokens.textSecondary,
              ),
        ),
        const Spacer(),
        DropdownButton<int>(
          value: pageSizeOptions.contains(pageSize)
              ? pageSize
              : pageSizeOptions.first,
          style: Theme.of(context).textTheme.erpTableSecondary,
          items: pageSizeOptions
              .map(
                (value) => DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value / página'),
                ),
              )
              .toList(growable: false),
          onChanged: isBusy
              ? null
              : (value) => value != null ? onPageSizeChanged?.call(value) : null,
        ),
        SizedBox(width: s.md),
        OutlinedButton.icon(
          onPressed: isBusy ? null : onPrev,
          icon: const Icon(Icons.chevron_left_rounded),
          label: const Text('Anterior'),
        ),
        SizedBox(width: s.sm),
        FilledButton.icon(
          onPressed: isBusy || !hasMore ? null : onNext,
          icon: const Icon(Icons.chevron_right_rounded),
          label: const Text('Próxima'),
        ),
      ],
    );
  }
}
