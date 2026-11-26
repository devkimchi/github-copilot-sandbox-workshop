# 스크립트

## 사전 준비 확인과 설치

**설치 동작은 실행 미검증.** 저장소 루트에서 실행한다. 점검은 Host, Core tools, GitHub Copilot CLI, Azure Container Apps Sandboxes, Docker Sandboxes 순으로 진행한다. 설치는 Core tools, GitHub Copilot CLI, Azure Container Apps Sandboxes, Docker Sandboxes 순으로 진행한다. Linux에서는 Local sandbox packages도 점검하고 설치한다. 상태와 그룹 안내는 PASS, FAIL, WARN, MANUAL, INFO에 따라 색으로 구분한다.

| 스크립트 | 동작 |
| --- | --- |
| `check-prerequisites.ps1`, `check-prerequisites.sh` | 읽기 전용으로 OS와 Windows PowerShell 7, Git, GitHub CLI, Node.js 관리자와 버전, npm, Copilot CLI, `sbx`, Azure CLI, `aca`와 로그인 상태를 확인한다. GitHub 로그인은 `gh auth status`로 직접 확인하도록 표시한다. Linux에서는 `bubblewrap`, `slirp4netns`, KVM 접근도 확인한다. 필수 항목이 실패하면 0이 아닌 코드로 끝난다. |
| `install-prerequisites.ps1`, `install-prerequisites.sh` | 대화형 터미널에서 그룹별로 항목을 확인하고 PATH에 없는 도구만 설치한다. Windows PowerShell 7과 GitHub CLI도 설치하며, Linux에서는 로컬 샌드박스 패키지를 설치한다. 마지막에 check 스크립트를 다시 실행한다. 비대화형 환경에서는 설치하지 않고 실패한다. |

```powershell
# Windows, PowerShell 7
./scripts/check-prerequisites.ps1
./scripts/install-prerequisites.ps1
```

```bash
# macOS, Linux
./scripts/check-prerequisites.sh
./scripts/install-prerequisites.sh
```

Git, GitHub CLI, Azure CLI, Copilot CLI, `sbx`와 `aca`는 설치 시점에 패키지 저장소나 공식 설치 프로그램에서 제공하는 버전을 설치한다. 기존 설치는 자동 업데이트하지 않으며 필요한 업데이트는 원래 설치 경로로 직접 수행한다. check 스크립트는 설치 여부와 최소 요구 사항을 검사하며 최신 버전인지 판정하지 않는다.

Node.js는 macOS와 Linux에서 nvm으로, Windows에서 nvm-windows 2.x로 24.x 최신 버전을 설치한다. nvm 밖에서 설치한 Node.js는 자동 제거하지 않는다. Windows는 WinGet, macOS는 Homebrew, Linux는 Ubuntu 계열의 apt를 사용한다. Windows Hypervisor Platform 활성화와 재부팅은 사람이 직접 한다. `terminal-output.sh`와 `powershell-bootstrap.ps1`은 공통 출력과 초기화 도우미다.

## 앱 추출

**실행 미검증.** PowerShell 7 이상 또는 Bash에서, 개인 워크숍 저장소 루트를 현재 위치로 사용한다. Git, curl과 tar가 필요하다. Windows PowerShell 5.1의 `curl` 별칭을 피하려고 `.ps1`은 `curl.exe`와 `tar.exe`를 명시한다.

```powershell
pwsh -File .\scripts\download-sample.ps1
```

```bash
bash scripts/download-sample.sh
```

기본 대상은 현재 폴더 바로 아래 `workspace`다. Lab 2처럼 별도 폴더가 필요하면 `-Target workspace-이름` 또는 첫 번째 인자로 `workspace-이름`을 지정한다. 기존 대상은 덮어쓰지 않는다. 다운로드/추출 임시 폴더만 자동 정리한다. Git 단계에서 실패해 생긴 부분 workspace는 보존하며 오류를 보고한다. 실패한 대상은 사람이 확인하고 **다른 이름으로 다시 시작**한다.

고정 SHA `9cd9a450f923c7a084bd47d661877d82ff710826`의 압축본을 받고 명시 목록만 추출한다. 네트워크에서는 전체 스냅샷 압축본을 받지만 최종 폴더에는 앱 파일만 남는다. `.github/`, `.vscode/`, `.devcontainer/`와 원본 문서는 제외한다. 원본 `.gitignore`와 MIT `LICENSE`는 유지한다.

새 독립 Git 저장소의 `main`에 기준 커밋과 `baseline` 태그를 만들고 remote는 추가하지 않는다. 원본 SHA와 로컬 기준 commit SHA는 다르며 참가자끼리 로컬 SHA를 같게 만들 필요는 없다. `core.autocrlf=false`는 새 workspace 로컬 설정이다. 원본 commit의 내용은 고정하지만 별도 배포용 압축본 checksum은 `TBD(검증 필요)`다.

다음은 참가자가 실행할 확인 명령이며 **미검증**이다.

```powershell
git -C .\workspace status --short
git -C .\workspace remote -v
git -C .\workspace ls-files
git -C .\workspace rev-parse baseline
git status --short --ignored
```

기대는 clean, remote 없음, 앱 파일만 존재, 바깥 저장소에서 workspace 무시다. 과거 연구 부록 A.7은 54개 추적 파일을 보고했지만 이 스크립트의 실행 결과가 아니다. OS별 파일 목록과 내용의 동일성은 예행 연습에서 확인한다.

`npm ci`, 테스트, Copilot, Docker와 Azure는 실행하지 않는다. [Lab 0/1](../docs/02-copilot-local-sandbox.md)에서 다음 절차를 확인한다.
