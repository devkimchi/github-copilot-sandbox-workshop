# 사전 준비

설치와 계정 준비는 150/180분에 포함하지 않는다. 모든 명령과 통과 조건은 **미검증**이다. 강사가 리허설 후 확정한 버전표와 함께 사용한다. [워크숍 개요](../README.md), [공식 출처](sources.md).

## 실습 환경 선택

| 환경 | 조사 당시 전제 | 사전 확인 |
| --- | --- | --- |
| Windows 개인 PC | Windows 11 x64 Intel/AMD, Windows Hypervisor Platform | Copilot은 25H2 + KB5124010 이상 또는 26H1 + KB5124006 이상 등 공식 요구 확인. Docker 실행 성공과 별도 판정 |
| macOS 개인 PC | Sonoma 14 이상, Apple silicon | Copilot 자체 정책과 Docker microVM 각각 확인 |
| Linux 개인 PC | Ubuntu 24.04 이상, KVM과 사용자 권한 | Copilot용 `bwrap >= 0.5.0`, `slirp4netns` 확인 |
| 선택 Windows VM | 개인 Azure 구독의 별도 Windows 실습 호스트 | 이미지/SKU/업데이트와 모듈별 통과 여부 `TBD(검증 필요)`. Docker 중첩 가상화 미검증 |

Codespaces, 일반 VDI와 회사 PC까지 지원 범위를 넓히지 않는다. GitHub cloud sandbox와 Docker cloud는 실습하지 않는다. VM을 쓰면 문서의 HOST는 물리 PC가 아니라 접속한 VM이다.

## 개인 저장소

[README의 템플릿 절차](../README.md)를 따라 개인 계정에 별도 저장소를 만들고 클론한다. fork가 아니다. 개인 결과 공개 여부는 본인이 결정하되 private을 권장한다. 템플릿 URL은 `TBD(검증 필요)`다.

아래는 HOST PowerShell에서 확인한다. macOS/Linux에서는 동등한 셸 명령으로 위치와 추적 상태를 기록한다.

```powershell
Get-Location
git status --short
git remote -v
git config --get user.name
git config --get user.email
git --version
node --version
npm --version
copilot --version
sbx --version
aca --version
```

실습에 사용할 Git 이름과 이메일은 교육용 값을 **workspace 로컬 설정**에만 사용한다. 추출 스크립트는 기준 커밋에 한해 교육용 identity를 지정한다. 개인 전역 Git 설정을 덮어쓰지 않는다.

## 도구와 계정

제공 스크립트로 도구를 확인하고 설치할 수 있다. check 스크립트는 읽기 전용이다. install 스크립트는 대화형 터미널에서 항목마다 확인을 받은 뒤 PATH에 없는 도구만 설치하고 마지막에 check 스크립트를 다시 실행한다. 두 스크립트 모두 **미검증**이다.

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

Node.js는 **22.13 이상**이어야 한다. install 스크립트는 macOS와 Linux에서 nvm으로, Windows에서 nvm-windows 2.x로 24.x 최신 버전을 설치한다. Docker workload와 ACA image에서도 직접 확인한다. Tailspin은 Node 내장 `node:sqlite`를 사용한다. Windows용 제공 스크립트에는 **PowerShell 7 이상**이 필요하다.

Git, Copilot CLI, Docker Sandboxes CLI(`sbx`), Azure CLI, ACA Sandboxes CLI(`aca`)는 설치 시점에 패키지 저장소나 공식 설치 프로그램에서 제공하는 최신 버전을 사용한다. 기존 설치는 자동 업데이트하지 않으므로 필요한 업데이트는 원래 설치 경로로 직접 수행한다. 실제 사용한 버전은 기록한다. Docker Desktop이나 `az containerapp`은 `sbx`/`aca`를 대체하지 않는다.

Copilot은 본인 라이선스와 본인의 fine-grained PAT(`Copilot Requests`)를 사용한다. 짧은 만료와 최소 권한으로 만들고 공식 보안 입력 흐름으로 저장한다. 토큰을 예제 파일, Bicep, 스크립트, 셸 이력 또는 관찰표에 붙여 넣지 않는다. `gh auth token` 존재만으로 모델 요청 권한을 판정하지 않는다.

Docker에서는 다음을 사전에 진행한다.

```text
sbx login
sbx secret set copilot
```

인증이 필요한 Git/gh 작업을 별도로 할 때만 `sbx secret set github`를 사용한다. 공개 Tailspin 다운로드에는 저장소 쓰기 권한이 필요하지 않다. 두 service를 혼동하지 않는다.

## 개인 Azure 구독의 사전 준비

비용은 본인 구독에 발생한다. 강사의 구독, group과 PAT를 공유하지 않는다. 설치/그룹/credential 생성 명령은 CLI 버전에 민감하므로 공식 quickstart와 `--help`를 대조한다.

1. `az login` 후 `az account show`로 본인의 구독을 화면에서 확인한다. 원자료를 공유할 때 구독 ID와 계정 정보를 지운다.
2. 참가자별 교육 전용 sandbox group을 준비한다. `Microsoft.App/SandboxGroups` 경로이며 Dynamic Sessions/session pool이 아니다.
3. control plane 생성 권한과 `Container Apps SandboxGroup Data Owner` data plane 권한을 구분한다. 자동 역할 부여 시도가 성공했는지 확인한다.
4. Azure portal의 본인 sandbox group에서 **GitHub Copilot > Set Token**으로 fine-grained PAT를 등록한다. `Configured`를 확인하고 sandbox 생성에 쓸 정확한 credential ID를 확인한다. 조사 당시 provider는 `github_pat_`를 요구하며 classic `ghp_`는 지원하지 않는다고 설명한다. 이 포털 표시만으로 실제 모델 요청 성공을 확정하지 않는다.
5. 아래 preflight와 이미지, quota를 확인한다.

```text
aca doctor
aca config show
aca sandboxgroup disk list-public
aca sandboxgroup --help
```

본인 구독을 선택한 후 group을 만드는 명령 구조는 다음과 같다(미검증). 실제 region과 고유한 교육용 이름을 확인한 후에만 실행한다.

```powershell
$subscription = az account show --query id -o tsv
az group create --name <개인교육용리소스그룹> --location <검증한지역>
aca sandboxgroup create -g <개인교육용리소스그룹> --name <개인교육용SandboxGroup> --location <검증한지역> -s $subscription --set-config
aca doctor
```

provider credential 관리는 공식 문서의 portal 경로를 사용한다. CLI 하위 명령을 추측하지 않는다. credential ID 확인 경로와 최종 group 설정 문법은 `TBD(검증 필요)`다. 목록의 첫 credential을 자동 선택하지 않는다. group/identity를 공유하면 이름이나 label만으로 참가자 접근을 격리할 수 없다.

지역은 Korea Central이 **후보**일 뿐이다. 실제 region, image ID/revision, tier, 동시 cores quota, CPU architecture, 예상 비용과 예산 한도는 `TBD(검증 필요)`다. compute 중지 후에도 저장소와 네트워크 비용이 남을 수 있다.

## 다운로드와 확장 준비

현장 전에 npm registry, 고정 v3 workload/mixin과 Playwright 브라우저 다운로드 경로를 확인한다. exact-host allowlist는 리허설 로그로 확정한다. 일반적인 초기 후보는 `github.com`, `codeload.github.com`, `registry.npmjs.org`이며 모델 endpoint와 Playwright 호스트는 `TBD(검증 필요)`다.

180분 확장에서는 **mixin을 직접 제작**한다. 선택한 source build 경로에 필요한 Docker/Buildx를 사전에 준비한다. published mixin 사용에 host Docker가 불필요하다고 해서 제작에도 불필요한 것은 아니다.

## 통과 기록

| 항목 | 실제 값/결과 | 근거 파일 |
| --- | --- | --- |
| OS와 Copilot 지원 backend | 참가자 작성 | 참가자 작성 |
| Node >=22.13, Git, Copilot, sbx, aca 버전 | 참가자 작성 | 참가자 작성 |
| 본인 모델 요청과 sbx 로컬 microVM 생성 | 참가자 작성 | 참가자 작성 |
| Azure 인증, group, RBAC, image와 quota | 참가자 작성 | 참가자 작성 |
| v3 kit digest와 Playwright 조합 | 참가자 작성 | 참가자 작성 |

토큰, 실제 credential 내용, 구독 ID를 표에 쓰지 않는다. 실패하면 일반 환경 오류인지 미지원인지 먼저 분류하고 조직 정책을 우회하지 않는다.
