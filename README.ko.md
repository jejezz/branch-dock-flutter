<!-- From jejezz/application-release-templates common/tool/readme @ conventions-v1.
     tool/readme/init_readme.py가 만든 파일입니다 — conventions/readme-guide.md 참고.
     {{TODO: …}}를 모두 채우십시오. 하나라도 남아 있으면 tool/readme/check_readme.py가 실패합니다. -->

<p align="center">
  <img src="assets/icon/app_icon.png" width="128" alt="Branch Dock 아이콘">
</p>

<h1 align="center">Branch Dock</h1>

<p align="center">
  <b>Git과 GitHub CLI를 위한 데스크톱 도우미</b> — 편집기 옆에 세워 두고 브랜치·태그·병합·Pull/Push·원격·릴리스를 버튼으로 다룹니다. 버튼마다 실제로 실행되는 명령을 보여 줍니다.
</p>

<p align="center">
  <a href="https://github.com/jejezz/branch-dock-flutter/releases/latest"><img src="https://img.shields.io/github/v/release/jejezz/branch-dock-flutter?style=flat-square&color=4c9dff" alt="최신 릴리스"></a>
  <a href="https://github.com/jejezz/branch-dock-flutter/releases"><img src="https://img.shields.io/github/downloads/jejezz/branch-dock-flutter/total?style=flat-square&color=7c5cff" alt="다운로드"></a>
  <img src="https://img.shields.io/badge/platform-macOS%20%C2%B7%20Windows%20%C2%B7%20Linux-34d399?style=flat-square" alt="macOS · Windows · Linux">
  <img src="https://img.shields.io/badge/built%20with-Flutter-02569b?style=flat-square" alt="Flutter">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/jejezz/branch-dock-flutter?style=flat-square" alt="MIT 라이선스"></a>
</p>

<p align="center">
  <a href="README.md">English</a> · <b>한국어</b>
</p>

<p align="center">
  <img src="docs/screenshots/demo.gif" width="720" alt="Branch Dock 데모: 브랜치 탭에서 새 브랜치 feature/hourly를 만들어 전환하고, 게시(Publish)로 원격에 올리는 흐름">
</p>

## 기능

- **편집기 옆에 세우는 세로 창** — 기본 440×960, 좁게는 380px까지. 편집기에서 저장하거나 터미널에서 커밋하면 바로 반영되고, 항상 위에 표시할 수 있습니다
- **상태 한눈에, 다음 할 일 하나** — 브랜치 → 추적 브랜치, ↑ 올릴 커밋 / ↓ 받을 커밋, 변경 수를 늘 위에 보여 주고 "커밋 2개가 아직 원격에 없습니다 [Push]"처럼 지금 할 일 하나를 제안합니다
- **Fetch · Pull · Push · 게시** — Pull 방식(병합 / rebase / fast-forward만)을 저장소별로 기억하고, 원격에 없는 브랜치는 Push 대신 게시(`git push -u`)로 올립니다
- **브랜치와 원격** — 브랜치 만들기(이름 검사)·전환·이름 바꾸기·삭제·원격 삭제, 원격 추가·URL 변경·HTTPS↔SSH 전환, `gh repo create`로 GitHub에 올리기
- **실행될 명령이 보이는 버튼** — 모든 양식이 실행할 `git`/`gh` 명령을 먼저 보여 주고, 명령 기록(⌘J)에 출력까지 남깁니다. 쓰다 보면 명령을 배웁니다
- **헷갈리는 말은 그림으로** — fetch와 pull, upstream, fast-forward, 병합 커밋, rebase를 낱말 뜻 → git에서의 뜻 → 커밋 그래프로 설명합니다. 자주 나는 오류 12가지는 이유와 해결 방법을 함께 보여 줍니다
- **라이트·다크, 한국어·English** — 시스템 설정을 따르거나 툴바에서 고를 수 있습니다

<p align="center">
  <img src="docs/screenshots/home.png" width="360" alt="변경 탭: 상태 헤더에 main → origin/main, ↑2, 변경 4와 Fetch·Pull·Push 버튼, 추천 배너, 스테이징된 파일과 변경된 파일 목록 (라이트·다크)">
  <img src="docs/screenshots/detail.png" width="360" alt="새 브랜치 양식: 브랜치 이름, 접두어 칩, 시작 브랜치, 만든 뒤 전환 체크, 실행될 명령 git switch -c feature/hourly">
</p>

## 설치

[**Releases**](https://github.com/jejezz/branch-dock-flutter/releases/latest)에서 받습니다.

| OS | 파일 |
|---|---|
| macOS 12.0 이상 | `BranchDock-<버전>-macos-universal.dmg` — 열어서 앱을 Applications 폴더로 끌어다 놓으세요 |
| Windows 10/11 (x64) | `BranchDock-<버전>-windows-x64-setup.exe` |
| Linux (x64) | `BranchDock-<버전>-linux-x64.tar.gz` — 압축을 풀고 `./install.sh` 실행 (`--remove`로 제거) |

**Windows:** 설치 프로그램에 아직 코드 서명이 없어서 SmartScreen이 "Windows의 PC 보호" 창을 띄웁니다. **추가 정보 → 실행**을 누르세요.

## 동작 방식

Branch Dock은 git을 다시 구현하지 않고, 설치된 `git`과 `gh`를 셸 없이 인자 목록으로 실행합니다. 상태는 사람이 읽는 출력이 아니라 `git status --porcelain=v2`, `git for-each-ref`, `gh --json` 같은 기계용 출력만 읽어서 git 버전이나 언어 설정에 흔들리지 않습니다. 그래서 앱에서 한 일과 터미널에서 한 일이 늘 같은 결과이고, 버튼마다 보여 주는 명령을 그대로 복사해 터미널에서 실행해도 됩니다.

## 개발

```bash
flutter pub get
flutter run -d macos
```

실행하려면 [git](https://git-scm.com)과 [GitHub CLI](https://cli.github.com)(`gh`)가 설치되어 있고 로그인(`gh auth login`)되어 있어야 합니다. Branch Dock은 설치된 것을 호출할 뿐 함께 넣어 배포하지 않습니다. git 동작은 어느 호스팅에서나 되지만, Pull Request·릴리스·Actions는 GitHub 원격이 있어야 합니다 — `gh`는 GitHub 전용입니다.

계획서: [PLAN.md](PLAN.md)(기능), [UI_UX.md](UI_UX.md)(화면).

릴리스: `scripts/bump-version.sh patch` → 병합 → `vX.Y.Z` 태그. CI가 모든 플랫폼을 빌드해서 올립니다. 규칙: [application-release-templates/conventions](https://github.com/jejezz/application-release-templates/tree/main/conventions).

## 크레딧

- 글꼴: [서울남산체](https://www.seoul.go.kr/seoul/font.do) (서울특별시)
- 아이콘: [Icons8](https://icons8.com)

## 라이선스

[MIT](LICENSE) © 2026 Jongyun Ahn
