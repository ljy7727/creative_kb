// 用量图表：模块占比环形图 + 模型柱状图。
// 纯 CustomPaint 实现，不引第三方图表库（docs/04 T3）。
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

final _compact = NumberFormat.compact();

const _palette = <Color>[
  Color(0xFF00695C),
  Color(0xFF3949AB),
  Color(0xFFEF6C00),
  Color(0xFFC2185B),
  Color(0xFF2E7D32),
  Color(0xFF1E88E5),
  Color(0xFF7B1FA2),
  Color(0xFF6D4C41),
  Color(0xFF546E7A),
  Color(0xFFF9A825),
];

class _PieSlice {
  const _PieSlice({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
  });

  final String label;
  final int value;
  final double fraction;
  final Color color;
}

/// 按模块占比（环形图 + 图例）。
class UsagePieChart extends StatelessWidget {
  const UsagePieChart({super.key, required this.data});

  /// key → output token 合计。
  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slices = _slicesOf(data);
    if (slices.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(child: Text('暂无数据', style: theme.textTheme.bodySmall)),
      );
    }
    final total = slices.fold<int>(0, (sum, s) => sum + s.value);
    return Column(
      children: [
        SizedBox(
          width: 180,
          height: 180,
          child: CustomPaint(
            painter: _PiePainter(
              slices: slices,
              holeColor: theme.cardColor,
              centerLabel: '总计 ${_compact.format(total)}',
              centerStyle:
                  theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...[
          for (final slice in slices)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: slice.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      slice.label,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${(slice.fraction * 100).toStringAsFixed(1)}%'
                    ' · ${_compact.format(slice.value)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  static List<_PieSlice> _slicesOf(Map<String, int> data) {
    final entries = data.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);
    if (total == 0) return const <_PieSlice>[];
    return <_PieSlice>[
      for (var i = 0; i < entries.length; i++)
        _PieSlice(
          label: entries[i].key,
          value: entries[i].value,
          fraction: entries[i].value / total,
          color: _palette[i % _palette.length],
        ),
    ];
  }
}

class _PiePainter extends CustomPainter {
  const _PiePainter({
    required this.slices,
    required this.holeColor,
    required this.centerLabel,
    required this.centerStyle,
  });

  final List<_PieSlice> slices;
  final Color holeColor;
  final String centerLabel;
  final TextStyle centerStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    if (slices.length == 1) {
      canvas.drawCircle(center, radius, Paint()..color = slices.single.color);
    } else {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()..style = PaintingStyle.fill;
      var start = -math.pi / 2;
      for (var i = 0; i < slices.length; i++) {
        // 末片直接画到起点，避免浮点误差留下缝隙。
        final sweep = i == slices.length - 1
            ? 2 * math.pi - (start + math.pi / 2)
            : slices[i].fraction * 2 * math.pi;
        paint.color = slices[i].color;
        canvas.drawArc(rect, start, sweep, true, paint);
        start += sweep;
      }
    }
    canvas.drawCircle(center, radius * 0.58, Paint()..color = holeColor);
    final painter = TextPainter(
      text: TextSpan(text: centerLabel, style: centerStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_PiePainter oldDelegate) =>
      oldDelegate.slices != slices ||
      oldDelegate.holeColor != holeColor ||
      oldDelegate.centerLabel != centerLabel;
}

class _Bar {
  const _Bar({required this.label, required this.value});

  final String label;
  final int value;
}

/// 按模型柱状图（纵向柱，最多 [maxBars] 根，其余并入「其他N项」）。
class UsageBarChart extends StatelessWidget {
  const UsageBarChart({super.key, required this.data, this.maxBars = 7});

  /// key → output token 合计。
  final Map<String, int> data;
  final int maxBars;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bars = _barsOf(data, maxBars);
    if (bars.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(child: Text('暂无数据', style: theme.textTheme.bodySmall)),
      );
    }
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarPainter(
          bars: bars,
          barColor: theme.colorScheme.primary,
          labelStyle:
              theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ) ??
              const TextStyle(fontSize: 11),
          valueStyle:
              theme.textTheme.bodySmall ?? const TextStyle(fontSize: 11),
        ),
      ),
    );
  }

  static List<_Bar> _barsOf(Map<String, int> data, int maxBars) {
    final entries = data.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) return const <_Bar>[];
    final kept = entries.take(maxBars).toList();
    final rest = entries.skip(maxBars).toList();
    if (rest.isNotEmpty) {
      kept.add(
        MapEntry(
          '其他${rest.length}项',
          rest.fold<int>(0, (sum, e) => sum + e.value),
        ),
      );
    }
    return <_Bar>[
      for (final entry in kept) _Bar(label: entry.key, value: entry.value),
    ];
  }
}

class _BarPainter extends CustomPainter {
  const _BarPainter({
    required this.bars,
    required this.barColor,
    required this.labelStyle,
    required this.valueStyle,
  });

  final List<_Bar> bars;
  final Color barColor;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  @override
  void paint(Canvas canvas, Size size) {
    const valueArea = 16.0;
    const labelArea = 18.0;
    if (bars.isEmpty) return;
    final plotBottom = size.height - labelArea;
    final plotHeight = plotBottom - valueArea;
    final maxValue = bars.map((b) => b.value).reduce(math.max);
    if (plotHeight <= 0 || maxValue <= 0) return;

    final slot = size.width / bars.length;
    final barWidth = math.min(slot * 0.6, 48.0);
    final fill = Paint()..color = barColor;
    final baseline = Paint()
      ..color = labelStyle.color ?? const Color(0x66000000)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, plotBottom),
      Offset(size.width, plotBottom),
      baseline,
    );

    for (var i = 0; i < bars.length; i++) {
      final bar = bars[i];
      final cx = slot * i + slot / 2;
      final barHeight = bar.value / maxValue * plotHeight;
      final rect = Rect.fromLTWH(
        cx - barWidth / 2,
        plotBottom - barHeight,
        barWidth,
        barHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        ),
        fill,
      );
      _drawText(
        canvas,
        _compact.format(bar.value),
        cx,
        rect.top - valueArea,
        valueStyle,
      );
      _drawText(
        canvas,
        bar.label,
        cx,
        plotBottom + 3,
        labelStyle,
        maxWidth: slot * 0.96,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    double centerX,
    double top,
    TextStyle style, {
    double? maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth ?? double.infinity);
    painter.paint(canvas, Offset(centerX - painter.width / 2, top));
  }

  @override
  bool shouldRepaint(_BarPainter oldDelegate) =>
      oldDelegate.bars != bars ||
      oldDelegate.barColor != barColor ||
      oldDelegate.labelStyle != labelStyle;
}
