import 'package:flutter/material.dart';

/// Ícone de menu lateral — quadrado arredondado com divisória vertical.
class SidebarMenuIcon extends StatelessWidget {
  const SidebarMenuIcon({
    super.key,
    required this.color,
    this.size = 24,
    this.strokeWidth = 1.75,
  });

  final Color color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _SidebarMenuIconPainter(
        color: color,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _SidebarMenuIconPainter extends CustomPainter {
  _SidebarMenuIconPainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final inset = strokeWidth / 2;
    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(size.width * 0.22),
    );
    canvas.drawRRect(outer, paint);

    final dividerX = size.width * 0.32;
    canvas.drawLine(
      Offset(dividerX, inset + size.height * 0.12),
      Offset(dividerX, size.height - inset - size.height * 0.12),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SidebarMenuIconPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
