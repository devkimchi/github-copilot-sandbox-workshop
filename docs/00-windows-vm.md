# 선택 사전 준비: Windows VM

## 1. 목표와 시간

개인 Azure 구독에 실습 HOST를 준비한다. **수업 시간 밖의 선택 절차**이며 모든 명령, 배포, 접속, 설치와 기대 결과는 **미검증**이다. [템플릿 구성](../windows-vm/README.md), [출처](sources.md).

## 2. 실행 위치

배포와 삭제는 **개인 PC**, 설치와 Lab의 HOST 명령은 **Bastion으로 접속한 Windows VM**에서 한다. ACA REMOTE와 DOCKER VM은 Windows HOST와 별개다. Azure VM을 네 번째 샌드박스 제품으로 소개하지 않는다.

## 3. 사전 조건과 현재 상태

Windows 11 클라이언트 Azure 라이선스 자격, 개인 구독 권한, 이미지/SKU와 Bastion Developer의 지역 가용성, quota와 예상 비용을 본인이 먼저 확인한다. 기본 `Standard_D8s_v5`와 SKU `win11-26h2-ent`는 **참고값이지 호환성 보장이나 필수 사양이 아니다**.

개인 PC에 Azure CLI와 azd >=1.35.1을 준비한다. Windows hook은 PowerShell 7, macOS와 Linux hook은 Bash를 사용한다. Windows 이미지 버전은 기본적으로 `latest`를 사용한다. 실제 이미지 버전, OS 업데이트와 모듈 통과 결과는 `TBD(검증 필요)`다.

## 4. 배포, 접속과 설치

아래는 실제 값으로 바꾼 뒤 **별도 실행 승인을 받아** 참가자가 수행할 흐름이다. 현재 자료 제작에서는 실행하지 않는다.

```powershell
# 개인 PC, <WORKSHOP_DIR>
Set-Location .\windows-vm
azd auth login
az login
azd env new <VM_ENV_NAME>
azd env set AZURE_SUBSCRIPTION_ID <본인구독ID>
azd env set AZURE_LOCATION <검증한지역>
azd up --environment <VM_ENV_NAME>
```

azd와 Azure CLI에서 같은 구독을 선택한다. 필요하면 `azd env set WORKSHOP_VM_IMAGE_VERSION <검증한고정숫자버전>`으로 이미지 버전을 고정할 수 있다. `latest`는 배포 시점에 따라 달라질 수 있으므로 실제 이미지 버전을 확인해 기록한다.

리소스 그룹 이름은 `rg-<VM_ENV_NAME>`이다. 이전 버전에서 `rg-<VM_ENV_NAME>-vm` 그룹을 만들었다면 재배포해도 기존 그룹과 자원은 자동으로 삭제되지 않는다. 두 그룹의 자원과 비용을 따로 확인한다.

`confirmWindowsClientLicense`는 기본값 없이 `true`만 허용하는 Bicep의 bool 입력이다. azd에서 입력을 요청하면 Windows 11 클라이언트 Azure 라이선스 자격을 본인이 확인한 경우에만 `true`를 선택한다. 자격이 없거나 확인하지 못했다면 배포를 중단한다. 별도 라이선스 환경 변수는 설정하지 않는다.

`adminPassword`는 azd의 보안 입력에서만 제공하고 셸 명령/파일에 넣지 않는다. preprovision은 필수 환경 변수와 지정한 이미지 버전 형식만 검사한다. 이미지, SKU, 지역별 가용성, 쿼터와 비용은 검사하지 않으므로 `azd up` 실행 전에 본인이 확인한다.

배포 출력의 **VM 이름, 리소스 그룹, 사용자 이름**을 확인한다. Azure portal에서 해당 VM의 **연결 > Bastion**을 선택해 로그인한다. NIC에는 공인 IP가 없으며 outbound 다운로드는 NAT를 사용한다. RDP 포트를 인터넷에 직접 공개하지 않는다.

Run Command는 도구를 자동 설치하지 않는다. 배포 시 지정한 관리자 사용자의 `$HOME\scripts`에 `install-vm-tools.ps1`과 `update-vm-tools.ps1`을 저장한다. 사용자가 아직 로그인하지 않았다면 Default 프로필에 저장하며, 첫 로그인 시 사용자 홈으로 복사된다. 사람이 내용을 검토한 뒤 로그인한 관리자 사용자 세션에서 실행한다. WinGet/App Installer가 없으면 공식 설치 절차로 먼저 준비한다.

```powershell
# Windows VM, 관리자 PowerShell
& "$HOME\scripts\install-vm-tools.ps1"
```

확인 입력 없이 진행하려면 `-Yes`를 추가한다. 이 옵션은 설치와 패키지 사용 조건에 동의한 것으로 간주하므로 내용을 검토한 뒤에만 사용한다.

```powershell
& "$HOME\scripts\install-vm-tools.ps1" -Yes
```

설치 스크립트는 도구를 다음 용도로 나누어 표시하고 이 순서대로 설치한다. 그룹별 선택 설치는 제공하지 않는다. 지원하는 터미널에서 `[INFO]`는 청록색, `[PASS]`는 초록색, `[FAIL]`은 빨간색으로 표시하며 경고는 PowerShell 경고 색상을 사용한다.

| 용도 | 도구 |
| --- | --- |
| 공통 개발 환경 | Git, GitHub CLI, nvm-windows, PowerShell, Node.js |
| Copilot CLI 샌드박스 | Copilot CLI |
| Azure Container Apps Sandboxes | Azure CLI, ACA CLI |
| Docker Sandboxes | 선택 사항인 Windows Hypervisor Platform, `sbx` |
| Docker Desktop 및 Linux 개발 환경 | WSL2, Ubuntu, Docker Desktop |

`INSTALL` 확인(또는 `-Yes`) 후 WinGet 패키지는 제공되는 최신 버전으로 설치한다. Node.js는 nvm-windows 2.x에서 `nvm install`과 `nvm use`로 24.x 최신 버전을 설치한다. ACA CLI는 PowerShell과 Azure CLI를 준비한 뒤 공식 설치 스크립트로 설치한다. Docker Desktop보다 먼저 `wsl --install --distribution Ubuntu --no-launch`로 WSL2와 Ubuntu를 설치한다. Ubuntu가 WSL1이면 WSL2로 전환한다. WSL 구성 요소가 재부팅을 기다리면 스크립트는 경고와 함께 종료 코드 `3010`으로 중단한다. 재부팅하고 Ubuntu 첫 실행을 마친 뒤 스크립트를 다시 실행한다. Ubuntu 패키지는 설치됐지만 첫 실행 전이라 WSL 배포판으로 등록되지 않았으면 경고와 함께 종료 코드 `2`로 중단한다. 시작 메뉴에서 Ubuntu를 열거나 `ubuntu.exe`를 실행해 Linux 사용자를 만든 뒤 스크립트를 다시 실행한다. 재부팅 대기 상태가 아닌데 WSL 조회나 전환이 실패하면 오류를 확인한다. 설치 후에도 필요한 재부팅을 하고 Docker Desktop 첫 실행에서 약관을 확인한다. 기존 도구는 자동 업데이트하지 않으므로 필요하면 원래 설치 경로로 직접 업데이트한다. 실제 설치 동작은 미검증이다.

[`sbx`는 Docker Desktop 없이 사용할 수 있고](https://docs.docker.com/ai/sandboxes/install/), [Docker Desktop의 WSL2 백엔드는 별도 Ubuntu 배포판을 필수로 요구하지 않는다](https://docs.docker.com/desktop/features/wsl/). 이 스크립트는 선택한 실습 구성에 맞춰 Ubuntu도 설치한다. [Docker Desktop의 Azure VM 공식 지원](https://docs.docker.com/desktop/setup/vm-vdi/)은 Docker Business 고객 대상이며 로컬 VM 사용 시 중첩 가상화가 필요하다.

Windows Hypervisor Platform은 기본 자동 변경하지 않는다. 승인된 중첩 가상화 조합을 리허설한 뒤에만 `-EnableHypervisorPlatform`을 추가한다. 필요 시 사람이 재부팅한다. Trusted Launch, Secure Boot와 vTPM을 낮추는 옵션은 제공하지 않는다.

VM에서 개인 워크숍 저장소를 별도로 클론하고 Lab 0을 진행한다. PAT/자격 증명은 도구의 보안 입력 흐름으로 **각자** 준비한다. VM 이미지나 Bicep에 넣지 않는다.

## 5. 모듈별 관찰 항목

| 모듈 | 통과 조건(모두 미검증) | 통과하지 못하면 |
| --- | --- | --- |
| Copilot 자체 샌드박스 | 실제 Windows build/업데이트 요구 충족, status와 같은 OFF/ON probe에서 정책 차이 | 지원 개인 PC 또는 강사 실제 기록, 미지원 표시 |
| Docker Lab 2/2B | 승인된 SKU/이미지/보안 조합에서 실제 sbx 로컬 microVM과 v3 workload/mixin 시작 | 개인 PC에서 해당 모듈 진행 |
| ACA | VM은 제어 단말, 본인 인증/RBAC, `aca doctor`, remote shell 성공 | 본인 권한과 일반 환경 진단 |

중첩 가상화 안내가 Standard 보안 유형을 명시하는 반면 참고 템플릿은 Trusted Launch를 사용한다. 따라서 **Docker Desktop이나 WSL2 실행만으로 Docker 모듈 통과라고 하지 않는다**. 검증 전에 보안 유형을 임의 변경하지 않는다.

## 6. 기대와 실제 결과

| 항목 | 기대 결과(미검증) | 실제/근거 |
| --- | --- | --- |
| azd/VM/Bastion | 본인 전용 환경 생성과 접속 | 참가자 작성 |
| 설치 스크립트 | 전달과 실제 사용자 설치를 구분 | 참가자 작성 |
| OS/tool version과 모듈 | 모듈별로 독립 판정 | 참가자 작성 |
| 삭제 | VM 전용 리소스와 비용 잔존 확인 | 참가자 작성 |

## 7. 실패가 정상인 경우

라이선스 자격을 확인하지 못했다면 배포를 중단한다. 필수 환경 변수 누락과 잘못된 이미지 버전은 hook의 의도된 중단 조건이다. 지역/SKU/이미지 미가용, quota와 Bastion 미지원은 일반 Azure 준비 오류다. Docker 중첩 가상화 미지원이면 개인 PC 경로를 사용하며 보안 설정 우회로 해결하지 않는다.

## 8. 복구

설치 스크립트를 갱신하려면 VM에서 `update-vm-tools.ps1`을 실행한다. `-CommitSha`에는 이 저장소의 수정본이 포함된 전체 40자리 커밋 SHA를 지정한다. 브랜치 이름과 축약 SHA는 받지 않는다.

```powershell
# PowerShell
& "$HOME\scripts\update-vm-tools.ps1" -CommitSha '<40자리 커밋 SHA>'
```

갱신 스크립트는 같은 폴더의 `install-vm-tools.ps1`을 `install-vm-tools.ps1.<타임스탬프>`로 백업한다. 타임스탬프는 `yyyyMMdd-HHmmss` 형식이다. 같은 이름의 백업이 이미 있으면 덮어쓰지 않고 중단한다. 지정한 커밋에서 다운로드한 파일이 비어 있지 않고 PowerShell 구문 검사를 통과하면 UTF-8 BOM으로 저장해 교체한다. 다운로드나 구문 검사가 실패하면 기존 파일을 유지한다. 갱신 후 설치는 자동 실행하지 않으므로 내용을 검토한 뒤 별도로 실행한다. 이 갱신 스크립트의 실제 VM 동작은 미검증이다.

Node.js 설치 후 `npm.cmd`를 찾지 못해 중단됐다면 위 절차로 수정본을 받아 다시 실행한다. 설치 스크립트는 확장자를 지정하지 않고 npm을 찾아 실행하므로 nvm-windows 2.x의 `npm.exe` shim도 지원한다. 실제 VM에서 재실행한 결과는 미검증이다.

실패한 배포의 잔존 자원과 정확한 환경을 먼저 확인한다. 다른 사람의 VM/group을 재사용하거나 공유 토큰을 배포하지 않는다. 수업 시작 후 설치/재부팅을 수업 시간에 밀어 넣지 않는다. 미통과 모듈은 직접 수행과 구분해 기록한다.

## 9. 결과 회수와 정리

VM에만 있는 코드와 `evidence/`를 물리 PC로 먼저 회수하고 파일을 확인한다. **배포했던 PC**, `windows-vm` 폴더에서 같은 구독과 환경 이름을 확인한 뒤:

```powershell
azd env select <VM_ENV_NAME>
azd env get-value AZURE_RESOURCE_GROUP
azd env get-value AZURE_VM_NAME
azd down --environment <VM_ENV_NAME>
```

확인 화면에서 본인 VM 전용 환경인지 다시 확인한다. ACA sandbox는 별도 정리 대상이다. 한국 시간 매일 00:00 자동 종료는 할당 취소이지 삭제가 아니다. VM 디스크, NAT Gateway와 공인 IP 등 비용 자원이 남지 않았는지 portal에서 확인하고 실제 결과를 관찰표에 적는다.
