/// `gh ... --json` 출력 모델 (PLAN.md 3.8, 3.9).
library;

import 'dart:convert';

Map<String, dynamic>? _obj(String json) {
  try {
    final v = jsonDecode(json);
    return v is Map<String, dynamic> ? v : null;
  } on FormatException {
    return null;
  }
}

List<dynamic> _list(String json) {
  try {
    final v = jsonDecode(json);
    return v is List ? v : const [];
  } on FormatException {
    return const [];
  }
}

DateTime? _date(Object? v) => v is String && v.isNotEmpty && !v.startsWith('0001') ? DateTime.tryParse(v) : null;

/// 검사(checks) 결과 요약.
class CheckSummary {
  const CheckSummary({this.passed = 0, this.failed = 0, this.pending = 0, this.failedNames = const []});

  final int passed;
  final int failed;
  final int pending;
  final List<String> failedNames;

  int get total => passed + failed + pending;

  /// statusCheckRollup: CheckRun(status, conclusion) 또는 StatusContext(state).
  static CheckSummary parse(List<dynamic> rollup) {
    var passed = 0, failed = 0, pending = 0;
    final names = <String>[];
    for (final item in rollup.whereType<Map<String, dynamic>>()) {
      final state = ((item['conclusion'] ?? item['state'] ?? '') as String).toUpperCase();
      final status = ((item['status'] ?? '') as String).toUpperCase();
      final name = (item['name'] ?? item['context'] ?? '') as String;
      if (status.isNotEmpty && status != 'COMPLETED') {
        pending++;
      } else if (const {'SUCCESS', 'NEUTRAL', 'SKIPPED'}.contains(state)) {
        passed++;
      } else if (const {'PENDING', 'EXPECTED', ''}.contains(state)) {
        pending++;
      } else {
        failed++;
        names.add(name);
      }
    }
    return CheckSummary(passed: passed, failed: failed, pending: pending, failedNames: names);
  }
}

enum PrState { open, merged, closed }

class PullRequest {
  const PullRequest({
    required this.number,
    required this.title,
    required this.url,
    required this.state,
    required this.headRef,
    required this.baseRef,
    this.draft = false,
    this.mergeable = 'UNKNOWN',
    this.mergeStateStatus = 'UNKNOWN',
    this.reviewDecision = '',
    this.checks = const CheckSummary(),
    this.mergeCommit,
    this.author = '',
    this.updated,
  });

  static const jsonFields =
      'number,title,url,state,isDraft,mergeable,mergeStateStatus,reviewDecision,statusCheckRollup,headRefName,baseRefName,mergeCommit';

  /// 목록용 (mergeable은 목록에서 계산 비용이 커서 뺀다).
  static const listFields =
      'number,title,url,state,isDraft,reviewDecision,statusCheckRollup,headRefName,baseRefName,author,updatedAt';

  final int number;
  final String title;
  final String url;
  final PrState state;
  final String headRef;
  final String baseRef;
  final bool draft;

  /// MERGEABLE / CONFLICTING / UNKNOWN
  final String mergeable;

  /// CLEAN / BLOCKED / BEHIND / DIRTY / UNSTABLE / HAS_HOOKS / UNKNOWN
  final String mergeStateStatus;

  /// APPROVED / CHANGES_REQUESTED / REVIEW_REQUIRED / ''
  final String reviewDecision;
  final CheckSummary checks;
  final String? mergeCommit;
  final String author;
  final DateTime? updated;

  bool get open => state == PrState.open;
  bool get merged => state == PrState.merged;
  bool get conflicting => mergeable == 'CONFLICTING' || mergeStateStatus == 'DIRTY';
  bool get reviewRequired => reviewDecision == 'REVIEW_REQUIRED' || reviewDecision == 'CHANGES_REQUESTED';

  /// 병합 버튼을 켤 수 있는가. BLOCKED(보호 규칙)여도 관리자는 병합할 수 있지만
  /// 그 판단은 gh에 맡기고, 알려진 막힘만 미리 보여 준다.
  bool get canMerge => open && !draft && !conflicting && checks.failed == 0 && checks.pending == 0;

  static PullRequest? parse(String json) {
    final m = _obj(json);
    return m == null ? null : fromJson(m);
  }

  static List<PullRequest> parseList(String json) =>
      _list(json).whereType<Map<String, dynamic>>().map(fromJson).toList();

  static PullRequest fromJson(Map<String, dynamic> m) => PullRequest(
        number: (m['number'] ?? 0) as int,
        title: (m['title'] ?? '') as String,
        url: (m['url'] ?? '') as String,
        state: switch ((m['state'] ?? '') as String) {
          'MERGED' => PrState.merged,
          'CLOSED' => PrState.closed,
          _ => PrState.open,
        },
        headRef: (m['headRefName'] ?? '') as String,
        baseRef: (m['baseRefName'] ?? '') as String,
        draft: (m['isDraft'] ?? false) as bool,
        mergeable: (m['mergeable'] ?? 'UNKNOWN') as String,
        mergeStateStatus: (m['mergeStateStatus'] ?? 'UNKNOWN') as String,
        reviewDecision: (m['reviewDecision'] ?? '') as String,
        checks: CheckSummary.parse((m['statusCheckRollup'] ?? const []) as List<dynamic>),
        mergeCommit: (m['mergeCommit'] as Map<String, dynamic>?)?['oid'] as String?,
        author: ((m['author'] as Map<String, dynamic>?)?['login'] ?? '') as String,
        updated: _date(m['updatedAt']),
      );
}

enum RunState { queued, running, success, failure, cancelled, skipped }

RunState _runState(String status, String conclusion) {
  if (status != 'completed') return status == 'queued' || status == 'waiting' || status == 'pending' ? RunState.queued : RunState.running;
  return switch (conclusion) {
    'success' => RunState.success,
    'cancelled' => RunState.cancelled,
    'skipped' || 'neutral' => RunState.skipped,
    _ => RunState.failure,
  };
}

class RunJob {
  const RunJob({required this.name, required this.state, this.started, this.completed, this.failedStep});

  final String name;
  final RunState state;
  final DateTime? started;
  final DateTime? completed;
  final String? failedStep;

  Duration? get duration => started == null ? null : (completed ?? DateTime.now()).difference(started!);
}

class WorkflowRun {
  const WorkflowRun({
    required this.id,
    required this.name,
    required this.state,
    required this.url,
    this.event = '',
    this.headBranch = '',
    this.created,
    this.jobs = const [],
    this.title = '',
  });

  static const listFields = 'databaseId,workflowName,status,conclusion,url,event,headBranch,createdAt,displayTitle';
  static const viewFields = 'databaseId,workflowName,status,conclusion,url,event,headBranch,createdAt,jobs,displayTitle';

  final int id;
  final String name;
  final RunState state;
  final String url;
  final String event;
  final String headBranch;
  final DateTime? created;
  final List<RunJob> jobs;

  /// 커밋 제목 등 실행을 알아볼 수 있는 한 줄.
  final String title;

  bool get done => state != RunState.queued && state != RunState.running;

  static List<WorkflowRun> parseList(String json) =>
      _list(json).whereType<Map<String, dynamic>>().map(fromJson).toList();

  static WorkflowRun? parse(String json) {
    final m = _obj(json);
    return m == null ? null : fromJson(m);
  }

  static WorkflowRun fromJson(Map<String, dynamic> m) => WorkflowRun(
        id: (m['databaseId'] ?? 0) as int,
        name: (m['workflowName'] ?? '') as String,
        state: _runState((m['status'] ?? '') as String, (m['conclusion'] ?? '') as String),
        url: (m['url'] ?? '') as String,
        event: (m['event'] ?? '') as String,
        headBranch: (m['headBranch'] ?? '') as String,
        created: _date(m['createdAt']),
        title: (m['displayTitle'] ?? '') as String,
        jobs: [
          for (final j in ((m['jobs'] ?? const []) as List<dynamic>).whereType<Map<String, dynamic>>())
            RunJob(
              name: (j['name'] ?? '') as String,
              state: _runState((j['status'] ?? '') as String, (j['conclusion'] ?? '') as String),
              started: _date(j['startedAt']),
              completed: _date(j['completedAt']),
              failedStep: [
                for (final s in ((j['steps'] ?? const []) as List<dynamic>).whereType<Map<String, dynamic>>())
                  if (s['conclusion'] == 'failure') s['name'] as String,
              ].firstOrNull,
            ),
        ],
      );
}

class ReleaseAsset {
  const ReleaseAsset(this.name, this.size);

  final String name;
  final int size;
}

class GitHubRelease {
  const GitHubRelease({
    required this.tag,
    required this.name,
    required this.url,
    this.prerelease = false,
    this.draft = false,
    this.body = '',
    this.assets = const [],
  });

  static const fields = 'tagName,name,url,isPrerelease,isDraft,body,assets';

  final String tag;
  final String name;
  final String url;
  final bool prerelease;
  final bool draft;
  final String body;
  final List<ReleaseAsset> assets;

  static GitHubRelease? parse(String json) {
    final m = _obj(json);
    if (m == null) return null;
    return GitHubRelease(
      tag: (m['tagName'] ?? '') as String,
      name: (m['name'] ?? '') as String,
      url: (m['url'] ?? '') as String,
      prerelease: (m['isPrerelease'] ?? false) as bool,
      draft: (m['isDraft'] ?? false) as bool,
      body: (m['body'] ?? '') as String,
      assets: [
        for (final a in ((m['assets'] ?? const []) as List<dynamic>).whereType<Map<String, dynamic>>())
          ReleaseAsset((a['name'] ?? '') as String, (a['size'] ?? 0) as int),
      ],
    );
  }
}


/// `gh release list --json` 한 줄 (PLAN.md 3.8.6).
class ReleaseSummary {
  const ReleaseSummary({
    required this.tag,
    required this.name,
    this.latest = false,
    this.prerelease = false,
    this.draft = false,
    this.published,
  });

  static const fields = 'tagName,name,isLatest,isPrerelease,isDraft,publishedAt';

  final String tag;
  final String name;
  final bool latest;
  final bool prerelease;
  final bool draft;
  final DateTime? published;

  static List<ReleaseSummary> parseList(String json) => [
        for (final m in _list(json).whereType<Map<String, dynamic>>())
          ReleaseSummary(
            tag: (m['tagName'] ?? '') as String,
            name: (m['name'] ?? '') as String,
            latest: (m['isLatest'] ?? false) as bool,
            prerelease: (m['isPrerelease'] ?? false) as bool,
            draft: (m['isDraft'] ?? false) as bool,
            published: _date(m['publishedAt']),
          ),
      ];
}

/// `gh workflow list --json` 한 줄 (PLAN.md 3.10).
class Workflow {
  const Workflow({required this.id, required this.name, required this.path, this.active = true});

  static const fields = 'id,name,path,state';

  final int id;
  final String name;

  /// `.github/workflows/release.yml`
  final String path;
  final bool active;

  String get file => path.split('/').last;

  static List<Workflow> parseList(String json) => [
        for (final m in _list(json).whereType<Map<String, dynamic>>())
          Workflow(
            id: (m['id'] ?? 0) as int,
            name: (m['name'] ?? '') as String,
            path: (m['path'] ?? '') as String,
            active: m['state'] == 'active',
          ),
      ];
}
