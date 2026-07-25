import 'package:flutter/material.dart';

/// Cabeçalho fixo (sticky) para [CustomScrollView].
///
/// O conteúdo acima deste sliver rola normalmente; quando o cabeçalho chega ao topo,
/// permanece visível enquanto a lista continua a rolar.
class PharmaPinnedSliverHeader extends StatefulWidget {
  const PharmaPinnedSliverHeader({
    super.key,
    required this.child,
    this.initialExtent = 220,
  });

  final Widget child;

  /// Estimativa inicial generosa — evita `SliverGeometry` inválido antes da medição.
  final double initialExtent;

  @override
  State<PharmaPinnedSliverHeader> createState() => _PharmaPinnedSliverHeaderState();
}

class _PharmaPinnedSliverHeaderState extends State<PharmaPinnedSliverHeader> {
  final GlobalKey _childKey = GlobalKey();
  late double _extent = widget.initialExtent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_measureChild);
  }

  @override
  void didUpdateWidget(covariant PharmaPinnedSliverHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      WidgetsBinding.instance.addPostFrameCallback(_measureChild);
    }
  }

  void _measureChild(_) {
    if (!mounted) return;

    final renderObject = _childKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final measured = renderObject.size.height;
    if (measured <= 0) return;

    if ((measured - _extent).abs() > 0.5) {
      setState(() => _extent = measured);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _PharmaPinnedSliverHeaderDelegate(
        extent: _extent,
        child: KeyedSubtree(
          key: _childKey,
          child: widget.child,
        ),
      ),
    );
  }
}

class _PharmaPinnedSliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _PharmaPinnedSliverHeaderDelegate({
    required this.extent,
    required this.child,
  });

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(
      height: extent,
      width: double.infinity,
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          child: child,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PharmaPinnedSliverHeaderDelegate oldDelegate) {
    return extent != oldDelegate.extent || child != oldDelegate.child;
  }
}
