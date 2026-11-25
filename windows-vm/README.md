# 선택 사전 준비용 Windows VM

**배포와 실행 미검증.** [참가자 절차](../docs/00-windows-vm.md)를 먼저 읽는다. 설치/접속/재부팅은 150/180분 시간 밖이다.

`azure.yaml`, `infra/`, `hooks/`, `scripts/`만으로 작동하도록 작성한 자립형 azd 템플릿이다. 상위 `shared` 의존, 앱 현대화 도구, PAT와 Azure credential은 포함하지 않는다. ACA 리소스는 생성하지 않는다.

| 구성 | 초안 |
| --- | --- |
| VM | `Standard_D8s_v5`, Windows 11 Enterprise Gen2, 256 GiB Premium SSD |
| 이미지 | publisher `MicrosoftWindowsDesktop`, offer `windows-11`, SKU `win11-26h2-ent` 참고값 |
| 버전 | 고정 숫자 이미지 버전을 사용자가 확인해 입력. `TBD(검증 필요)` |
| 보안 | Trusted Launch, Secure Boot, vTPM 유지 |
| 접속 | VM NIC 공인 IP 없음. Bastion Developer |
| 외부 다운로드 | NAT Gateway와 전용 Standard 공인 IP |
| 자동 종료 | 매일 한국 시간 00:00 할당 취소. 삭제 아님 |
| 도구 전달 | Run Command는 `C:\WorkshopSetup\install-tools.ps1`만 기록 |
| 사용자 설치 | 로그인한 관리자 계정에서 별도 확인 후 실행 |

이미지/SKU/지역/Bastion Developer 가용성, 라이선스 자격과 quota, Windows 업데이트, 비용은 `TBD(검증 필요)`다. Docker 중첩 가상화는 **미검증**이다. Trusted Launch를 Standard로 자동 변경하지 않는다.

## 입력

`azd env`에서 `AZURE_SUBSCRIPTION_ID`, `AZURE_LOCATION`, `WORKSHOP_VM_IMAGE_VERSION`, `WORKSHOP_CONFIRM_WINDOWS_LICENSE=true`를 준비한다. `AZURE_ENV_NAME`은 전용 azd 환경 이름이다. preprovision은 값 존재와 고정 버전 형식, 사용자 확인만 검사하며 Azure 가용성이나 권한을 검사하지 않는다.

선택 입력은 `WORKSHOP_VM_ADMIN_USERNAME`(기본 `workshopuser`), `WORKSHOP_VM_SIZE`, `WORKSHOP_VM_IMAGE_SKU`다. `adminPassword`는 Bicep의 secure 입력이며 parameter 파일에 값을 넣지 않는다. 암호와 PAT를 버전 관리하거나 커맨드 라인/관찰표에 기록하지 않는다.

## 도구 설치 스크립트

WinGet이 없다면 VM에서 Microsoft의 공식 App Installer/WinGet 준비를 먼저 마친다. 전달된 스크립트는 로그인한 사용자 세션에서 관리자 권한으로 실행하며 SYSTEM은 거부한다. Git, Node.js >=22.13, PowerShell 7, Azure CLI, `Docker.sbx`와 Copilot CLI만 대상으로 한다. ACA는 공식 배포처에서 받은 Windows `aca.exe`와 검증한 SHA-256을 입력받아 사용자 도구 폴더에 복사한다.

각 버전 인자는 필수다. 미확정 값을 latest로 바꾸지 않는다. 이미 있는 도구는 보존하고 경고하므로 **설치 스크립트 완료가 버전 일치를 의미하지 않는다**. 실제 `--version`을 검증표와 비교하고 불일치하면 사람이 승인한 설치 경로로 조정한다. 자동 로그인, PAT 저장, 모델 호출과 샌드박스 생성은 하지 않는다.

## 참고와 변경

[`justinyoo/agent-box/appmod-box`](https://github.com/justinyoo/agent-box/tree/18bd8c0ec534c02f83827a7d3917b590cb992ae0/appmod-box), SHA `18bd8c0ec534c02f83827a7d3917b590cb992ae0`의 네트워크/VM/Run Command 전달 방식을 참고했다. 원본 [MIT 고지](LICENSE-UPSTREAM)를 유지한다. 워크숍용으로 리소스 이름과 태그, 고정 이미지 입력, 라이선스 확인, 도구 목록과 설치 전달을 수정했고 `shared` 의존을 없앴다. 원본의 배포 성공을 이번 템플릿의 검증으로 승계하지 않는다.
