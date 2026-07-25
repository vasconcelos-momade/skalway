import 'package:flutter/material.dart';

import '../../../../../core/theme/design_metrics.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../domain/entities/user_entities.dart';
import 'user_card.dart';

class UserList extends StatefulWidget {
  const UserList({
    super.key,
    required this.items,
    required this.hasMore,
    required this.isLoading,
    required this.onLoadMore,
    required this.onItemTap,
  });

  final List<TenantUserSummary> items;
  final bool hasMore;
  final bool isLoading;
  final VoidCallback onLoadMore;
  final void Function(TenantUserSummary) onItemTap;

  @override
  State<UserList> createState() => _UserListState();
}

class _UserListState extends State<UserList> {
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

    return ListView.separated(
      controller: _scrollController,
      padding: EdgeInsets.zero,
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

        final user = widget.items[index];
        return UserCard(
          user: user,
          onTap: () => widget.onItemTap(user),
        );
      },
    );
  }
}
