import 'package:flutter/material.dart';

import '../../../../../core/theme/design_metrics.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../pharmacy/products/domain/entities/product.dart';
import 'pdv_product_card.dart';

class PdvProductList extends StatefulWidget {
  const PdvProductList({
    super.key,
    required this.items,
    required this.query,
    required this.hasMore,
    required this.isLoading,
    required this.canAdd,
    required this.addingProductId,
    required this.onAdd,
    required this.onLoadMore,
    this.bottomPadding = 0,
  });

  final List<Product> items;
  final String query;
  final bool hasMore;
  final bool isLoading;
  final bool canAdd;
  final String? addingProductId;
  final void Function(Product product) onAdd;
  final VoidCallback onLoadMore;
  final double bottomPadding;

  @override
  State<PdvProductList> createState() => _PdvProductListState();
}

class _PdvProductListState extends State<PdvProductList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMore || widget.isLoading) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final textTheme = Theme.of(context).textTheme;

    if (widget.items.isEmpty && !widget.isLoading) {
      return ModuleEmptyState(
        title: widget.query.isEmpty
            ? 'Nenhum produto disponível.'
            : 'Nenhum produto encontrado.',
        subtitle: widget.query.isEmpty ? null : 'Tente outro nome, código ou EAN.',
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: EdgeInsets.only(bottom: widget.bottomPadding + s.md),
      itemCount: widget.items.length + 1,
      separatorBuilder: (_, index) {
        if (index >= widget.items.length - 1) {
          return const SizedBox.shrink();
        }
        return const EnterpriseListDivider();
      },
      itemBuilder: (context, index) {
        if (index == widget.items.length) {
          if (widget.isLoading) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: s.lg),
              child: Center(
                child: SizedBox(
                  width: DesignMetrics.iconMd,
                  height: DesignMetrics.iconMd,
                  child: CircularProgressIndicator(
                    strokeWidth: DesignMetrics.buttonLoaderStrokeWidth,
                  ),
                ),
              ),
            );
          }
          if (!widget.hasMore && widget.items.isNotEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: s.lg),
              child: Center(
                child: Text(
                  'Fim da lista',
                  style: textTheme.erpCaption.copyWith(color: t.textMuted),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final product = widget.items[index];
        final lineId = 'produto:${product.id}';
        return PdvProductCard(
          product: product,
          canAdd: widget.canAdd,
          isAdding: widget.addingProductId == lineId,
          onAdd: () => widget.onAdd(product),
          compactAction: true,
        );
      },
    );
  }
}
