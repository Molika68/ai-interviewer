/// 雷达图组件（自定义绘制，不依赖第三方图表库）。
///
/// 用 CustomPainter 直接绘制能力维度多边形，包体更小、渲染可控，
/// 也避免图表库大版本升级带来的 API 兼容问题。
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 雷达图的一个维度。
class RadarItem {
  const RadarItem({required this.label, required this.value});

  final String label;
  final double value;
}

class RadarChart extends StatelessWidget {
  const RadarChart({
    super.key,
    required this.items,
    this.maxValue = 100,
    this.size = 240,
    this.color,
  });

  final List<RadarItem> items;
  final double maxValue;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fallback = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RadarPainter(
          items: items,
          maxValue: maxValue,
          color: color ?? fallback,
          labelStyle: Theme.of(context).textTheme.bodySmall ??
              const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.items,
    required this.maxValue,
    required this.color,
    required this.labelStyle,
  });

  final List<RadarItem> items;
  final double maxValue;
  final Color color;
  final TextStyle labelStyle;

  static const int _gridCount = 4;

  @override
  void paint(Canvas canvas, Size size) {
    if (items.length < 3) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 30;
    final count = items.length;
    const startAngle = -math.pi / 2;

    Offset point(int index, double r) {
      final angle = startAngle + (2 * math.pi / count) * index;
      return Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
    }

    // 网格
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var g = 1; g <= _gridCount; g++) {
      final r = radius * g / _gridCount;
      final path = Path();
      for (var i = 0; i < count; i++) {
        final p = point(i, r);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // 轴线
    for (var i = 0; i < count; i++) {
      canvas.drawLine(center, point(i, radius), gridPaint);
    }

    // 数据多边形
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final dataPath = Path();
    for (var i = 0; i < count; i++) {
      final ratio = (items[i].value / maxValue).clamp(0.0, 1.0);
      final p = point(i, radius * ratio);
      if (i == 0) {
        dataPath.moveTo(p.dx, p.dy);
      } else {
        dataPath.lineTo(p.dx, p.dy);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);

    // 顶点
    final dotPaint = Paint()..color = color;
    for (var i = 0; i < count; i++) {
      final ratio = (items[i].value / maxValue).clamp(0.0, 1.0);
      canvas.drawCircle(point(i, radius * ratio), 3.2, dotPaint);
    }

    // 标签
    for (var i = 0; i < count; i++) {
      final label = '${items[i].label} ${items[i].value.toStringAsFixed(0)}';
      final painter = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final outer = point(i, radius + 14);
      final dx = outer.dx - painter.width / 2;
      final dy = outer.dy - painter.height / 2;
      painter.paint(canvas, Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.items != items ||
      oldDelegate.color != color ||
      oldDelegate.maxValue != maxValue;
}
