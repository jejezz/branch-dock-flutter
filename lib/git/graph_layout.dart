/// 기록 탭의 커밋 그래프 (PLAN.md 3.11 P2): 커밋 목록을 "줄(lane)" 배치로 바꾼다.
///
/// 커밋은 위(최신) → 아래(오래됨) 순서로 들어온다 (`git log --topo-order`: 부모는 항상 자식 뒤).
/// 줄마다 "다음에 올 커밋"을 하나 기억해 두고, 그 커밋이 나오면 같은 줄에 점을 찍는다.
library;

import 'history.dart';

/// 한 줄(행)의 위쪽 가장자리나 아래쪽 가장자리의 [lane]과, 점이 있는 높이(행의 가운데)를 잇는 선.
class GraphSegment {
  const GraphSegment(this.from, this.to);

  /// 위쪽 선: 가장자리의 줄. 아래쪽 선: 점의 줄.
  final int from;

  /// 위쪽 선: 점의 줄. 아래쪽 선: 가장자리의 줄.
  final int to;

  @override
  String toString() => '$from→$to';
}

class GraphRow {
  const GraphRow({
    required this.lane,
    required this.top,
    required this.through,
    required this.bottom,
    this.shifts = const [],
  });

  /// 점이 있는 줄.
  final int lane;

  /// 위 가장자리에서 점으로 들어오는 선 (이 커밋을 부모로 기다리던 줄들).
  /// 새 브랜치 끝(아무도 기다리지 않던 커밋)이면 비어 있다.
  final List<GraphSegment> top;

  /// 이 커밋과 상관없이 위에서 아래까지 곧게 지나가는 줄.
  final List<int> through;

  /// 점에서 아래 가장자리로 나가는 선 (부모마다 하나). 첫 커밋이면 비어 있다.
  final List<GraphSegment> bottom;

  /// 점을 거치지 않고 위 가장자리의 줄에서 아래 가장자리의 줄로 옮겨 가는 선 (`from`→`to`, 항상 왼쪽으로).
  /// 이 커밋의 부모를 이미 오른쪽 줄이 기다리고 있을 때, 그 줄을 왼쪽(이 커밋의 줄)으로 끌어온다 —
  /// 줄기가 왼쪽에 머물고 갈라져 나간 브랜치가 줄기로 합쳐지는 모양이 된다.
  final List<GraphSegment> shifts;
}

class CommitGraphLayout {
  const CommitGraphLayout(this.rows, this.laneCount);

  final List<GraphRow> rows;

  /// 가장 많이 쓴 줄 수 (넓이 계산용).
  final int laneCount;

  static CommitGraphLayout of(List<LogEntry> entries) {
    // lanes[i] = i번 줄이 다음에 기다리는 커밋. null이면 빈 줄.
    final lanes = <String?>[];
    final rows = <GraphRow>[];
    var used = 1;

    int firstFree() {
      final i = lanes.indexOf(null);
      if (i >= 0) return i;
      lanes.add(null);
      return lanes.length - 1;
    }

    for (final e in entries) {
      final matched = <int>[
        for (var i = 0; i < lanes.length; i++)
          if (lanes[i] == e.hash) i,
      ];
      final lane = matched.isEmpty ? firstFree() : matched.first;

      final top = [for (final m in matched) GraphSegment(m, lane)];
      final through = <int>[
        for (var i = 0; i < lanes.length; i++)
          if (lanes[i] != null && lanes[i] != e.hash) i,
      ];

      // 이 커밋을 기다리던 줄은 모두 비운다. 점이 있는 줄은 아래에서 부모로 다시 채운다.
      for (final m in matched) {
        lanes[m] = null;
      }
      lanes[lane] = null;

      final bottom = <GraphSegment>[];
      final shifts = <GraphSegment>[];
      for (final (i, parent) in e.parents.indexed) {
        final existing = lanes.indexOf(parent);
        if (existing > lane && i == 0) {
          // 첫 부모를 오른쪽 줄이 이미 기다린다: 그 줄을 이 줄로 끌어와 줄기를 왼쪽에 둔다.
          lanes[lane] = parent;
          lanes[existing] = null;
          shifts.add(GraphSegment(existing, lane));
          through.remove(existing);
          bottom.add(GraphSegment(lane, lane));
        } else if (existing >= 0) {
          bottom.add(GraphSegment(lane, existing)); // 이미 다른 줄이 기다리는 부모: 그 줄로 합쳐진다
        } else if (i == 0) {
          lanes[lane] = parent; // 첫 부모는 같은 줄로 이어진다
          bottom.add(GraphSegment(lane, lane));
        } else {
          final free = firstFree();
          lanes[free] = parent;
          bottom.add(GraphSegment(lane, free));
        }
      }

      rows.add(GraphRow(lane: lane, top: top, through: through, bottom: bottom, shifts: shifts));
      used = [
        used,
        lane + 1,
        for (final s in top) s.from + 1,
        for (final s in bottom) s.to + 1,
        for (final t in through) t + 1,
        for (final s in shifts) s.from + 1,
      ].reduce((a, b) => a > b ? a : b);
    }
    return CommitGraphLayout(rows, used);
  }
}
