# Branch Dock

Git과 GitHub CLI(`gh`)를 위한 데스크톱 도우미 (macOS / Windows / Linux).
편집기 옆에 세로로 세워 두고 브랜치·태그·병합·Pull/Push·원격·릴리스를 버튼으로
다루며, 버튼마다 실제로 실행되는 `git`/`gh` 명령을 보여 준다. GitHub 저장소에
가장 알맞고, GitLab 등 다른 호스팅에서는 git 동작만 쓸 수 있다.

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
