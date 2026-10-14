import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../git/graph_layout.dart';
import 'widgets.dart';

/// 기록 탭 줄 왼쪽의 그래프 열 (PLAN.md 3.11 P2). 점 = 커밋, 선 = 부모와의 이음.
///
/// 줄 높이가 제각각이어도 이어지도록, 열은 줄 높이만큼 늘어나고 선은 가장자리까지 그린다.
/// 좁은 창에서는 줄 수를 [maxLanes]로 제한한다 (넘는 줄은 맨 오른쪽 줄에 겹쳐 그린다).
class CommitGraphGutter extends StatelessWidget {
  const CommitGraphGutter({
    super.key,
    required this.row,
    required this.lanes,
    required this.isHead,
    required this.isMerge,
    this.nodeY = 14,
  });

  static const laneWidth = 14.0;
  static const maxLanes = 6;

  /// 전체 줄 수([CommitGraphLayout.laneCount])에서 실제로 그릴 줄 수.
  static int visibleLanes(int laneCount) => math.min(math.max(laneCount, 1), maxLanes);

  final GraphRow row;
  final int lanes;
  final bool isHead;
  final bool isMerge;

  /// 점의 높이 (줄 위쪽부터). 첫 줄 글자의 가운데쯤.
  final double nodeY;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = [
      toneColor(context, Tone.primary),
      toneColor(context, Tone.success),
      toneColor(context, Tone.warning),
      toneColor(context, Tone.danger),
      const Color(0xFFB07CFF),
      const Color(0xFF3CC8C8),
    ];
    return SizedBox(
      width: lanes * laneWidth,
      child: CustomPaint(
        painter: _GutterPainter(
          row: row,
          lanes: lanes,
          isHead: isHead,
          isMerge: isMerge,
          nodeY: nodeY,
          palette: palette,
          surface: theme.colorScheme.surface,
          headRing: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _GutterPainter extends CustomPainter {
  _GutterPainter({
    required this.row,
    required this.lanes,
    required this.isHead,
    required this.isMerge,
    required this.nodeY,
    required this.palette,
    required this.surface,
    required this.headRing,
  });

  final GraphRow row;
  final int lanes;
  final bool isHead;
  final bool isMerge;
  final double nodeY;
  final List<Color> palette;
  final Color surface;
  final Color headRing;

  double _x(int lane) => (math.min(lane, lanes - 1) + 0.5) * CommitGraphGutter.laneWidth;
  Color _color(int lane) => palette[lane % palette.length];

  Paint _line(int lane) => Paint()
    ..color = _color(lane)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round;

  /// 두 줄 사이를 잇는다. 같은 줄이면 곧은 선, 다르면 부드러운 곡선.
  void _connect(Canvas canvas, int colorLane, double x1, double y1, double x2, double y2) {
    final paint = _line(colorLane);
    if ((x1 - x2).abs() < 0.5) {
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      return;
    }
    final mid = (y1 + y2) / 2;
    final path = Path()
      ..moveTo(x1, y1)
      ..cubicTo(x1, mid, x2, mid, x2, y2);
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final lane in row.through) {
      canvas.drawLine(Offset(_x(lane), 0), Offset(_x(lane), size.height), _line(lane));
    }
    // 줄을 왼쪽으로 끌어오는 선: 위 가장자리에서 아래 가장자리까지 한 번에 휜다.
    for (final s in row.shifts) {
      _connect(canvas, s.from, _x(s.from), 0, _x(s.to), size.height);
    }
    final node = _x(row.lane);
    // 위에서 점으로 들어오는 선: 색은 들어오는 줄의 것 (갈라져 나온 브랜치 색을 따른다).
    for (final s in row.top) {
      _connect(canvas, s.from, _x(s.from), 0, node, nodeY);
    }
    // 점에서 아래로 나가는 선: 같은 줄이면 이 줄 색, 다른 줄로 가면 그 줄의 색.
    for (final s in row.bottom) {
      _connect(canvas, s.to, node, nodeY, _x(s.to), size.height);
    }
    final color = _color(row.lane);
    final center = Offset(node, nodeY);
    if (isHead) {
      canvas.drawCircle(center, 7, Paint()..color = headRing..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
    if (isMerge) {
      // 병합 커밋은 속이 빈 점
      canvas.drawCircle(center, 4.5, Paint()..color = surface);
      canvas.drawCircle(center, 4.5, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2);
    } else {
      canvas.drawCircle(center, 4.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_GutterPainter old) =>
      old.row != row || old.lanes != lanes || old.isHead != isHead || old.isMerge != isMerge || old.nodeY != nodeY;
}
