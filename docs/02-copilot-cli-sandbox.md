# Copilot CLI 샌드박스

## 목표

같은 파일 접근 명령을 Copilot CLI 샌드박스를 끈 상태, 켠 상태와 최소 권한을 부여한 상태에서 실행해 결과를 비교한다. 네트워크와 개발 도구의 실행 결과도 정책과 함께 확인하고 기록한다.

**이 문서의 모든 명령과 기대 결과는 미검증**이다. 강사 리허설 후에만 배포본으로 사용한다. [출처](sources.md), [개요](../README.md).

## 실행 위치

실습 준비와 실행 기록 보관은 **HOST**에서, 접근 제한 확인과 과제 실행은 **COPILOT CLI가 호출한 도구**에서 한다. HOST의 실행 결과만으로 샌드박스 차단을 판정하지 않는다.

## 실습 준비와 실행 전 상태 확인

### 준비 상태 확인

저장소 루트(`<REPOSITORY_ROOT>`)의 `workspace/`는 실습용 앱이 있는 워크스페이스다.

Git, Node.js 24.x, Copilot CLI가 설치되어 있는지 확인한다.

```bash
git --version
node --version
copilot --version
```

### 실습 파일과 기록 폴더 준비

파일 읽기 시험에 사용할 `workspace/.env`를 만들고 관찰 기록 폴더를 준비한다. **HOST**의 **저장소 루트**에서 실행한다.

```bash
# zsh/bash
mkdir -p evidence/setup evidence/copilot-cli
if [ ! -e evidence/observation.md ]; then
  cp evidence-template/observation.md evidence/observation.md
fi
printf '%s\n' 'WORKSHOP_DUMMY=not-a-secret' > workspace/.env
```

```powershell
# PowerShell
New-Item -ItemType Directory -Path ./evidence/setup,./evidence/copilot-cli -Force | Out-Null
if (-not (Test-Path ./evidence/observation.md)) {
  Copy-Item ./evidence-template/observation.md ./evidence/observation.md
}
Set-Content ./workspace/.env 'WORKSHOP_DUMMY=not-a-secret'
```

각 실험의 결과는 `evidence/observation.md`에 기록한다.

### 외부 확인용 파일과 시작 상태 기록

샌드박스 밖의 파일에 접근할 수 있는지 시험하려고 교육용 확인 파일(canary)을 만든다. 이 파일은 OS 임시 폴더나 부모 저장소 안에 두지 않는다. 임시 폴더와 저장소 전체에 자동으로 부여되는 읽기 권한 때문에 실험이 무효가 될 수 있다. 다음 예시 경로가 이미 존재하면 덮어쓰지 말고 다른 교육용 경로를 선택한다.

HOST에서 확인용 파일을 만들고, 실습 전 파일 해시와 Git 상태를 `evidence/setup/`에 저장한다. 아래 bash 예시의 `/home/<user>/SandboxCanary`는 실제로 사용할 수 있는 외부 절대 경로로 바꾼다. 이 기록은 이후 변경 여부를 비교하는 데 사용한다.

```bash
# zsh/bash
CANARY_DIR="/home/<user>/SandboxCanary"
if [ -e "$CANARY_DIR" ]; then
  printf '%s\n' "$CANARY_DIR already exists; choose another training path." >&2
  exit 1
fi
mkdir "$CANARY_DIR"
printf '%s\n' 'WORKSHOP_CANARY=not-a-secret' > "$CANARY_DIR/read.txt"
printf '%s\n' 'before' > "$CANARY_DIR/write.txt"
cat "$CANARY_DIR/read.txt"
shasum -a 256 "$CANARY_DIR/write.txt" > evidence/setup/canary-before.txt
git -C workspace status --short > evidence/setup/git-before.txt
git -C workspace rev-parse baseline > evidence/setup/baseline.txt
git -C workspace remote -v > evidence/setup/remotes.txt
git status --short --ignored > evidence/setup/outer-status.txt
```

```powershell
# PowerShell
# HOST, 기존 폴더이면 중단하고 다른 교육용 경로를 선택한다.
New-Item -ItemType Directory C:/SandboxCanary -ErrorAction Stop
Set-Content C:/SandboxCanary/read.txt 'WORKSHOP_CANARY=not-a-secret'
Set-Content C:/SandboxCanary/write.txt 'before'
Get-Content C:/SandboxCanary/read.txt
Get-FileHash C:/SandboxCanary/write.txt |
  Out-File ./evidence/setup/canary-before.txt
git -C ./workspace status --short |
  Out-File ./evidence/setup/git-before.txt
git -C ./workspace rev-parse baseline |
  Out-File ./evidence/setup/baseline.txt
git -C ./workspace remote -v |
  Out-File ./evidence/setup/remotes.txt
git status --short --ignored |
  Out-File ./evidence/setup/outer-status.txt
```

`baseline.txt`에서 기준 커밋을 확인하고 `remotes.txt`에 원격 저장소가 없는지 확인한다. `git-before.txt`와 `outer-status.txt`는 나중에 변경 사항과 비교할 수 있도록 보관한다.

`workspace`에서 가장 가까운 Git 루트만 저장소(repository) 범위로 판단하는지는 미확인이다. 샌드박스를 켠 상태에서 부모의 `checkpoints/`가 읽히면 강사에게 알린다. **과제 해결을 위해 체크포인트나 완성 예시를 Copilot에 읽히지 않는다.** 프롬프트에서 읽지 말라고 지시하는 것만으로는 접근을 차단할 수 없다.

### HOST에서 의존성 설치와 단위 테스트

샌드박스 실험 전에 HOST에서 의존성을 설치하고 단위 테스트를 실행한다. 각 명령 직후 표시한 종료 코드를 관찰표에 기록한다.

```bash
# zsh/bash
set -o pipefail
cd workspace
npm ci 2>&1 | tee ../evidence/setup/npm-ci.txt
status=$?
printf '%s\n' "$status"
cd ..
```

```powershell
# PowerShell
Push-Location ./workspace
npm ci 2>&1 | Tee-Object ../evidence/setup/npm-ci.txt
$LASTEXITCODE
Pop-Location
```

종료 코드를 기록한다. 0이 아니면 단위 테스트로 넘어가지 말고 오류를 기록한 뒤 일반 실행 환경을 확인한다. 성공했다면 다음 명령을 실행한다.

```bash
# zsh/bash
set -o pipefail
cd workspace
npm run test:unit 2>&1 | tee ../evidence/setup/unit.txt
status=$?
printf '%s\n' "$status"
cd ..
```

```powershell
# PowerShell
Push-Location ./workspace
npm run test:unit 2>&1 | Tee-Object ../evidence/setup/unit.txt
$LASTEXITCODE
Pop-Location
```

단위 테스트가 실패하면 오류와 종료 코드를 기록하고 일반 실행 환경부터 확인한다. `.env`가 Git에서 무시되어도 파일은 존재하고 읽힐 수 있다.

## 샌드박스 상태와 접근 권한 비교

### 샌드박스를 끈 상태에서 실행

샌드박스를 끈 상태의 결과를 이후 켠 상태의 결과와 비교한다. HOST의 저장소 루트에서 기록을 시작하고 `workspace`로 이동해 새 Copilot CLI 세션을 연다. 세션 기록에는 토큰을 입력하지 않는다.

```bash
# zsh/bash
script -q -c 'cd workspace && copilot --no-sandbox' evidence/copilot-cli/off-transcript.txt
```

```powershell
# PowerShell
Start-Transcript -Path ./evidence/copilot-cli/off-transcript.txt -NoClobber
Set-Location ./workspace
copilot --no-sandbox
Stop-Transcript
Set-Location ..
```

CLI에서 `/sandbox status`를 확인해 실제 상태를 기록한다. 조직의 관리 정책이 샌드박스 해제를 금지하면 우회하지 않고 해당 비교를 미지원 또는 정책 제한으로 기록한다. 샌드박스를 끈 세션을 실행할 수 있으면 다음 **각 명령을 CLI의 셸 도구로 정확히 실행**하도록 요청한다. 도구 실행은 사람이 필요한 범위만 승인한다. HOST에서 `--yolo`는 사용하지 않는다.

```bash
# zsh/bash
node -e "console.log(require('node:fs').readFileSync('.env','utf8'))"
node -e "require('node:fs').writeFileSync('__workshop-inside.txt','inside')"
node -e "console.log(require('node:fs').readFileSync('/home/<user>/SandboxCanary/read.txt','utf8'))"
node -e "require('node:fs').writeFileSync('/home/<user>/SandboxCanary/write.txt','after')"
```

```powershell
# PowerShell
node -e "console.log(require('node:fs').readFileSync('.env','utf8'))"
node -e "require('node:fs').writeFileSync('__workshop-inside.txt','inside')"
node -e "console.log(require('node:fs').readFileSync('C:/SandboxCanary/read.txt','utf8'))"
node -e "require('node:fs').writeFileSync('C:/SandboxCanary/write.txt','after')"
```

앞의 두 명령은 `workspace` 안의 교육용 파일 읽기와 쓰기를, 뒤의 두 명령은 외부 확인용 파일 읽기와 쓰기를 시험한다. 각 명령의 도구 호출, 승인 여부, 실제 출력과 종료 코드를 관찰표에 기록한다. bash 예시의 `/home/<user>/SandboxCanary`와 PowerShell 예시의 `C:/SandboxCanary`는 각각 실제로 사용할 외부 교육용 절대 경로로 바꾼다. 샌드박스를 끄고 켰을 때 같은 경로를 쓴다.

세션을 종료한 뒤 CLI를 시작한 HOST 터미널에서 기록을 종료하고 저장소 루트로 돌아간다. 확인용 파일의 해시를 저장해 쓰기 명령을 실행한 뒤의 상태를 남긴다.

```bash
# zsh/bash
shasum -a 256 "/home/<user>/SandboxCanary/write.txt" > evidence/copilot-cli/canary-after-off.txt
```

```powershell
# PowerShell
Get-FileHash C:/SandboxCanary/write.txt | Out-File ./evidence/copilot-cli/canary-after-off.txt
```

세션 기록에 CLI 화면이 완전히 남지 않으면 실제 도구의 표준 출력, 표준 오류와 정책 화면을 별도 텍스트로 저장하고 빠진 부분을 표시한다. 모델이 작성한 설명으로 빈 실행 기록을 채우지 않는다.

### 샌드박스를 켠 상태에서 같은 명령 반복

HOST의 저장소 루트에서 확인용 파일 `write.txt`를 `before`로 되돌리고 해시를 저장한다. 샌드박스를 끈 상태의 결과는 앞 단계에서 보존했으므로, 같은 시작 상태에서 결과를 비교할 수 있다. `__workshop-inside.txt`는 다음 시험에서 같은 내용으로 덮어써도 된다.

```bash
# zsh/bash
printf '%s\n' 'before' > "/home/<user>/SandboxCanary/write.txt"
shasum -a 256 "/home/<user>/SandboxCanary/write.txt" > evidence/copilot-cli/canary-before-on.txt
script -q -c 'cd workspace && copilot --sandbox' evidence/copilot-cli/on-transcript.txt
```

```powershell
# PowerShell
# HOST, <REPOSITORY_ROOT>
Set-Content C:/SandboxCanary/write.txt 'before'
Get-FileHash C:/SandboxCanary/write.txt | Out-File ./evidence/copilot-cli/canary-before-on.txt
Start-Transcript -Path ./evidence/copilot-cli/on-transcript.txt -NoClobber
Set-Location ./workspace
copilot --sandbox
Stop-Transcript
Set-Location ..
```

CLI에서 다음 상태와 설정을 확인해 기록한다. `Allow sandbox bypass`를 끄거나 우회 실행 승인을 거부한 뒤 샌드박스를 끈 상태에서 실행한 네 명령을 **동일한 도구**로 반복한다.

```text
/sandbox status
/sandbox policy
/sandbox config
```

각 결과를 샌드박스를 끈 상태의 출력과 비교한다. CLI 세션을 유지한 채 다른 HOST 터미널을 저장소 루트에서 열고 다음 명령으로 확인용 파일의 해시를 저장한다. 이 해시를 시작 해시와 비교해 관찰표에 기록한다.

```bash
# zsh/bash
shasum -a 256 "/home/<user>/SandboxCanary/write.txt" > evidence/copilot-cli/canary-after-on.txt
```

```powershell
# PowerShell
# HOST, <REPOSITORY_ROOT>
Get-FileHash C:/SandboxCanary/write.txt | Out-File ./evidence/copilot-cli/canary-after-on.txt
```

`/sandbox policy npm ci`, `/sandbox policy npm run test:e2e`는 정책에 따른 처리 결과를 예측할 뿐 실제 실행 기록은 아니다.

### 필요한 범위만 권한 부여

외부 파일에 부여한 권한에 따라 결과가 달라지는지 확인한다. 다음 단계마다 실제 도구 출력과 종료 코드, 적용 중인 정책, 확인용 파일의 전후 해시를 관찰표에 기록한다.

각 시험 전에 다른 HOST 터미널에서 다음 명령으로 확인용 파일 `write.txt`를 `before`로 되돌리고 시작 해시를 관찰표에 기록한다. 시험 후에는 `Get-FileHash`를 다시 실행해 종료 해시를 기록한다. 다음 시험을 위해 되돌리기 전에 직전 결과와 해시를 보존한다.

```bash
# zsh/bash
printf '%s\n' 'before' > "/home/<user>/SandboxCanary/write.txt"
shasum -a 256 "/home/<user>/SandboxCanary/write.txt"
```

```powershell
# PowerShell
# HOST, <REPOSITORY_ROOT>
Set-Content C:/SandboxCanary/write.txt 'before'
Get-FileHash C:/SandboxCanary/write.txt
```

1. `/sandbox config`에서 정확한 UI 표기를 확인하고 외부 확인용 폴더 하나만 읽기 전용(Read-Only)으로 허용한다.
2. `/sandbox policy` 화면을 원본 기록으로 저장하고 샌드박스를 끈 상태에서 실행한 외부 확인용 파일 읽기와 쓰기 명령을 반복한다. 읽기와 쓰기가 각각 어떻게 처리됐는지 샌드박스를 켠 상태의 결과와 비교한다.
3. 쓰기가 필요한 교육용 파일 또는 폴더에만 읽기와 쓰기(Read/Write) 권한을 부여한다. 적용 중인 정책 화면을 다시 저장하고 같은 읽기와 쓰기 명령을 반복한다.

UI 메뉴와 OS별 지원은 `TBD(검증 필요)`이므로 설정할 수 없으면 추측하지 말고 그 상태를 기록한다.

명시적으로 `Denied`를 설정하는 실험에는 **이미 존재하는** 교육용 파일만 쓴다. `Denied`가 허용 규칙보다 우선하므로 교육용 차단 규칙을 제거한 뒤 허용 권한을 설정한다. 존재하지 않는 차단 경로가 디렉터리로 생성될 수 있다는 공식 주의사항을 확인한다.

### 네트워크와 개발 도구 확인

파일 접근과 별도로 네트워크 요청의 결과를 살펴본다. CLI 도구에서 `curl -I https://example.com`을 실행하고 출력과 종료 코드를 남긴다(Windows에서는 `curl.exe`). `example.com`만 차단한 뒤 같은 명령을 반복하고 적용 중인 정책과 결과를 기록해 비교한다. 파일이나 확인용 파일의 내용을 전송하지 않는다. 모델 API 전체를 막지 않는다.

그다음 CLI에 `npm run test:unit`, `npm run build`, `npm run test:e2e`를 순서대로 실행하도록 요청하고 각 출력과 종료 코드를 기록한다. 종단 간 테스트(E2E)가 실패하면 브라우저 미설치, 캐시 접근 차단, localhost 차단, 일반 빌드 오류 등 확인된 원인을 기록한다. 근거가 부족하면 미확정으로 남긴다. Windows의 `Allow local network`는 프록시, 자격 증명 마스킹과 사설 네트워크 접근에 영향을 줄 수 있다. 한 `curl` 실행 결과만으로 모든 프로그램의 접근이 차단된다고 판단하지 않는다.

### 공통 과제 실행

앞에서 확인한 정책이 실제 코딩 작업에 어떤 영향을 주는지 관찰한다. 사람이 [05번 과제](../tasks/05-catalog-summary.md)의 `BEGIN ORIGINAL`과 `END ORIGINAL` 사이 원문을 준비해 아래 프롬프트 뒤에 그대로 붙이고 CLI에 요청한다. 구현 완료 여부와 테스트 결과를 기록하며, 접근 허용과 차단 결과 관찰을 우선한다. 진행하지 못하면 그 상태를 기록하고 강사에게 복구 경로를 확인한다.

```text
아래 과제 원문의 수락 조건을 구현한다. npm run test:unit을 실행하고 결과와
변경 요약을 앱 루트의 evidence/summary.md에 남긴다. 지정 workspace 밖을
변경하지 않는다. checkpoints나 완성 예시는 읽지 않는다.
원격 push, PR 작성, 앱 배포는 하지 않는다.
[사람이 tasks/05-catalog-summary.md의 원문 부분만 여기에 붙인다]
```

### 변경 사항과 실행 기록 보관

CLI 세션을 종료한 뒤 CLI를 시작한 HOST 터미널에서 세션 기록을 종료하고 저장소 루트로 돌아간다. 다음 명령으로 앱의 변경 사항과 확인용 파일의 최종 해시를 저장한다.

```bash
# zsh/bash
git -C workspace status --short > evidence/copilot-cli/git-after.txt
git -C workspace diff --binary --output=../evidence/copilot-cli/changes.patch
shasum -a 256 "/home/<user>/SandboxCanary/write.txt" > evidence/copilot-cli/canary-after.txt
```

```powershell
# PowerShell
git -C ./workspace status --short | Out-File ./evidence/copilot-cli/git-after.txt
git -C ./workspace diff --binary --output=../evidence/copilot-cli/changes.patch
Get-FileHash C:/SandboxCanary/write.txt | Out-File ./evidence/copilot-cli/canary-after.txt
```

`--output`은 Git의 `-C` 기준 상대 경로다. `changes.patch`에는 추적되지 않은 새 파일이 포함되지 않으므로 `git-after.txt`에서도 새 파일을 확인하고 필요한 내용은 별도로 보존한다. 시작 상태와 최종 상태를 비교하고 실행 기록에 비밀이 없는지 사람이 검토한다.

## 관찰 결과 정리

각 실험을 마칠 때마다 아래 명령의 플레이스홀더를 실제 정보로 바꿔 실행한다. 명령은 `evidence/observation.md`의 `Lab별 관찰` 표에 한 행을 덧붙인다. OS와 CLI 버전, 시작 작업 디렉터리, 기준 커밋과 샌드박스 상태는 `환경과 원자료`에 기록하고, 각 행에는 실행 위치와 정확한 명령, 미검증 기대 결과, 실제 승인과 정책, 표준 출력과 표준 오류, 종료 코드, 파일 hash 또는 diff, 근거 파일 경로와 판정 이유를 적는다. 표 안에 들어가는 명령에 `|`가 있으면 `\|`로 바꾼다. 시간 초과나 미실행은 그대로 표시하고 성공으로 적지 않는다. 비밀, 토큰, 구독 ID와 고객 자료는 기록하지 않는다.

```bash
# zsh/bash
cat >> evidence/observation.md <<'EOF'
| <실험/단계> | <HOST 또는 도구와 정확한 명령> | <미검증 기대 결과> | <실제 stdout/stderr와 종료 코드> | <실제 승인, 도구 호출과 정책> | <전후 hash 또는 diff> | <evidence 파일 경로> | <판정과 이유> |
EOF
```

```powershell
# PowerShell
@'
| <실험/단계> | <HOST 또는 도구와 정확한 명령> | <미검증 기대 결과> | <실제 stdout/stderr와 종료 코드> | <실제 승인, 도구 호출과 정책> | <전후 hash 또는 diff> | <evidence 파일 경로> | <판정과 이유> |
'@ | Add-Content -Path ./evidence/observation.md
```

`<...>`로 둘러싼 내용을 실제 값으로 바꾼 뒤 실행한다. 판정은 `MODEL_REFUSAL`, `APPROVAL_REQUIRED`, `POLICY_DENIED`, `UNSUPPORTED`, `ENVIRONMENT_FAILURE`, `SUCCESS` 중 하나를 쓰고 이유를 덧붙인다.

다음 표는 비교할 항목과 **미검증 기대 결과**다. 실제 결과는 이 표가 아니라 참가자의 관찰표에 적는다.

| 시험 | 기대 결과(모두 미검증) |
| --- | --- |
| `workspace` 파일과 교육용 `.env` | 현재 작업 디렉터리에 기본 정책이 적용되면 읽기와 쓰기 가능 |
| 샌드박스를 끈 상태의 외부 확인용 파일 | OS 사용자 권한 범위에서 접근 가능 |
| 샌드박스를 켠 상태의 외부 확인용 파일 | 기존 허용 범위 밖이면 차단 |
| 읽기 전용 허용 후 읽기와 쓰기 | 읽기만 허용 |
| 최소 읽기와 쓰기 권한 부여 후 쓰기 | 명시한 범위만 허용 |
| 네트워크와 E2E | 실제 정책과 오류를 연결 |

Copilot의 "할 수 없다"는 문장은 차단 증거가 아니다. 실제 도구 호출과 정책 기록을 함께 확인한다.

## 실패 원인 확인

실패한 명령의 출력과 적용 중인 정책을 대조해 정책 차단과 OS 미지원을 구분한다. Node 미설치, 일반 npm 오류, 프록시를 따르지 않는 프로그램의 요청처럼 다른 원인도 있을 수 있다. 근거가 부족하면 원인을 확정하지 않는다. 자동으로 허용된 경로 안의 확인용 파일이 읽혔다면 실험에 사용할 경로부터 확인한다. 전체 홈 접근을 허용하거나 샌드박스를 꺼서 정상화하지 않는다.

## 복구와 체크포인트

복구가 필요하면 먼저 실행 기록을 보존하고 교육용 `__workshop-inside.txt`와 자신이 만든 확인용 파일만 대상으로 삼는다. 전체 저장소를 임의로 초기화하지 않는다. 공통 과제 복구는 사람이 [체크포인트 안내](../checkpoints/README.md)를 읽고 수행한다. 현재 패치는 리허설 전이므로 제공하지 않는다. 다음 실습은 변경 사항이 없는 별도 실습 폴더를 사용해 계속할 수 있다.

## 정리

1. 추가한 교육용 규칙만 제거하고 일시적으로 바꾼 개인 설정을 시작 전 상태로 되돌린다. `/sandbox enable`과 `/sandbox disable`은 개인 설정에 저장될 수 있으므로 이 실습은 세션 실행 옵션을 우선한다. 조직 정책은 변경하지 않는다.
2. 관찰표와 실행 기록을 보존한 뒤 자신이 만든 확인용 **개별 파일**만 제거한다. 다른 파일이 있는 폴더를 재귀 삭제하지 않는다.
