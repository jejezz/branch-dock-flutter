import '../../l10n/app_localizations.dart';

/// 개념 도움말 카드 (PLAN.md 3.13). v0.1.0은 동기화와 Pull 방식에 필요한
/// 카드만 담는다. squash 등 병합 카드는 병합 기능과 함께 들어온다.
enum Concept { fetchVsPull, upstream, fastForward, mergeCommit, rebase }

/// 커밋 그래프 한 장면. 커밋은 왼쪽(오래됨) → 오른쪽(최신), 줄(lane)은 위에서 아래.
class GraphScene {
  const GraphScene({required this.caption, required this.commits, required this.edges, this.labels = const []});

  final String caption;
  final List<GraphCommit> commits;

  /// (부모 id, 자식 id)
  final List<(String, String)> edges;
  final List<GraphLabel> labels;
}

class GraphCommit {
  const GraphCommit(this.id, this.column, this.lane, {this.highlight = false, this.ghost = false});

  final String id;
  final int column;
  final int lane;

  /// 이번 동작으로 새로 생긴 커밋.
  final bool highlight;

  /// 아직 내 컴퓨터에 없는 커밋 (원격에만 있음).
  final bool ghost;
}

class GraphLabel {
  const GraphLabel(this.text, this.commit, {this.highlight = false, this.remote = false});

  final String text;
  final String commit;

  /// 이번 동작으로 옮겨진 이름표.
  final bool highlight;
  final bool remote;
}

class ConceptLink {
  const ConceptLink(this.title, this.url);

  final String title;
  final String url;
}

/// 카드 한 장의 내용 (카드 구성: 낱말 뜻 → git에서는 → 왜·언제 → 그림 → 링크).
class ConceptCard {
  const ConceptCard({
    required this.title,
    required this.word,
    required this.inGit,
    required this.why,
    required this.scenes,
    required this.links,
  });

  final String title;
  final String word;
  final String inGit;
  final String why;
  final List<GraphScene> scenes;
  final List<ConceptLink> links;
}

const _a = GraphCommit('A', 0, 0);
const _b = GraphCommit('B', 1, 0);

ConceptCard conceptCard(AppLocalizations l10n, Concept concept) {
  final ko = l10n.localeName == 'ko';
  final book = ko ? 'https://git-scm.com/book/ko/v2' : 'https://git-scm.com/book/en/v2';
  final merging = ConceptLink(
    l10n.helpLinkBranchingBasics,
    ko
        ? '$book/Git-%EB%B8%8C%EB%9E%9C%EC%B9%98-%EB%B8%8C%EB%9E%9C%EC%B9%98%EC%99%80-Merge-%EC%9D%98-%EA%B8%B0%EC%B4%88'
        : '$book/Git-Branching-Basic-Branching-and-Merging',
  );
  final remoteBranches = ConceptLink(
    l10n.helpLinkRemoteBranches,
    ko
        ? '$book/Git-%EB%B8%8C%EB%9E%9C%EC%B9%98-%EB%A6%AC%EB%AA%A8%ED%8A%B8-%EB%B8%8C%EB%9E%9C%EC%B9%98'
        : '$book/Git-Branching-Remote-Branches',
  );
  final rebasing = ConceptLink(
    l10n.helpLinkRebasing,
    ko ? '$book/Git-%EB%B8%8C%EB%9E%9C%EC%B9%98-Rebase-%ED%95%98%EA%B8%B0' : '$book/Git-Branching-Rebasing',
  );
  const gitMerge = ConceptLink('git-merge', 'https://git-scm.com/docs/git-merge');
  const gitPull = ConceptLink('git-pull', 'https://git-scm.com/docs/git-pull');

  // 갈라진 기록: main은 E를, feature는 C·D를 가졌다.
  const diverged = [_a, _b, GraphCommit('E', 2, 0), GraphCommit('C', 2, 1), GraphCommit('D', 3, 1)];
  const divergedEdges = [('A', 'B'), ('B', 'E'), ('B', 'C'), ('C', 'D')];

  return switch (concept) {
    Concept.fetchVsPull => ConceptCard(
        title: l10n.helpFetchVsPullTitle,
        word: l10n.helpFetchVsPullWord,
        inGit: l10n.helpFetchVsPullInGit,
        why: l10n.helpFetchVsPullWhy,
        scenes: [
          GraphScene(
            caption: l10n.helpCaptionBefore,
            commits: const [_a, _b, GraphCommit('C', 2, 0, ghost: true), GraphCommit('D', 3, 0, ghost: true)],
            edges: const [('A', 'B'), ('B', 'C'), ('C', 'D')],
            labels: const [GraphLabel('main', 'B'), GraphLabel('origin/main', 'B', remote: true)],
          ),
          GraphScene(
            caption: l10n.helpCaptionAfterFetch,
            commits: const [_a, _b, GraphCommit('C', 2, 0, highlight: true), GraphCommit('D', 3, 0, highlight: true)],
            edges: const [('A', 'B'), ('B', 'C'), ('C', 'D')],
            labels: const [GraphLabel('main', 'B'), GraphLabel('origin/main', 'D', remote: true, highlight: true)],
          ),
          GraphScene(
            caption: l10n.helpCaptionAfterPull,
            commits: const [_a, _b, GraphCommit('C', 2, 0), GraphCommit('D', 3, 0)],
            edges: const [('A', 'B'), ('B', 'C'), ('C', 'D')],
            labels: const [GraphLabel('main', 'D', highlight: true), GraphLabel('origin/main', 'D', remote: true)],
          ),
        ],
        links: [remoteBranches, gitPull],
      ),
    Concept.upstream => ConceptCard(
        title: l10n.helpUpstreamTitle,
        word: l10n.helpUpstreamWord,
        inGit: l10n.helpUpstreamInGit,
        why: l10n.helpUpstreamWhy,
        scenes: [
          GraphScene(
            caption: l10n.helpCaptionAheadOne,
            commits: const [_a, _b, GraphCommit('C', 2, 0, highlight: true)],
            edges: const [('A', 'B'), ('B', 'C')],
            labels: const [GraphLabel('feature', 'C', highlight: true), GraphLabel('origin/feature', 'B', remote: true)],
          ),
        ],
        links: [remoteBranches],
      ),
    Concept.fastForward => ConceptCard(
        title: l10n.helpFastForwardTitle,
        word: l10n.helpFastForwardWord,
        inGit: l10n.helpFastForwardInGit,
        why: l10n.helpFastForwardWhy,
        scenes: [
          GraphScene(
            caption: l10n.helpCaptionBefore,
            commits: const [_a, _b, GraphCommit('C', 2, 0), GraphCommit('D', 3, 0)],
            edges: const [('A', 'B'), ('B', 'C'), ('C', 'D')],
            labels: const [GraphLabel('main', 'B'), GraphLabel('feature', 'D')],
          ),
          GraphScene(
            caption: l10n.helpCaptionAfter,
            commits: const [_a, _b, GraphCommit('C', 2, 0), GraphCommit('D', 3, 0)],
            edges: const [('A', 'B'), ('B', 'C'), ('C', 'D')],
            labels: const [GraphLabel('main', 'D', highlight: true), GraphLabel('feature', 'D')],
          ),
        ],
        links: [merging, gitMerge],
      ),
    Concept.mergeCommit => ConceptCard(
        title: l10n.helpMergeCommitTitle,
        word: l10n.helpMergeCommitWord,
        inGit: l10n.helpMergeCommitInGit,
        why: l10n.helpMergeCommitWhy,
        scenes: [
          GraphScene(
            caption: l10n.helpCaptionBefore,
            commits: diverged,
            edges: divergedEdges,
            labels: const [GraphLabel('main', 'E'), GraphLabel('feature', 'D')],
          ),
          GraphScene(
            caption: l10n.helpCaptionAfter,
            commits: const [...diverged, GraphCommit('M', 4, 0, highlight: true)],
            edges: const [...divergedEdges, ('E', 'M'), ('D', 'M')],
            labels: const [GraphLabel('main', 'M', highlight: true), GraphLabel('feature', 'D')],
          ),
        ],
        links: [merging, gitMerge],
      ),
    Concept.rebase => ConceptCard(
        title: l10n.helpRebaseTitle,
        word: l10n.helpRebaseWord,
        inGit: l10n.helpRebaseInGit,
        why: l10n.helpRebaseWhy,
        scenes: [
          GraphScene(
            caption: l10n.helpCaptionBefore,
            commits: diverged,
            edges: divergedEdges,
            labels: const [GraphLabel('main', 'E'), GraphLabel('feature', 'D')],
          ),
          GraphScene(
            caption: l10n.helpCaptionAfter,
            commits: const [
              _a,
              _b,
              GraphCommit('E', 2, 0),
              GraphCommit("C'", 3, 0, highlight: true),
              GraphCommit("D'", 4, 0, highlight: true),
            ],
            edges: const [('A', 'B'), ('B', 'E'), ('E', "C'"), ("C'", "D'")],
            labels: const [GraphLabel('main', 'E'), GraphLabel('feature', "D'", highlight: true)],
          ),
        ],
        links: [rebasing],
      ),
  };
}
