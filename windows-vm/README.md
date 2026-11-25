# 선택 사전 준비용 Windows VM

**배포와 실행 미검증.** [참가자 절차](../docs/00-windows-vm.md)를 먼저 읽는다. 설치/접속/재부팅은 150/180분 시간 밖이다.

`azure.yaml`, `infra/`, `hooks/`, `scripts/`만으로 작동하도록 작성한 자립형 azd 템플릿이다. 상위 `shared` 의존, 앱 현대화 도구, PAT와 Azure credential은 포함하지 않는다. ACA 리소스는 생성하지 않는다.

| 구성 | 초안 |
| --- | --- |
| VM | `Standard_D8s_v5`, Windows 11 Enterprise Gen2, 256 GiB Premium SSD |
| 이미지 | publisher `MicrosoftWindowsDesktop`, offer `windows-11`, SKU `win11-26h2-ent` 참고값 |
| 버전 | 기본 `latest`, 선택적으로 고정 숫자 버전 지정. 가용성 `TBD(검증 필요)` |
| 보안 | Trusted Launch, Secure Boot, vTPM 유지 |
| 접속 | VM NIC 공인 IP 없음. Bastion Developer |
| 외부 다운로드 | NAT Gateway와 전용 Standard 공인 IP |
| 자동 종료 | 매일 한국 시간 00:00 할당 취소. 삭제 아님 |
| 도구 전달 | Run Command는 관리자 사용자의 `$HOME\scripts\install-vm-tools.ps1`만 기록 |
| 사용자 설치 | 로그인한 관리자 계정에서 별도 확인 후 실행 |

이미지/SKU/지역/Bastion Developer 가용성, 라이선스 자격과 quota, Windows 업데이트, 비용은 `TBD(검증 필요)`다. Docker 중첩 가상화는 **미검증**이다. Trusted Launch를 Standard로 자동 변경하지 않는다.

## 입력

`azd env`에서 `AZURE_SUBSCRIPTION_ID`, `AZURE_LOCATION`을 준비한다. `AZURE_ENV_NAME`은 전용 azd 환경 이름이다. `confirmWindowsClientLicense`는 기본값 없이 `true`만 허용하는 Bicep의 bool 입력이다. azd에서 입력을 요청하면 Windows 11 클라이언트 Azure 라이선스 자격을 본인이 확인한 경우에만 `true`를 선택한다. 자격이 없거나 확인하지 못했다면 배포를 중단한다. 별도 라이선스 환경 변수는 설정하지 않는다.

preprovision은 필수 환경 변수와 지정한 이미지 버전 형식만 검사하며 Azure 가용성이나 권한을 검사하지 않는다.

선택 입력은 `WORKSHOP_VM_ADMIN_USERNAME`(기본 `workshopuser`), `WORKSHOP_VM_SIZE`, `WORKSHOP_VM_IMAGE_SKU`, `WORKSHOP_VM_IMAGE_VERSION`(기본 `latest`, 고정 숫자 버전도 가능)이다. `latest`는 배포 시점에 따라 달라질 수 있으므로 실제 이미지 버전을 확인해 기록한다. `adminPassword`는 Bicep의 secure 입력이며 parameter 파일에 값을 넣지 않는다. 암호와 PAT를 버전 관리하거나 커맨드 라인/관찰표에 기록하지 않는다.

## 도구 설치 스크립트

WinGet이 없다면 VM에서 Microsoft의 공식 App Installer/WinGet 준비를 먼저 마친다. 전달된 스크립트는 로그인한 사용자 세션에서 관리자 권한으로 실행하며 SYSTEM은 거부한다. Git, GitHub CLI(`GitHub.cli`), PowerShell, Azure CLI, `Docker.sbx`와 Copilot CLI는 WinGet에서 제공하는 최신 버전으로 설치한다. Node.js는 nvm-windows 2.x(`AuthorSoftware.NVMWindows`)를 통해 24.x 최신 버전을 설치한다. nvm-windows 밖에서 설치한 Node.js가 있으면 중단한다. ACA CLI는 공식 설치 스크립트 `https://aka.ms/aca-cli-install-ps`로 최신 버전을 설치한다.

도구 버전 인자는 받지 않는다. 이미 있는 도구는 보존하고 경고하므로 **설치 스크립트 완료가 모든 도구의 최신 상태를 의미하지 않는다**. 필요한 업데이트는 원래 설치 경로로 직접 수행하고 실제 버전을 기록한다. 실제 설치 동작은 미검증이다. 자동 로그인, PAT 저장, 모델 호출과 샌드박스 생성은 하지 않는다.

## 참고와 변경

[`justinyoo/agent-box/appmod-box`](https://github.com/justinyoo/agent-box/tree/18bd8c0ec534c02f83827a7d3917b590cb992ae0/appmod-box), SHA `18bd8c0ec534c02f83827a7d3917b590cb992ae0`의 네트워크/VM/Run Command 전달 방식을 참고했다. 원본 [MIT 고지](LICENSE-UPSTREAM)를 유지한다. 워크숍용으로 리소스 이름과 태그, 이미지 버전 입력, 라이선스 확인, 도구 목록과 설치 전달을 수정했고 `shared` 의존을 없앴다. 원본의 배포 성공을 이번 템플릿의 검증으로 승계하지 않는다.
