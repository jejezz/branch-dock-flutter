# GitHub CLI — 기능 계획서 (v0.1 초안)

화면 구성은 [UI_UX.md](UI_UX.md), 공통 규약은
[conventions](https://github.com/jejezz/application-release-templates/tree/main/conventions)를 따른다.

## 1. 개요

로컬 git 저장소를 열어서 **git과 GitHub CLI(`gh`)로 하는 일을 버튼과 양식으로**
할 수 있게 하는 데스크톱 앱이다.

- **대상 사용자**: git은 조금 써 봤지만 `gh` 명령이 익숙하지 않은 사람,
  GitHub 웹의 메뉴가 너무 많아 헷갈리는 사람.
- **범위**: 모든 기능이 아니라 **중급 수준**까지. 매일 쓰는 흐름을 확실하게
  한다.
- **중점 기능**: branch, tag, merge, pull, push, remote, 그리고 **릴리스
  흐름**(버전 올리기 → 태그 생성 → 태그 push → 릴리스 노트).
- **GitHub 전용**: `gh`는 GitHub 전용 도구이므로 이 앱은 **GitHub 저장소에
  가장 알맞게** 만든다. GitLab, Bitbucket 같은 다른 호스팅의 저장소도 열 수는
  있지만, `gh`가 필요한 동작(PR, 릴리스, Actions, 로그인, 저장소 생성)은 쓸 수
  없다 (§2.1).
- **사용 방식**: 편집기(VS Code, Xcode, Android Studio 등) 옆에 세로로 길게
  띄워 두고 함께 쓴다 ([UI_UX.md](UI_UX.md) §1).

### 핵심 원칙

1. **명령이 보인다** — 모든 동작은 실행 전에 실제 `git` / `gh` 명령을 보여
   주고, 실행 후 기록(명령 로그)에 남긴다. 앱을 쓰다 보면 명령을 배우게 된다.
2. **다음 할 일을 알려 준다** — 저장소 상태를 보고 "Push할 커밋 2개",
   "원격에 새 커밋 3개", "이 브랜치는 아직 원격에 없음" 같은 추천 행동을
   먼저 보여 준다.
3. **되돌리기 어려운 일은 한 번 더 묻는다** — 강제 push, 원격 브랜치·태그
   삭제, 변경 취소는 확인을 받는다 (conventions `ui-ux.md` §6).
4. **편집기와 싸우지 않는다** — 편집기에서 저장하면 앱이 알아서 새로 고친다.
   충돌 해결 같은 편집은 편집기로 넘긴다.

### 우선순위

- **P0**: 첫 정식 릴리스(v0.1.0)에 반드시 포함
- **P1**: 바로 다음 릴리스
- **P2**: 여유가 있을 때

## 2. git과 gh의 역할 나누기

branch, tag, merge, pull, push, remote는 **로컬 git 작업**이라 `gh`가 아니라
`git`으로 실행한다. `gh`는 GitHub 쪽 작업(인증, 저장소, PR, 릴리스, Actions)을
맡는다. 사용자에게는 둘을 구분하지 않고 하나의 흐름으로 보여 준다.

| 영역 | 도구 | 예 |
|---|---|---|
| 변경·커밋·브랜치·태그·병합·동기화·원격 | `git` | `git switch`, `git tag -a`, `git push --follow-tags` |
| 인증, 저장소 생성/연결 | `gh` | `gh auth status`, `gh repo create --source .` |
| PR, 릴리스, Actions | `gh` | `gh pr create`, `gh release create`, `gh run watch` |

출력은 사람이 읽는 형식이 아니라 **기계용 형식**만 파싱한다:
`git status --porcelain=v2 --branch`, `git for-each-ref --format`,
`gh ... --json <fields>`.

### 2.1 GitHub가 아닌 원격 (GitLab 등)

`gh`는 GitHub의 API만 다룬다. GitLab, Bitbucket, Gitea, 사내 git 서버의
저장소에서는 `gh` 명령이 동작하지 않으므로, 이 앱은 그런 저장소에서 **git으로
하는 동작만 제공하고 `gh`가 필요한 동작은 막는다.** GitLab의 MR, 릴리스, CI는
GitLab 웹이나 GitLab 전용 도구(`glab`)를 써야 한다. 이 앱은 `glab` 등 다른
호스팅 도구를 지원하지 않는다.

- **판별**: 원격 URL의 호스트로 판단한다 (`https://`, `git@host:`, `ssh://`
  형식 모두). `github.com`이면 GitHub, 그 밖은 "GitHub 아님"으로 본다.
  GitHub Enterprise Server는 `gh auth status`에 로그인된 호스트일 때만
  GitHub로 보며, 시험하지 않은 환경으로 표시한다 (P2).
- **원격이 여러 개일 때**: `gh`가 필요한 동작은 GitHub 원격을 대상으로 한다.
  예: `origin`은 GitLab, `github`은 GitHub이면 PR·릴리스는 `github` 원격으로
  한다 (`gh repo set-default`). GitHub 원격이 하나도 없으면 막는다.

| 동작 | GitHub 원격 | GitHub가 아닌 원격 (GitLab 등) |
|---|---|---|
| 변경·커밋, 브랜치, 병합, stash, 기록 | ✓ | ✓ |
| Fetch / Pull / Push, 게시(Publish) | ✓ | ✓ (인증은 사용자의 git 설정에 맡김) |
| 원격 추가·삭제·URL 변경 | ✓ | ✓ |
| 태그 만들기·push·삭제 | ✓ | ✓ |
| 릴리스 마법사 ① 점검 ~ ④ Push | ✓ | ✓ |
| 릴리스 마법사 ⑤ 릴리스 노트, ⑥ CI 확인, 릴리스 관리 | ✓ | ✕ |
| Pull Request, Actions | ✓ | ✕ |
| `gh` 로그인, GitHub에 올리기(`gh repo create`), 복제(`gh repo clone`) | ✓ | ✕ |

- 막힌 동작은 숨기지 않고 비활성으로 두고, "이 저장소의 원격은 GitLab입니다.
  PR·릴리스·Actions는 GitHub 저장소에서만 쓸 수 있습니다" 같은 이유를
  보여 준다 ([UI_UX.md](UI_UX.md) §3 D).
- `gh auth setup-git`은 GitHub에만 git 인증을 설정한다. GitHub가 아닌
  원격에서 push가 인증 실패하면 해당 호스팅의 인증 방법을 확인하라고
  안내한다 (앱이 대신 설정하지 않는다).

## 3. 기능 목록

### 3.1 시작과 저장소 열기

- `P0` 폴더 열기(⌘O), 창에 폴더 끌어다 놓기. 하위 폴더를 열어도 저장소
  루트(`git rev-parse --show-toplevel`)를 찾는다.
- `P0` 최근 저장소 목록 (최대 10개, 빈 상태 화면과 저장소 전환 메뉴에 표시).
- `P0` 환경 점검: `git`, `gh` 설치 여부와 버전, `gh auth status`.
  없거나 로그인이 안 됐으면 설치/로그인 방법을 안내하는 화면을 보여 준다.
- `P1` `gh auth login --web` 실행: 일회용 코드를 앱에 보여 주고 브라우저를
  연다. `gh auth setup-git`으로 git push 인증도 함께 설정한다.
- `P1` **SSH로 원격 작업할 때는 `gh auth login`을 SSH 방식으로 하도록 권장**한다.
  저장소의 원격 URL이 SSH 형식(`git@github.com:…`, `ssh://`)이거나 SSH
  세션(`SSH_CONNECTION`)에서 실행 중이면 로그인 화면에서 SSH를 기본으로 고르고
  아래 요령을 단계별로 보여 준다. HTTPS로 로그인하면 git 인증이 SSH 키와
  따로 놀아 push할 때 비밀번호/토큰을 묻거나 실패하기 때문이다.
  1. 키 확인: `~/.ssh/id_ed25519.pub`가 있는지 본다. 없으면
     `ssh-keygen -t ed25519 -C "<GitHub 이메일>"`로 만든다 (암호 문구 권장).
  2. 로그인: `gh auth login --hostname github.com --git-protocol ssh --web`.
     진행 중 공개 키 업로드를 물으면 1의 키를 고른다
     (이미 등록했다면 건너뜀, 나중에 `gh ssh-key add ~/.ssh/id_ed25519.pub`).
  3. 브라우저가 없는 원격 서버: 화면에 나온 일회용 코드를 다른 기기의
     브라우저에서 https://github.com/login/device 에 입력한다.
  4. 확인: `ssh -T git@github.com` ("successfully authenticated")와
     `gh auth status`의 `Git operations protocol: ssh`.
  5. 기존 HTTPS 로그인은 `gh config set git_protocol ssh`로 바꾸고, HTTPS
     원격은 SSH URL로 바꾸도록 제안한다 (3.6 HTTPS ↔ SSH 전환과 연결).
  - 키 암호 문구를 매번 묻지 않도록 macOS는 `ssh-add --apple-use-keychain`,
    그 밖에는 `ssh-agent` 사용을 안내한다. 앱은 키나 암호 문구를 입력받지
    않고, 명령을 복사해 터미널에서 실행하게 한다.
- `P1` 저장소가 아닌 폴더: "git 저장소로 만들기"(`git init -b main`) 제안.
- `P1` GitHub에서 복제: `gh repo clone <owner/repo> <폴더>` (내 저장소 목록에서 고르기).

### 3.2 변경 사항과 커밋

push할 커밋을 만들 수 있어야 나머지 흐름이 이어지므로 최소한으로 포함한다.

- `P0` 변경된 파일 목록: 스테이징됨 / 안 됨 / 추적 안 됨 / 충돌로 나눠 표시.
- `P0` 파일별·전체 스테이징과 해제.
- `P0` 커밋 메시지 입력과 커밋(⌘Enter). Conventional Commit 접두어
  (`feat:`, `fix:`, `chore:` …) 빠른 선택.
- `P0` 파일을 편집기로 열기 (OS 기본 앱, 또는 설정한 편집기 명령 `code` 등).
- `P1` 직전 커밋 고치기(`--amend`) — 이미 push한 커밋이면 경고.
- `P1` 변경 취소(`git restore`) — 확인 필요.
- `P1` Stash: 임시 저장 / 목록 / 다시 적용 / 삭제. 브랜치 전환이나 pull이
  변경 때문에 막히면 "임시 저장하고 계속"을 제안한다.
- `P2` 간단한 diff 보기 (읽기 전용, 한 파일).

### 3.3 동기화: fetch / pull / push (중점)

- `P0` 상단 고정 영역에 현재 브랜치, 추적 브랜치, **↑ahead / ↓behind** 표시.
- `P0` Fetch (`git fetch --prune`), Pull, Push 버튼.
- `P0` Pull 방식 선택: 병합(기본) / rebase / fast-forward만. 저장소별로 기억한다.
- `P0` 원격에 없는 브랜치를 push하면 **게시(Publish)**로 바꿔 보여 주고
  `git push -u <remote> <branch>`를 실행한다.
- `P0` push가 거부되면(원격이 앞서 있음) 이유를 풀어서 설명하고 "먼저 Pull"을
  제안한다.
- `P1` 강제 push는 `--force-with-lease`만 제공, 기본 브랜치에서는 막는다.
- `P1` 자동 fetch (기본 5분, 끌 수 있음). 창이 다시 활성화될 때도 fetch.
- `P1` 태그 함께 push (`--follow-tags`) 옵션.

### 3.4 브랜치 (중점)

- `P0` 로컬 / 원격 브랜치 목록. 현재 브랜치, 추적 브랜치, ahead/behind,
  마지막 커밋 시간 표시. 검색 필터.
- `P0` 새 브랜치 만들기(⌘B): 기준(현재 / 다른 브랜치 / 태그 / 커밋) 고르고,
  만든 뒤 바로 전환할지 선택. 이름 규칙 검사(`git check-ref-format`)와
  `feature/`, `fix/` 접두어 제안.
- `P0` 브랜치 전환 (`git switch`). 원격 브랜치를 고르면 추적 브랜치를
  만들어 전환한다.
- `P0` 이름 바꾸기, 로컬 삭제 (병합 안 된 브랜치는 경고 후 `-D`).
- `P0` 원격 브랜치 삭제 (`git push <remote> --delete`) — 확인 필요.
- `P1` 추적 브랜치 설정/변경 (`git branch -u`).
- `P1` 병합이 끝난 브랜치 정리: 병합된 로컬 브랜치와 원격에서 사라진
  브랜치(`[gone]`)를 모아 한 번에 삭제.

### 3.5 병합 (중점)

- `P0` 다른 브랜치를 현재 브랜치로 병합: fast-forward / 병합 커밋(`--no-ff`) /
  squash 중 선택. 실행 전에 "들어올 커밋 N개" 미리 보기.
- `P0` 충돌이 나면: 충돌 파일 목록, 파일별 "편집기로 열기", "해결됨 표시"
  (`git add`), 병합 계속(`git commit`) / 병합 중단(`git merge --abort`).
  상단에 "병합 중" 상태를 계속 표시한다.
- `P1` 충돌 파일에 "내 것 사용 / 들어오는 것 사용"
  (`git checkout --ours/--theirs`).
- `P1` rebase 중 상태도 같은 방식으로 표시 (계속 / 건너뛰기 / 중단).
  대화형 rebase는 범위 밖.
- `P1` GitHub에서 병합하기: 3.9 PR 병합으로 연결.

### 3.6 원격 (중점)

- `P0` 원격 목록 (이름, fetch/push URL, GitHub 저장소면 `owner/repo`와 링크).
- `P0` 원격 추가 / 이름 바꾸기 / 삭제(확인) / URL 바꾸기.
- `P0` 원격별 fetch.
- `P0` **GitHub에 올리기**: 원격이 없는 저장소는 `gh repo create <이름>
  --source . --remote origin --push` (공개/비공개, 설명 입력).
- `P1` HTTPS ↔ SSH URL 전환.
- `P1` fork 저장소면 `upstream` 추가를 제안하고, "upstream에서 가져오기" 제공.
- `P1` `gh repo set-default` (원격이 여러 개일 때 gh가 쓸 저장소 지정).
- `P1` 브라우저에서 저장소 열기 (`gh browse`).

### 3.7 태그 (중점)

- `P0` 태그 목록: 이름, 대상 커밋, 날짜, 주석(annotated) 여부,
  **원격에 올라갔는지** 표시 (`git ls-remote --tags`와 비교).
- `P0` 태그 만들기(⌘T): 주석 태그(기본) / 가벼운 태그, 대상(HEAD / 커밋 /
  브랜치), 메시지. `v` 접두어와 SemVer 형식 검사, 이미 있는 이름이면 막음.
- `P0` 태그 push (하나 / 원격에 없는 것 전부).
- `P0` 태그 삭제: 로컬 / 원격(확인 필요, 이미 릴리스가 있으면 경고).
- `P1` 태그 위치로 체크아웃 (detached HEAD 경고, "여기서 브랜치 만들기" 제안).
- `P1` 태그 사이 커밋 보기 (릴리스 노트 초안에 사용).

### 3.8 릴리스 (중점)

"버전 올리기 → 커밋 → 태그 → push → 릴리스 노트 → CI 확인"을 한 흐름으로
안내하는 **릴리스 마법사**가 이 앱의 핵심 기능이다.

#### 3.8.1 사전 점검 (P0)

- 작업 트리가 깨끗한가, 기본 브랜치에 있는가, 원격과 동기화됐는가
  (ahead 0 / behind 0).
- 마지막 릴리스 태그와 그 이후 커밋 수.
- 실패한 항목마다 해결 버튼을 붙인다 (커밋하기, Pull, 브랜치 전환).
  "무시하고 계속"은 이유를 보여 준 뒤에만 허용한다.

#### 3.8.2 버전 올리기 (P0)

- 버전 파일 자동 감지: `pubspec.yaml`, `package.json`, `Cargo.toml`,
  `pyproject.toml`. 여러 개면 함께 올린다. 감지되지 않으면 "태그만"으로 진행.
- 다음 버전 제안: 마지막 태그 이후 커밋의 Conventional Commit 종류로 계산
  (`feat!`/`BREAKING CHANGE` → major, `feat` → minor, 나머지 → patch;
  `0.y.z`에서는 conventions `versioning.md` §2 해석을 따름).
- 선택지: patch / minor / major / 프리릴리스(`-rc.N`) / 직접 입력.
- Flutter 앱은 build number를 **+1** (`versioning.md` §3). 되돌리지 않음.
- 변경 내용을 diff로 보여 준 뒤 커밋: `chore(release): vX.Y.Z`.
- `P1` 저장소에 `scripts/bump-version.sh`가 있으면 그것을 실행한다
  (conventions 규약 앱과 동작을 맞춤).

#### 3.8.3 태그 만들기와 push (P0)

- 주석 태그 `vX.Y.Z` (메시지 기본값 = 태그 이름). pubspec 버전과 태그가
  다르면 막는다.
- 커밋과 태그를 함께 push: `git push <remote> <branch> && git push <remote> vX.Y.Z`.
- `P1` **PR 경유 방식**: 기본 브랜치가 보호돼 있거나 사용자가 고르면,
  릴리스 브랜치 → PR 생성 → (병합 후) 병합 커밋에 태그. conventions
  `versioning.md` §5 절차와 같다.

#### 3.8.4 릴리스 노트 (P0)

- 두 가지 모드를 자동으로 구분한다.
  - **CI가 릴리스를 만드는 저장소**: `.github/workflows/*`에 태그 push
    트리거(`on: push: tags`)가 있으면, 앱은 릴리스를 만들지 않고 CI가
    만든 릴리스의 노트를 **고친다** (`gh release edit --notes-file`).
  - **앱이 릴리스를 만드는 저장소**: `gh release create vX.Y.Z --title
    --notes-file [--prerelease] [--draft]`.
- 노트 초안: 마지막 태그 이후 커밋을 종류별로 묶은 목록
  (새 기능 / 버그 수정 / 기타), 또는 GitHub 자동 생성
  (`--generate-notes`). 둘 중 선택 후 편집.
- 편집기: 마크다운 입력 + 미리 보기 전환. `.github/release-notes-header.md`가
  있으면 머리말로 붙인다.
- 프리릴리스 태그(`-rc`, `-beta`)면 자동으로 프리릴리스 표시.

#### 3.8.5 CI 확인 (P0)

- 태그 push 뒤 해당 태그로 시작된 워크플로 실행을 찾아
  (`gh run list --branch vX.Y.Z --json`) 잡별 상태를 보여 준다.
- 실패하면 실패한 단계 이름과 로그 끝부분 (`gh run view --log-failed`),
  "실패한 잡 다시 실행" (`gh run rerun --failed`), 브라우저에서 열기.
- 완료되면 릴리스 링크와 산출물 목록을 보여 준다.

#### 3.8.6 릴리스 관리 (P1)

- 릴리스 목록 (`gh release list`): 최신/프리릴리스/초안 표시.
- 노트 수정, 프리릴리스 ↔ 정식 전환, 초안 게시, 삭제(확인, 태그는 남길지 선택).
- `P2` 산출물 업로드 / 다운로드.

#### 3.8.7 되돌리기 (P1)

- 잘못 단 태그: 원격 태그 삭제 + 로컬 태그 삭제 + (있으면) 릴리스 삭제를 한 번에.
  이미 다운로드됐을 수 있으므로 "같은 태그 다시 쓰기 대신 다음 번호"를 권한다.

### 3.9 Pull Request (GitHub)

- `P0` 현재 브랜치로 PR 만들기: 기준 브랜치, 제목(마지막 커밋 제목 기본값),
  본문, 초안 여부. push가 안 됐으면 먼저 게시한다.
- `P0` 현재 브랜치의 PR 상태: 검사(checks) 결과, 리뷰 상태, 병합 가능 여부.
- `P1` PR 목록 (내가 만든 것 / 리뷰 요청받은 것 / 전체 열림).
- `P1` PR 병합: merge / squash / rebase, 병합 후 브랜치 삭제, 로컬 기본
  브랜치로 돌아가 Pull.
- `P1` PR 체크아웃 (`gh pr checkout`).
- `P2` 리뷰 승인 / 코멘트.

### 3.10 Actions (GitHub)

- `P1` 현재 브랜치의 최근 워크플로 실행과 상태.
- `P1` 다시 실행, 취소, 브라우저에서 열기.
- `P2` 수동 실행 (`gh workflow run`, `workflow_dispatch` 입력 양식).

### 3.11 기록(log)

- `P1` 현재 브랜치의 커밋 목록 (한 줄 요약, 태그·브랜치 표시, ahead 커밋 강조).
  태그·브랜치를 만들 때 대상 커밋 고르기에 쓴다.
- `P2` 커밋 되돌리기(`git revert`), cherry-pick.

### 3.12 명령 로그와 도움말

- `P0` 모든 실행 명령과 결과(종료 코드, 출력)를 시간순으로 남긴다. 복사 가능.
- `P0` 오류는 원문과 함께 쉬운 설명을 보여 준다 (자주 나오는 오류:
  non-fast-forward, 인증 실패, 충돌, 보호된 브랜치, 이미 있는 태그).
- `P0` 용어 도움말: 각 동작 옆 `?`에 git 용어를 한두 문장으로. 자세한 개념은 3.13.
- `P2` 명령 팔레트(⌘K).

### 3.13 개념 도움말 (P0)

fast-forward, squash처럼 **낱말의 사전 뜻만으로는 git에서 무엇을 하는지
짐작하기 어려운 용어**는 설명 카드로 도와준다. 사용자가 옵션을 고르는 바로 그
자리(병합 방식 선택, Pull 방식 선택, 강제 push 확인 등)에서 연다.

#### 카드 구성

모든 카드는 같은 다섯 칸으로 쓴다. 사전 뜻과 git 동작 사이의 연결고리를 먼저
짚는 것이 핵심이다.

1. **낱말 뜻** — 사전적 의미 한 줄.
2. **git에서는** — 그 뜻이 git에서 어떤 동작이 되는지, 둘을 잇는 한 문장.
3. **왜·언제 쓰나 / 쓰지 않나** — 고를 때 판단 기준. 장단점.
4. **그림** — 실행 전 → 실행 후 커밋 그래프 (점과 선 3~6개).
5. **더 알아보기** — 공식 문서 링크 1~2개 (한국어 우선).

카드 본문은 앱이 직접 쓰고(오프라인에서도 보이게 앱에 포함, ko/en), 링크는
보충으로만 둔다. 링크는 구현할 때 다시 열어 보고 넣는다.

#### 대상 용어

| 용어 | 우선 | 여는 곳 |
|---|---|---|
| fast-forward | P0 | 병합 방식, Pull 방식, push 거부(non-fast-forward) 오류 |
| squash | P0 | 병합 방식, PR 병합 방식 |
| merge commit (`--no-ff`) | P0 | 병합 방식, PR 병합 방식 |
| rebase | P0 | Pull 방식, PR 병합 방식, rebase 중 상태 |
| fetch vs pull | P0 | 상태 헤더 버튼 |
| upstream / 추적 브랜치, origin | P0 | 상태 헤더, 게시(Publish), 원격 |
| stash | P1 | 브랜치 전환·pull이 막혔을 때 |
| detached HEAD | P1 | 태그 체크아웃, 상태 헤더 |
| force-with-lease | P1 | 강제 push 확인 |
| 주석 태그 vs 가벼운 태그 | P1 | 새 태그 양식 |
| prune | P2 | Fetch 옵션, 브랜치 정리 |
| cherry-pick, revert | P2 | 기록 메뉴 |

#### 예시 카드 (문구 기준)

**fast-forward (빨리 감기)**
1. 낱말 뜻: 테이프나 영상을 앞으로 빨리 감는 것.
2. git에서는: 내 브랜치가 갈라진 적 없이 뒤처져 있기만 할 때, 새 커밋을
   만들지 않고 **브랜치 이름표를 최신 커밋 위치로 앞으로 옮기기만** 한다.
   이미 있는 커밋을 따라 "앞으로 감기"만 하므로 이렇게 부른다.
3. 왜: 기록이 한 줄로 깔끔하고, 합칠 것이 없으니 충돌도 없다.
   안 되는 경우: 양쪽에 서로 다른 새 커밋이 있으면(갈라졌으면) 빨리 감을
   수 없다. 이때 "fast-forward만" 옵션은 실패하고, 병합 커밋이나 rebase가
   필요하다. push가 non-fast-forward로 거부되는 것도 같은 이유 — 원격이 내가
   모르는 커밋을 갖고 있어서 원격 브랜치를 앞으로 감을 수 없는 것이다.
4. 그림: `main A─B` + `feature A─B─C─D` → `main A─B─C─D` (이름표만 이동).
5. 링크: [Pro Git — 브랜치와 Merge의 기초](https://git-scm.com/book/ko/v2/Git-%EB%B8%8C%EB%9E%9C%EC%B9%98-%EB%B8%8C%EB%9E%9C%EC%B9%98%EC%99%80-Merge-%EC%9D%98-%EA%B8%B0%EC%B4%88),
   [git-merge 문서](https://git-scm.com/docs/git-merge)

**squash (눌러 합치기)**
1. 낱말 뜻: 눌러서 납작하게 만들다, 찌그러뜨리다.
2. git에서는: 브랜치의 **여러 커밋을 눌러 커밋 하나로 합친 뒤** 대상
   브랜치에 올린다. 변경 내용은 그대로이고 커밋 개수만 하나가 된다.
3. 왜: "오타 수정", "다시 시도" 같은 작업 중 커밋을 기본 브랜치 기록에 남기지
   않고, 기능 하나 = 커밋 하나로 정리한다. PR을 병합할 때 가장 많이 쓴다.
   주의: 원래 커밋들은 기본 브랜치 기록에 남지 않고, 병합한 브랜치를 계속
   이어서 쓰면 같은 변경이 다시 충돌할 수 있다 → 병합 후 브랜치를 지우는
   것을 권한다.
4. 그림: `feature C─D─E` → `main A─B─S` (S = C+D+E를 합친 새 커밋).
5. 링크: [GitHub — 병합 방법 정보](https://docs.github.com/ko/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/about-merge-methods-on-github),
   [GitHub — PR 병합 정보](https://docs.github.com/ko/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/about-pull-request-merges)

#### 비교 도움말

병합 방식처럼 **여러 개 중 하나를 고르는 곳**에는 카드 대신 한 화면 비교를
연다: fast-forward / merge commit / squash / rebase를 같은 시작 그래프로
그려 결과를 나란히 보여 주고, "이럴 때 고르세요" 한 줄씩. 현재 저장소
상태에서 가능한 방식만 활성으로 표시한다 (예: 갈라졌으면 fast-forward 비활성
+ 이유).

#### 그 밖의 참고 링크

- [Pro Git — Rebase 하기](https://git-scm.com/book/ko/v2/Git-%EB%B8%8C%EB%9E%9C%EC%B9%98-Rebase-%ED%95%98%EA%B8%B0)
- [Pro Git — 리모트 브랜치](https://git-scm.com/book/ko/v2/Git-%EB%B8%8C%EB%9E%9C%EC%B9%98-%EB%A6%AC%EB%AA%A8%ED%8A%B8-%EB%B8%8C%EB%9E%9C%EC%B9%98) (upstream, 추적 브랜치)
- [Pro Git — Stashing과 Cleaning](https://git-scm.com/book/ko/v2/Git-%EB%8F%84%EA%B5%AC-Stashing%EA%B3%BC-Cleaning)
- [Pro Git — 태그](https://git-scm.com/book/ko/v2/Git%EC%9D%98-%EA%B8%B0%EC%B4%88-%ED%83%9C%EA%B7%B8)
- [Learn Git Branching](https://learngitbranching.js.org/?locale=ko) — 브라우저에서 그래프를 직접 움직여 보는 연습 (도움말 목록 맨 아래 "연습하기"로)

## 4. 범위 밖

- 대화형 rebase, 서브모듈, Git LFS, blame, 코드 리뷰 코멘트 작성, 3-way 병합 편집기
- Issues, Projects, Discussions, Gist, Codespaces
- GitLab, Bitbucket 등 GitHub가 아닌 호스팅의 PR/MR·릴리스·CI (`glab` 등
  다른 도구 지원 없음, §2.1). git 동작은 호스팅과 관계없이 쓸 수 있다.
- 여러 GitHub 계정 전환, GitHub Enterprise Server 공식 지원 (gh 설정에 맡김)

## 5. 기술 사항

- **실행**: `Process.start`로 `git`, `gh`를 저장소 폴더에서 실행한다.
  인자는 목록으로 넘기고 셸을 거치지 않는다. 오래 걸리는 작업은 출력을
  스트리밍하고 취소할 수 있게 한다.
- **대화형 프롬프트 막기**: `GIT_TERMINAL_PROMPT=0`, `GH_PROMPT_DISABLED=1`,
  `GIT_EDITOR=true`. 입력이 필요한 작업은 앱이 먼저 값을 받아 인자로 넘긴다.
- **실행 파일 찾기**: macOS GUI 앱은 셸의 `PATH`를 받지 못한다.
  `/opt/homebrew/bin`, `/usr/local/bin`, 로그인 셸의 `PATH`(`$SHELL -lc 'echo $PATH'`)
  순서로 찾고, 설정에서 경로를 직접 지정할 수 있게 한다.
- **macOS 샌드박스 해제**: 외부 프로그램 실행과 임의 폴더 접근이 필요하므로
  `com.apple.security.app-sandbox`를 끈다 (Developer ID 배포라 가능, App
  Store 배포는 하지 않음). hardened runtime은 유지.
- **새로 고침**: `.git/HEAD`, `.git/index`, `.git/refs`를 감시(파일 감시 +
  짧은 debounce)하고, 창이 활성화될 때도 새로 고친다. 편집기에서 커밋해도
  앱에 바로 반영된다.
- **최소 버전**: git 2.30, gh 2.40 이상 (구현하면서 실제로 쓰는 옵션 기준으로 확정).
- **저장**: 최근 저장소, 저장소별 pull 방식, 편집기 명령은 `shared_preferences`.
  테마·언어 키는 공통 규약(`theme_mode`, `app_locale`).
- **테스트**: 명령 조립과 출력 파싱은 순수 함수로 두고 단위 테스트.
  통합 테스트는 임시 폴더에 만든 저장소와 로컬 bare 원격으로 실행한다
  (GitHub 호출 없음).

## 6. 마일스톤

| 버전 | 내용 |
|---|---|
| v0.1.0 | 3.1 · 3.2 · 3.3 · 3.4 · 3.6 P0, 명령 로그 — 매일 쓰는 동기화 흐름 |
| v0.2.0 | 3.5 병합, 3.7 태그, 3.8 릴리스 마법사 P0 |
| v0.3.0 | 3.9 PR, 3.10 Actions, 3.8.6 릴리스 관리 |
| 이후 | P1 나머지, P2 |

첫 정식 릴리스 전에 README의 기능·동작 방식·스크린샷·데모 GIF를 채운다.

## 7. 정할 것

- 기본 편집기 연결 방식: OS 기본 앱으로 열기 vs `code`/`idea` 같은 명령 지정 (둘 다 지원 예정, 기본값 결정 필요)
- Windows에서 `gh`/`git` 경로 탐색 (Git for Windows, winget, scoop 설치 위치)
- 앱 이름: "GitHub CLI"는 공식 도구 이름과 같아 혼동과 상표 문제가 있을 수 있다.
  첫 정식 릴리스 전에 이름을 확정한다 (식별자 `art.zoomon.githubcli`는 정식
  릴리스 전인 지금은 아직 바꿀 수 있다).
