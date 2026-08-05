import 'package:flutter/material.dart';

class ChainTimelineArrow extends StatelessWidget {
  const ChainTimelineArrow({super.key, required this.showArrow});

  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.outlineVariant;

    return SizedBox(
      width: 40,
      child: CustomPaint(
        painter: _TimelineArrowPainter(color: color, showArrow: showArrow),
      ),
    );
  }
}

class _TimelineArrowPainter extends CustomPainter {
  _TimelineArrowPainter({required this.color, required this.showArrow});

  final Color color;
  final bool showArrow;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final x = size.width / 2;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);

    if (showArrow && size.height > 12) {
      final tip = Offset(x, size.height);
      canvas.drawLine(tip, Offset(x - 5, size.height - 8), paint);
      canvas.drawLine(tip, Offset(x + 5, size.height - 8), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineArrowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.showArrow != showArrow;
}
