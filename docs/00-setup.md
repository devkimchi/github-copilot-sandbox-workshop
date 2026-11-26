# 준비: 저장소 생성부터 샘플 다운로드까지

[워크숍 개요](../README.md) | [다음: 승인과 접근 범위](01-approval-and-boundaries.md) | [문제 해결](troubleshooting.md)

## 실행 환경

Windows에서는 **PowerShell 7**, macOS와 Linux에서는 **Bash** 또는 **Zsh**를 사용한다.

### 사전 설치 항목

| 도구 | 용도와 준비 방법 |
| --- | --- |
| [Git](https://git-scm.com/downloads) | 저장소 복제와 샘플의 기준 커밋 생성 |
| [GitHub CLI](https://cli.github.com/) (`gh`) | 개인 저장소 인증과 복제 |
| [nvm](https://github.com/nvm-sh/nvm) | Node.js 버전 관리. Windows에서는 [nvm-windows 2.x](https://github.com/nvm-windows/nvm) 사용 |
| [Node.js 24.x](https://nodejs.org/) | 샘플 앱 실행. nvm으로 설치 |
| [Copilot CLI](https://github.com/github/copilot-cli) | Copilot 자체 샌드박스 실습 |
| [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) | 개인 Azure 계정 인증과 구독 선택 |
| [ACA CLI](https://sandboxes.azure.com/docs/sandboxes/quickstart/setup-cli) (`aca`) | Azure Container Apps Sandboxes 실습 |
| [Docker Sandboxes CLI](https://docs.docker.com/ai/sandboxes/install/) (`sbx`) | Docker 샌드박스 실습 |
| Windows: [PowerShell 7](https://learn.microsoft.com/powershell/scripting/install/install-powershell-on-windows) | Windows용 스크립트 실행 |

## 템플릿으로 저장소 만들고 복제하기

1. [워크숍 템플릿](https://github.com/devkimchi/github-copilot-sandbox-workshop)에서 **Use this template > Create a new repository**를 선택하거나 [![GitHub에서 템플릿으로 저장소 만들기](https://img.shields.io/badge/GitHub-Create%20repository%20from%20template-2ea44f?style=flat&logo=github&logoColor=white)](https://github.com/new?template_name=github-copilot-sandbox-workshop&template_owner=devkimchi)을 클릭한다.
2. 소유자는 **개인 계정**, 공개 범위는 **Private**을 권장한다. **Include all branches**는 선택하지 않는다.
3. 터미널에서 개인 GitHub 계정으로 로그인하고 만든 저장소를 복제한다. `<...>`는 본인의 계정과 저장소 이름으로 바꾼다(예: `octocat/github-copilot-sandbox-workshop`).

```bash
gh auth login
gh repo clone "<본인-계정>/<저장소-이름>"
cd "<저장소-이름>"
```

복제한 폴더가 **워크숍 루트**이며, 이후 명령은 별도 안내가 없으면 여기서 실행한다. 원본 템플릿을 직접 복제하거나 포크하지 않는다. 템플릿으로 만든 저장소에는 원본의 변경 사항이 자동으로 반영되지 않는다.

## 필수 도구 점검과 설치

### 설치 여부 점검

워크숍 루트에서 운영체제에 맞는 명령을 실행한다.

```bash
# zsh/bash
./scripts/check-prerequisites.sh
```

```powershell
# PowreShell
./scripts/check-prerequisites.ps1
```

| 결과 | 의미와 후속 조치 |
| --- | --- |
| ![PASS](https://img.shields.io/badge/PASS-green) | 해당 점검 통과. 앱 실행이나 모델 요청까지 확인한 것은 아님 |
| ![FAIL](https://img.shields.io/badge/FAIL-red) | 누락된 도구나 설정을 보완한 뒤 다시 점검 |
| ![WARN](https://img.shields.io/badge/WARN-yellow) | 권장 버전이나 선택 도구 등 경고 내용 확인 |
| ![MANUAL](https://img.shields.io/badge/MANUAL-cyan) | 로그인, 라이선스와 권한 등 직접 확인할 항목 |
| ![INFO](https://img.shields.io/badge/INFO-blue) | 참고 정보 |

GitHub CLI는 점검 스크립트의 대상이 아니므로 별도로 확인한다. Node.js는 24.x 이상이어야 한다. 이보다 낮으면 점검 스크립트가 `FAIL`로 표시하고 설치 스크립트로 24.x 최신 버전을 설치하도록 안내한다.

```bash
git --version
gh --version
nvm --version
node --version
npm --version
copilot --version
az --version
aca --version
sbx --version
pwsh --version    # Windows
```

### 누락된 도구 설치

다음 스크립트는 대화형 터미널에서 항목마다 승인을 받고 도구를 설치한다. 다운로드와 시스템 변경 내용을 확인한 뒤 필요한 항목만 승인한다.

```bash
# zsh/bash
./scripts/install-prerequisites.sh
```

```powershell
# PowerShell
./scripts/install-prerequisites.ps1
```

스크립트가 설치하는 도구는 다음과 같다.

| 구분 | 설치 도구 | 설치 방법 |
| --- | --- | --- |
| 기본 도구 | Git | Windows: WinGet, macOS: Homebrew, Linux: apt |
| 기본 도구 | GitHub CLI | Windows: WinGet, macOS: Homebrew, Linux: apt |
| Node.js | nvm, Node.js 24.x 최신 버전 | Windows: WinGet으로 nvm-windows 2.x 설치, macOS와 Linux: nvm 공식 설치 스크립트 |
| Copilot | Copilot CLI | Windows: WinGet, macOS와 Linux: 공식 설치 스크립트 |
| Azure | Azure CLI | Windows: WinGet, macOS: Homebrew, Linux: Microsoft 공식 설치 스크립트 |
| Azure | ACA CLI (`aca`) | 공식 설치 스크립트 |
| Docker 샌드박스 | Docker Sandboxes CLI (`sbx`) | Windows: WinGet, macOS: Homebrew, Linux: Docker apt 저장소 |
| Windows 전용 | PowerShell 7.x | WinGet |
| Linux 전용 | bubblewrap, slirp4netns | apt |

### 인증과 권한 확인

#### GitHub 로그인 상태 확인

```bash
gh auth status
```

#### Azure 로그인 및 상태 확인
```bash
az login
az account show
```

#### GitHub Copilot CLI 로그인

```bash
copilot login
```

#### Docker 샌드박스 로그인

```bash
sbx login
```

#### Azure Container Apps 샌드박스 로그인

```bash
aca auth login
aca auth status
```

## 샘플 다운로드하기

샘플 앱을 다운로드 받아 `workspace` 디렉토리에 저장한다.

```bash
# zsh/bash
./scripts/download-sample.sh
```

```powershell
# PowerShell
./scripts/download-sample.ps1
```

`workspace`에는 독립 Git 저장소와 기준 커밋, `baseline` 태그를 만든다. 원격 저장소는 연결하지 않는다. 다음 명령으로 상태를 확인한다.

```bash
git -C workspace status --short
git -C workspace remote -v
git -C workspace rev-parse --verify baseline
```

## 완료 및 다음 단계

- [ ] 개인 계정에 템플릿으로 저장소를 만들고 복제했다.
- [ ] 도구 점검의 `FAIL` 항목을 해결하고 Node.js 24.x를 확인했다.
- [ ] GitHub, Copilot CLI, Azure와 Docker Sandboxes 인증을 마쳤다.
- [ ] `workspace/package.json`과 `workspace/LICENSE`가 있다.
- [ ] `workspace`의 작업 트리가 깨끗하고 `baseline` 태그가 있으며 원격 저장소는 없다.

준비를 마쳤다면 [1. 승인과 접근 범위](01-approval-and-boundaries.md)로 이동한다.
