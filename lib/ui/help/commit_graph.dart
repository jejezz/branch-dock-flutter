import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'concepts.dart';

/// 개념 카드의 커밋 그래프 (UI_UX.md §6.1): 점(커밋) · 선 · 브랜치 이름표.
/// 이번 동작으로 달라진 부분만 primary 색으로 칠한다.
class CommitGraph extends StatelessWidget {
  const CommitGraph({super.key, required this.scene});

  final GraphScene scene;

  static const columnWidth = 52.0;
  static const laneHeight = 44.0;
  static const labelRow = 22.0;

  @override
  Widget build(BuildContext context) {
    final columns = scene.commits.map((c) => c.column).fold(0, math.max) + 1;
    final lanes = scene.commits.map((c) => c.lane).fold(0, math.max) + 1;
    // 이름표는 커밋 위에 쌓인다. 같은 커밋의 이름표가 여럿이면 줄을 더한다.
    final stacks = <String, int>{};
    for (final l in scene.labels) {
      stacks[l.commit] = (stacks[l.commit] ?? 0) + 1;
    }
    final maxStack = stacks.values.fold(0, math.max);
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: CustomPaint(
          size: Size(columns * columnWidth + 60, maxStack * labelRow + lanes * laneHeight),
          painter: _GraphPainter(
            scene: scene,
            topPadding: maxStack * labelRow,
            line: theme.colorScheme.outline,
            node: theme.colorScheme.onSurfaceVariant,
            accent: theme.colorScheme.primary,
            text: theme.colorScheme.onSurface,
            surface: theme.colorScheme.surfaceContainerLowest,
          ),
        ),
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  _GraphPainter({
    required this.scene,
    required this.topPadding,
    required this.line,
    required this.node,
    required this.accent,
    required this.text,
    required this.surface,
  });

  final GraphScene scene;
  final double topPadding;
  final Color line;
  final Color node;
  final Color accent;
  final Color text;
  final Color surface;

  Offset _pos(GraphCommit c) => Offset(
        24 + c.column * CommitGraph.columnWidth,
        topPadding + CommitGraph.laneHeight / 2 + c.lane * CommitGraph.laneHeight,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final byId = {for (final c in scene.commits) c.id: c};
    final edgePaint = Paint()
      ..color = line
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final (from, to) in scene.edges) {
      final a = byId[from];
      final b = byId[to];
      if (a == null || b == null) continue;
      final p1 = _pos(a);
      final p2 = _pos(b);
      final paint = Paint()
        ..color = b.highlight ? accent : line
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      if (b.ghost) paint.color = line.withValues(alpha: 0.4);
      if (p1.dy == p2.dy) {
        canvas.drawLine(p1, p2, paint);
      } else {
        final path = Path()
          ..moveTo(p1.dx, p1.dy)
          ..cubicTo(p1.dx + 20, p1.dy, p2.dx - 20, p2.dy, p2.dx, p2.dy);
        canvas.drawPath(path, paint);
      }
    }
    edgePaint.color = line;

    for (final c in scene.commits) {
      final p = _pos(c);
      final color = c.highlight ? accent : node;
      if (c.ghost) {
        canvas.drawCircle(
            p,
            9,
            Paint()
              ..color = node.withValues(alpha: 0.5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
      } else {
        canvas.drawCircle(p, 9, Paint()..color = color);
      }
      _text(canvas, c.id, p, color: c.ghost ? node : surface, size: 9, bold: true, center: true);
    }

    final stacked = <String, int>{};
    for (final l in scene.labels) {
      final c = byId[l.commit];
      if (c == null) continue;
      final level = stacked[l.commit] = (stacked[l.commit] ?? 0) + 1;
      final p = _pos(c);
      final top = p.dy - 12 - level * CommitGraph.labelRow + 2;
      final color = l.highlight ? accent : (l.remote ? node : text);
      final painter = _layout(l.text, color: color, size: 10.5, bold: true);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(p.dx - painter.width / 2 - 6, top, painter.width + 12, 18),
        const Radius.circular(AppRadius.chip),
      );
      canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: 0.14));
      canvas.drawRRect(
          rect,
          Paint()
            ..color = color.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke);
      painter.paint(canvas, Offset(p.dx - painter.width / 2, top + (18 - painter.height) / 2));
    }
  }

  TextPainter _layout(String s, {required Color color, required double size, bool bold = false}) =>
      TextPainter(
        text: TextSpan(
          text: s,
          style: AppFonts.mono.copyWith(color: color, fontSize: size, fontWeight: bold ? FontWeight.w700 : null),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

  void _text(Canvas canvas, String s, Offset at,
      {required Color color, required double size, bool bold = false, bool center = false}) {
    final p = _layout(s, color: color, size: size, bold: bold);
    p.paint(canvas, center ? at - Offset(p.width / 2, p.height / 2) : at);
  }

  @override
  bool shouldRepaint(_GraphPainter old) => old.scene != scene || old.accent != accent || old.text != text;
}
