# 실습용 Windows VM 준비

개인 PC 대신 사용할 Windows VM을 Azure에 만든다.

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

## 사전 준비 사항

- [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)
- Windows: [PowerShell 7](https://learn.microsoft.com/powershell/scripting/install/install-powershell-on-windows)

## Windows VM 프로비저닝

아래 명령어를 실행시켜 Windows VM을 Azure에 프로비저닝한다.

```bash
cd ./windows-vm
azd auth login
azd up
```

프롬프트를 따라 필요한 정보를 입력한다.

## Windows VM 도구 설치

배포가 끝나면 Azure Portal에서 해당 VM의 **연결 > Bastion**을 선택한다. 기본 관리자 계정은 `workshopuser`이며, 암호는 배포할 때 입력한 값을 사용한다.

VM에 로그인한 뒤 **관리자 권한으로 PowerShell**을 열고 아래 스크립트를 실행한다.

```powershell
& "$HOME/scripts/install-vm-tools.ps1"
```

또는 `-Yes` 스위치를 이용해 확인 절차 없이 바로 실행한다.

```powershell
& "$HOME/scripts/install-vm-tools.ps1" -Yes
```

설치 과정에서 Windows VM을 몇차례 재부팅할 수 있다. 화면 지시에 따라 재부팅하고 다시 `install-vm-tools.ps1` 스크립트를 실행한다.

### 설치 도구 목록

스크립트는 다음 도구를 순서대로 설치한다.

| 그룹 | 도구 및 구성 요소 |
| --- | --- |
| 공통 개발 환경 | Git, GitHub CLI, nvm-windows, PowerShell, Node.js 24.x |
| Copilot CLI | Copilot CLI |
| Azure Container Apps Sandboxes | Azure CLI, ACA CLI |
| Docker Sandboxes | Windows Hypervisor Platform (`-EnableHypervisorPlatform` 지정 시 활성화), `sbx` (Docker Sandboxes CLI) |
| Docker Desktop 및 Linux 개발 환경 | WSL2, Ubuntu, Docker Desktop |

설치가 끝난 후 아래 명령어를 실행시켜 설치된 도구를 확인한다.

```powreshell
git --version
gh --version
pwsh --version
nvm --version
node --version
npm --version
copilot --version
az --version
aca --version
sbx --version
wsl --version
docker --version
```
