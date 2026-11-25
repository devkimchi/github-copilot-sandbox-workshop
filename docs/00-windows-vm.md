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

Run Command는 도구를 자동 설치하지 않는다. 배포 시 지정한 관리자 사용자의 `$HOME\scripts\install-vm-tools.ps1`에 설치 스크립트만 저장한다. 사용자가 아직 로그인하지 않았다면 Default 프로필에 저장하며, 첫 로그인 시 사용자 홈으로 복사된다. 사람이 내용을 검토한 뒤 로그인한 관리자 사용자 세션에서 실행한다. WinGet/App Installer가 없으면 공식 설치 절차로 먼저 준비한다.

```powershell
# Windows VM, 관리자 PowerShell
& "$HOME\scripts\install-vm-tools.ps1"
```

확인 입력 없이 진행하려면 `-Yes`를 추가한다. 이 옵션은 설치와 패키지 사용 조건에 동의한 것으로 간주하므로 내용을 검토한 뒤에만 사용한다.

```powershell
& "$HOME\scripts\install-vm-tools.ps1" -Yes
```

설치 스크립트가 `INSTALL` 확인(또는 `-Yes`) 후 Git, GitHub CLI, PowerShell, Azure CLI, `sbx`, Docker Desktop과 Copilot CLI를 WinGet에서 제공하는 최신 버전으로 설치한다. Docker Desktop보다 먼저 `wsl --install --distribution Ubuntu --no-launch`로 WSL2와 Ubuntu를 설치한다. 설치 후 VM을 재부팅하고, Ubuntu 첫 실행에서 Linux 사용자를 만들고 Docker Desktop 첫 실행에서 약관을 확인한다. Docker Desktop은 `sbx`를 대체하지 않는다. Node.js는 nvm-windows 2.x에서 `nvm install`과 `nvm use`로 24.x 최신 버전을 설치한다. ACA CLI는 공식 설치 스크립트를 사용한다. 기존 도구는 자동 업데이트하지 않으므로 필요하면 원래 설치 경로로 직접 업데이트한다. 실제 설치 동작은 미검증이다.

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
