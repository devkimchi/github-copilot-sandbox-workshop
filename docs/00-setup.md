# 준비: 저장소 생성부터 샘플 다운로드까지

[워크숍 개요](../README.md) | [다음: 승인과 접근 범위](01-approval-and-boundaries.md) | [문제 해결](troubleshooting.md)

## 실행 환경

Windows에서는 **PowerShell 7**, macOS와 Linux에서는 **Bash** 또는 **Zsh**를 사용한다. 개인 PC에서 실습하기 어렵다면 [실습용 Windows VM](../windows-vm/README.md)을 준비한다.

> [!NOTE]
>
> 아래 도구 점검, 설치와 샘플 다운로드 절차는 실행 미검증이다. 점검 결과만으로 샌드박스 실행이나 모델 요청 성공을 판단하지 않는다.

### 사전 설치 항목

| 도구 | 용도와 준비 방법 |
| --- | --- |
| [Git](https://git-scm.com/downloads) | 저장소 복제와 샘플의 기준 커밋 생성 |
| [Copilot CLI](https://github.com/github/copilot-cli) | Copilot 자체 샌드박스 실습 |
| Windows: [PowerShell 7](https://learn.microsoft.com/powershell/scripting/install/install-powershell-on-windows) | Windows용 스크립트 실행 |
| [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) | 개인 Azure 계정 인증과 구독 선택 |
| [ACA CLI](https://sandboxes.azure.com/docs/sandboxes/quickstart/setup-cli) (`aca`) | Azure Container Apps Sandboxes 실습 |
| [GitHub CLI](https://cli.github.com/) (`gh`) | 개인 저장소 인증과 복제 |
| [nvm](https://github.com/nvm-sh/nvm) | Node.js 버전 관리. Windows에서는 [nvm-windows 2.x](https://github.com/nvm-windows/nvm) 사용 |
| [Node.js 24.x](https://nodejs.org/) | 샘플 앱 실행. nvm으로 설치 |
| [Docker Sandboxes CLI](https://docs.docker.com/ai/sandboxes/install/) (`sbx`) | Docker 샌드박스 실습 |

도구별 링크에서 설치 방법과 지원 환경을 확인한다. Docker Desktop은 `sbx`를, `az containerapp`은 `aca`를 대체하지 않는다. 180분 확장 과정에서 mixin을 직접 만들 때는 Docker와 Buildx도 필요하다.

## 템플릿으로 저장소 만들고 복제하기

1. [워크숍 템플릿](https://github.com/devkimchi/github-copilot-sandbox-workshop)에서 **Use this template > Create a new repository**를 선택하거나 [![GitHub에서 템플릿으로 저장소 만들기](https://img.shields.io/badge/GitHub-Create%20repository%20from%20template-2ea44f?style=flat&logo=github&logoColor=white)](https://github.com/new?template_name=github-copilot-sandbox-workshop&template_owner=devkimchi)을 클릭한다.
2. 소유자는 **개인 계정**, 공개 범위는 **Private**을 권장한다. **Include all branches**는 선택하지 않는다.
3. 터미널에서 개인 GitHub 계정으로 로그인하고 만든 저장소를 복제한다. `<...>`는 본인의 계정과 저장소 이름으로 바꾼다.

```bash
gh auth login
gh repo clone "<본인-계정>/<저장소-이름>"
cd "<저장소-이름>"
```

복제한 폴더가 **워크숍 루트**이며, 이후 명령은 별도 안내가 없으면 여기서 실행한다. 원본 템플릿을 직접 복제하거나 포크하지 않는다. 템플릿으로 만든 저장소에는 원본의 변경 사항이 자동으로 반영되지 않는다.

## 필수 도구 점검과 설치

### 설치 여부 점검

워크숍 루트에서 운영체제에 맞는 명령을 실행한다.

```powershell
# Windows, PowerShell 7
./scripts/check-prerequisites.ps1
```

```bash
# macOS, Linux
bash scripts/check-prerequisites.sh
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
gh --version
node --version
npm --version
```

### 누락된 도구 설치

다음 스크립트는 대화형 터미널에서 항목마다 승인을 받고 도구를 설치한다. 다운로드와 시스템 변경 내용을 확인한 뒤 필요한 항목만 승인한다.

```powershell
# Windows, PowerShell 7
./scripts/install-prerequisites.ps1
```

```bash
# macOS, Linux
bash scripts/install-prerequisites.sh
```

스크립트가 설치하는 도구는 다음과 같다.

| 구분 | 설치 도구 | 설치 방법 |
| --- | --- | --- |
| 기본 도구 | Git | Windows: WinGet, macOS: Homebrew, Linux: apt |
| Node.js | nvm, Node.js 24.x 최신 버전 | Windows: WinGet으로 nvm-windows 2.x 설치, macOS와 Linux: nvm 공식 설치 스크립트 |
| Copilot | Copilot CLI | Windows: WinGet, macOS와 Linux: 공식 설치 스크립트 |
| Docker 샌드박스 | Docker Sandboxes CLI (`sbx`) | Windows: WinGet, macOS: Homebrew, Linux: Docker apt 저장소 |
| Azure | Azure CLI | Windows: WinGet, macOS: Homebrew, Linux: Microsoft 공식 설치 스크립트 |
| Azure | ACA CLI (`aca`) | 공식 설치 스크립트 |
| Linux 전용 | bubblewrap, slirp4netns | apt |

macOS에서 Homebrew가 없으면 먼저 Homebrew 설치 승인을 요청한다. PATH에서 찾은 기존 도구는 설치하거나 업데이트하지 않는다. 단, Node.js는 nvm으로 24.x 최신 버전을 따로 설치하고 사용할 버전을 선택한다. Windows에서 nvm-windows 밖에 설치한 Node.js가 있으면 직접 제거한 뒤 다시 실행하라고 안내한다. GitHub CLI는 설치 대상이 아니므로 앞의 공식 링크로 준비한다. Windows Hypervisor Platform 활성화는 스크립트가 안내하는 명령으로 직접 진행한다.

설치가 끝나면 스크립트가 점검을 다시 실행한다. 현재 터미널에서 새 도구나 Node.js 버전을 찾지 못하면 화면의 PATH 안내를 따르거나 새 터미널을 열어 다시 점검한다. 실행 정책이나 조직 정책으로 차단되면 임의로 완화하지 않는다.

### 인증과 권한 확인

GitHub 로그인 상태를 확인하고, Azure CLI에서는 본인의 실습용 구독을 선택한다.

```bash
gh auth status
az login
az account show
```

Copilot CLI에서는 `copilot`을 실행한 뒤 `/login`으로 로그인하고 본인의 라이선스를 확인한다. PAT가 필요한 경우에는 짧은 만료 기간과 `Copilot Requests` 권한을 가진 본인의 fine-grained PAT를 사용한다.

Docker Sandboxes 인증과 Copilot 토큰 저장은 다음 명령의 보안 입력 흐름으로 진행한다.

```text
sbx login
sbx secret set copilot
```

토큰을 명령 인자, 파일이나 관찰표에 붙여 넣지 않는다. 구독과 계정 정보가 포함된 출력은 그대로 공유하지 않는다. ACA의 샌드박스 그룹, 권한과 자격 증명은 [Lab 3의 사전 조건](05-aca-sandboxes.md#3-사전-조건과-현재-상태)과 [공식 출처](sources.md)를 확인해 해당 실습 전에 준비한다.

## 샘플 다운로드하기

워크숍 루트에서 운영체제에 맞는 명령을 실행한다. Git, curl과 tar가 필요하며, Windows 스크립트는 `curl.exe`와 `tar.exe`를 사용한다. **대상 `workspace` 폴더는 없어야 한다. 빈 폴더도 허용하지 않는다.**

```powershell
# Windows, PowerShell 7
./scripts/download-sample.ps1
```

```bash
# macOS, Linux
bash scripts/download-sample.sh
```

스크립트는 [Tailspin Toys의 고정 스냅샷](https://github.com/github-samples/tailspin-toys/tree/9cd9a450f923c7a084bd47d661877d82ff710826)을 다운로드하고 앱 파일만 추출한다. 원본의 `.github/`, `.vscode/`, `.devcontainer/`와 문서는 제외하고, `.gitignore`와 MIT `LICENSE`는 유지한다.

`workspace`에는 독립 Git 저장소와 기준 커밋, `baseline` 태그를 만든다. 원격 저장소는 연결하지 않는다. 다음 명령으로 상태를 확인한다.

```bash
git -C workspace status --short
git -C workspace remote -v
git -C workspace rev-parse --verify baseline
```

첫 두 명령은 출력이 없어야 하고, 마지막 명령은 기준 커밋 SHA를 표시해야 한다. 실패해서 일부 파일이 남았다면 삭제하거나 덮어쓰지 말고 내용을 확인한다. 다시 받으려면 남은 폴더의 이름을 바꾼 뒤 명령을 다시 실행한다. 자세한 동작은 [스크립트 안내](../scripts/README.md#앱-추출)를 참고한다.

이 단계에서는 의존성 설치와 테스트를 실행하지 않는다. 해당 절차는 [Lab 0/1](02-copilot-local-sandbox.md)에서 진행한다.

## 완료 및 다음 단계

- [ ] 개인 계정에 템플릿으로 저장소를 만들고 복제했다.
- [ ] 도구 점검의 `FAIL` 항목을 해결하고 Node.js 24.x를 확인했다.
- [ ] GitHub, Copilot CLI, Azure와 Docker Sandboxes 인증을 마쳤다.
- [ ] `workspace/package.json`과 `workspace/LICENSE`가 있다.
- [ ] `workspace`의 작업 트리가 깨끗하고 `baseline` 태그가 있으며 원격 저장소는 없다.

준비를 마쳤다면 [1. 승인과 접근 범위](01-approval-and-boundaries.md)로 이동한다.
