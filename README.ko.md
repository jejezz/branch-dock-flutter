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
  <img src="docs/screenshots/demo.gif" width="720" alt="Branch Dock 데모: 저장소 열기, 브랜치 만들기, Push, 태그를 달고 릴리스 게시">
</p>

## 기능

- **{{TODO: 기능}}** — {{TODO: 무엇을 하는지 구체적으로 (이름, 숫자, 형식)}}
- **{{TODO: 기능}}** — {{TODO: …}}
- **{{TODO: 기능}}** — {{TODO: …}}
- **라이트·다크, 한국어·English** — 시스템 설정을 따르거나 툴바에서 고를 수 있습니다

<p align="center">
  <img src="docs/screenshots/home.png" width="360" alt="{{TODO: 화면 1}}">
  <img src="docs/screenshots/detail.png" width="360" alt="{{TODO: 화면 2}}">
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

{{TODO: 궁금한 사람을 위한 2~4문장 — 흥미로운 기술적 선택 한 가지. 말할 것이 없으면 이 절을 지웁니다.}}

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
