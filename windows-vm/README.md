# 실습용 Windows VM 준비

개인 PC 대신 사용할 Windows VM을 Azure에 만든다. VM 준비는 실습 시간에 포함되지 않는다.

## VM 기본 구성

| 항목 | 기본값 |
| --- | --- |
| VM 크기 | `Standard_D8s_v5` |
| 운영체제 | Windows 11 Enterprise Gen2 (`win11-26h2-ent`) |
| 이미지 버전 | 배포 시점의 최신 버전(`latest`) |
| OS 디스크 | 256 GiB Premium SSD |
| 관리자 계정 | `workshopuser` |
| 보안 | Trusted Launch, Secure Boot, vTPM |
| 접속 | Azure Bastion Developer. VM에 공인 IP를 할당하지 않음 |
| 외부 통신 | NAT Gateway와 전용 Standard 공인 IP |
| 자동 종료 | 매일 한국 시간 00:00에 할당 취소. 자원은 삭제하지 않음 |

## azd CLI로 VM 프로비저닝

개인 PC에 azd 1.35.1 이상을 설치한다. 배포 훅을 실행하려면 Windows에서는 PowerShell 7, macOS와 Linux에서는 Bash가 필요하다. Windows 11의 Azure 사용 라이선스 자격, 구독 권한, 배포 지역의 VM 크기와 Bastion 가용성, 할당량과 비용을 먼저 확인한다.

개인 PC의 저장소 루트에서 다음 명령을 실행한다. `<...>`는 사용할 값으로 바꾼다.

```powershell
Set-Location ./windows-vm
azd auth login
azd env new <VM_ENV_NAME>
azd env set AZURE_SUBSCRIPTION_ID <구독ID>
azd env set AZURE_LOCATION <배포지역>
azd up
```

VM 자원만 프로비저닝하려면 `azd up` 대신 다음 명령을 사용한다.

```powershell
azd provision
```

Windows 라이선스 확인과 관리자 암호를 요청하면 안내에 따라 입력한다. 라이선스 자격을 확인한 경우에만 `true`를 선택하고, 암호는 명령이나 파일에 저장하지 않는다.

배포가 끝나면 Azure Portal에서 해당 VM의 **연결 > Bastion**을 선택한다. 기본 관리자 계정은 `workshopuser`이며, 암호는 배포할 때 입력한 값을 사용한다.

## VM에서 도구 설치

VM에 로그인한 뒤 **관리자 권한으로 PowerShell**을 연다. WinGet이 없다면 Microsoft의 공식 App Installer/WinGet 설치 절차로 먼저 준비한다.

다음 명령을 실행하고 내용을 확인한 뒤 `INSTALL`을 입력한다.

```powershell
& "$HOME\scripts\install-vm-tools.ps1"
```

설치 내용과 패키지 사용 조건을 확인했다면 `-Yes`로 확인 입력을 생략할 수 있다.

```powershell
& "$HOME\scripts\install-vm-tools.ps1" -Yes
```

스크립트는 Git, GitHub CLI, nvm-windows, PowerShell, Node.js, Copilot CLI, Azure CLI, ACA CLI, Docker Sandboxes, WSL2, Ubuntu와 Docker Desktop을 설치한다. 이미 설치된 도구는 유지한다.

재부팅 안내가 나오면 Windows를 재부팅하고 같은 명령을 다시 실행한다. Ubuntu 첫 실행 안내가 나오면 Ubuntu를 열어 Linux 사용자를 만든 뒤 다시 실행한다. 설치가 끝나면 Docker Desktop을 처음 실행해 약관을 확인하고 초기 설정을 마친다. GitHub, Copilot CLI, Azure, Docker 샌드박스 인증은 각 도구에서 직접 진행한다.

이 템플릿은 [`justinyoo/agent-box/appmod-box`](https://github.com/justinyoo/agent-box/tree/18bd8c0ec534c02f83827a7d3917b590cb992ae0/appmod-box), SHA `18bd8c0ec534c02f83827a7d3917b590cb992ae0`의 네트워크, VM과 스크립트 전달 구성을 참고해 워크숍에 맞게 수정했다.
