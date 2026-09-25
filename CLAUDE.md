# Branch Dock

GitHub CLI(`gh`)를 위한 데스크톱 GUI (macOS / Windows / Linux). `gh` 명령을
터미널 대신 창에서 실행하고, 저장소·풀 리퀘스트·이슈·릴리스를 한 화면에서
다룬다.

릴리스·버전·패키징·정보 창·아이콘·라이선스·UI/UX·글꼴·언어·테마는
https://github.com/jejezz/application-release-templates/tree/main/conventions
규약을 따른다. 이 앱에 적용된 규약 버전: conventions-v1

- 표시 이름 `Branch Dock`, 파일 이름 `BranchDock`, 패키지 `branch_dock`,
  식별자 `art.zoomon.branchdock`. 식별자와 `installer/windows/app.iss`의
  `AppId`는 릴리스 후 바꾸지 않는다.
- 공식 GitHub CLI와 무관한 개인 프로젝트다. 사용자가 설치한 `git`, `gh`를 호출한다.
- 앱 이름에 "Git"/"GitHub"를 넣지 않는다 (Git 상표 정책, GitHub 상표). 소개 문구에서만
  "for Git", "for the GitHub CLI"처럼 쓴다.
- 기능 범위는 [PLAN.md](PLAN.md), 화면은 [UI_UX.md](UI_UX.md).
