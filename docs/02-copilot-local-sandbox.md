# Lab 0/1. Copilot 자체 샌드박스 OFF → ON → 최소 grant

## 1. 목표와 시간

Lab 0은 10분, Lab 1은 30분이다. 같은 명령을 반복하고 정책과 상태로 차이를 설명한다. **이 문서의 모든 명령과 기대 결과는 미검증**이다. 강사 리허설 후에만 배포본으로 사용한다. [출처](sources.md), [개요](../README.md).

## 2. 실행 위치

준비와 원자료 저장은 **HOST**, 접근 제한 확인과 과제 실행은 **COPILOT CLI가 호출한 도구**에서 한다. HOST에서 실행한 probe를 sandbox 차단 증거로 기록하지 않는다. 예시는 PowerShell이다. macOS/Linux는 경로를 실제 절대 경로로 바꾸고 `Get-FileHash` 대신 `shasum -a 256` 또는 `sha256sum`을 쓴다.

## 3. 사전 조건과 현재 상태

`<WORKSHOP_DIR>`는 개인 템플릿 저장소의 클론 루트다. [사전 준비의 샘플 다운로드](00-setup.md#샘플-다운로드하기)를 마친 `workspace`를 사용하며 추출 스크립트를 다시 실행하지 않는다. Node.js 24.x, Git과 Copilot 지원 OS를 확인한다. `workspace`에는 고정 SHA의 앱 파일과 `baseline` 태그가 있고 원격 저장소는 없어야 한다.

```powershell
# HOST, <WORKSHOP_DIR>
New-Item -ItemType Directory -Path .\evidence -ErrorAction Stop
Copy-Item .\evidence-template\* .\evidence -Recurse
New-Item -ItemType Directory -Path .\evidence\lab-0,.\evidence\lab-1 -ErrorAction Stop
Set-Content .\workspace\.env 'WORKSHOP_DUMMY=not-a-secret'
```

기존 `evidence`가 있으면 위 생성/복사를 반복하지 않고 새 실습 폴더를 고른다. POSIX에서는 `mkdir evidence`와 `cp -R evidence-template/. evidence/`로 관찰 기록 폴더를 준비한다.

canary는 OS 임시 폴더나 부모 워크숍 저장소 안에 두지 않는다. 임시 폴더와 저장소 전체 읽기 자동 grant 때문에 실험이 무효가 될 수 있다.

```powershell
# HOST, 기존 폴더이면 중단하고 다른 교육용 경로를 선택한다.
New-Item -ItemType Directory C:\SandboxCanary -ErrorAction Stop
Set-Content C:\SandboxCanary\read.txt 'WORKSHOP_CANARY=not-a-secret'
Set-Content C:\SandboxCanary\write.txt 'before'
Get-Content C:\SandboxCanary\read.txt
Get-FileHash C:\SandboxCanary\write.txt |
  Out-File .\evidence\lab-0\canary-before.txt
git -C .\workspace status --short |
  Out-File .\evidence\lab-0\git-before.txt
git -C .\workspace rev-parse baseline |
  Out-File .\evidence\lab-0\baseline.txt
git -C .\workspace remote -v |
  Out-File .\evidence\lab-0\remotes.txt
git status --short --ignored |
  Out-File .\evidence\lab-0\outer-status.txt
```

`workspace`의 가장 가까운 Git 루트만 repository 범위로 판단하는지는 미확인이다. sandbox ON에서 부모의 `checkpoints/`가 읽히면 강사에게 알린다. **과제 해결을 위해 checkpoint나 완성 예시를 Copilot에 읽히지 않는다.** 단순 프롬프트 금지는 보안 통제가 아니다.

HOST에서 sandbox를 켜기 **전** 기준선을 확인한다. 실패하면 일반 환경부터 해결한다.

```powershell
Push-Location .\workspace
npm ci 2>&1 | Tee-Object ..\evidence\lab-0\npm-ci.txt
npm run test:unit 2>&1 | Tee-Object ..\evidence\lab-0\unit.txt
Pop-Location
```

각 명령 직후 `$LASTEXITCODE`도 별도 기록한다. `.env`가 Git에서 무시되어도 파일은 존재하고 읽힐 수 있다.

## 4. 실행 명령과 공통 프롬프트

### A. OFF, 5분

HOST에서 기록을 시작한 뒤 앱 루트에서 새 세션을 연다. transcript에는 토큰을 입력하지 않는다.

```powershell
Start-Transcript -Path .\evidence\lab-1\off-transcript.txt -NoClobber
Set-Location .\workspace
copilot --no-sandbox
```

CLI에서 `/sandbox status`를 확인하고 다음 **각 명령을 CLI의 셸 도구로 정확히 실행**하도록 요청한다. 도구 승인은 필요한 범위만 사람이 승인한다. host `--yolo`는 사용하지 않는다.

```text
node -e "console.log(require('node:fs').readFileSync('.env','utf8'))"
node -e "require('node:fs').writeFileSync('__workshop-inside.txt','inside')"
node -e "console.log(require('node:fs').readFileSync('C:/SandboxCanary/read.txt','utf8'))"
node -e "require('node:fs').writeFileSync('C:/SandboxCanary/write.txt','after')"
```

POSIX에서는 `C:/SandboxCanary/...`를 예컨대 `/home/<user>/SandboxCanary/...` 같은 **실제 존재하는 외부 교육용 절대 경로**로 바꾼다. OFF/ON에서 동일한 문자열을 쓴다.

세션을 종료한 뒤 HOST에서 `Stop-Transcript`를 실행한다. transcript에 CLI의 화면이 완전히 남지 않으면 실제 도구 stdout/stderr와 정책 화면을 복사해 별도 텍스트로 저장하고, 빠진 부분을 표시한다. 모델이 작성한 설명으로 빈 실행 로그를 채우지 않는다.

### B. ON, 8분

HOST에서 canary `write.txt`를 `before`로 되돌리고 hash를 기록한다. 각 시험 전 상태가 같아야 한다. `__workshop-inside.txt`는 다음 시험에서 같은 내용으로 덮어써도 된다.

```powershell
# HOST, workspace에서 한 단계 위로 이동한 뒤
Set-Location ..
Set-Content C:\SandboxCanary\write.txt 'before'
Start-Transcript -Path .\evidence\lab-1\on-transcript.txt -NoClobber
Set-Location .\workspace
copilot --sandbox
```

CLI에서 다음을 기록하고 A의 네 명령을 **동일한 도구**로 반복한다.

```text
/sandbox status
/sandbox policy
/sandbox config
```

`Allow sandbox bypass`를 끄거나 우회 실행 승인을 거부한다. 조직 managed policy가 OFF를 금지하면 우회하지 않고 해당 비교를 미지원/정책 제한으로 기록한다. `/sandbox policy npm ci`, `/sandbox policy npm run test:e2e`는 정책 예측이며 실제 실행 로그가 아니다.

### C. 최소 grant, 6분

`/sandbox config`에서 정확한 UI 표기를 확인해 외부 canary 폴더 하나만 Read-Only로 허용한다. `/sandbox policy`를 저장하고 같은 읽기/쓰기 명령을 반복한다. 이어 쓰기가 필요한 교육용 파일/폴더에만 Read/Write를 부여하고 반복한다. UI 메뉴와 OS별 지원은 `TBD(검증 필요)`다.

명시적 Denied 실험에는 **이미 존재하는** dummy 파일만 쓴다. Denied가 allow보다 우선하므로 교육용 deny를 제거한 뒤 grant를 설정한다. 없는 denied 경로가 디렉터리로 생성될 수 있다는 공식 주의사항을 확인한다.

### D. 네트워크와 개발 도구, 6분

CLI 도구에서 `curl -I https://example.com`을 실행하고 출력과 종료 코드를 남긴다(Windows에서는 `curl.exe`). 특정 공개 호스트만 deny한 뒤 같은 명령과 유효 정책을 기록한다. 파일이나 canary 내용을 전송하지 않는다. 모델 API 전체를 막지 않는다.

그다음 CLI에 `npm run test:unit`, `npm run build`, `npm run test:e2e`를 순서대로 실행하도록 요청한다. E2E의 실패를 browser 미설치, cache 접근 차단, localhost 차단, 일반 build 오류로 분류한다. Windows의 `Allow local network`는 proxy/credential masking과 private-network 접근에 영향을 줄 수 있다. 한 `curl` 결과를 모든 프로그램의 차단 보장으로 일반화하지 않는다.

공통 코딩 작업은 별도로 준비한 05번 원문을 아래 프롬프트 뒤에 그대로 붙인다. 30분 안에 구현을 끝내는 것보다 접근 허용과 차단 결과 관찰을 우선하며 시간이 부족하면 강사가 복구 경로를 안내한다.

```text
아래 과제 원문의 수락 조건을 구현한다. npm run test:unit을 실행하고 결과와
변경 요약을 앱 루트의 evidence/summary.md에 남긴다. 지정 workspace 밖을
변경하지 않는다. checkpoints나 완성 예시는 읽지 않는다.
원격 push, PR 작성, 앱 배포는 하지 않는다.
[사람이 tasks/05-catalog-summary.md의 원문 부분만 여기에 붙인다]
```

### E. 설명과 복구, 5분

세션 종료 후 `Stop-Transcript`를 실행한다. 다음 관찰 명령은 **HOST, WORKSHOP_DIR**에서 실행해 출력 파일을 보관한다.

```powershell
git -C .\workspace status --short | Out-File .\evidence\lab-1\git-after.txt
git -C .\workspace diff --binary --output=..\evidence\lab-1\changes.patch
Get-FileHash C:\SandboxCanary\write.txt | Out-File .\evidence\lab-1\canary-after.txt
```

`--output`은 Git의 `-C` 기준 상대 경로다. 원자료 파일에 비밀이 없는지 사람이 검토한다.

## 5. 관찰 항목

OS/CLI 버전, 시작 CWD, 기준 commit, sandbox status, 유효 정책, 실제 호출 도구, 승인/우회 여부, stdout/stderr, 종료 코드와 파일 hash를 기록한다. 시간 초과로 건너뛴 작업도 숨기지 않는다.

## 6. 기대와 실제 결과

| 시험 | 기대 결과(모두 미검증) | 실제 결과 | 근거 파일 |
| --- | --- | --- | --- |
| workspace 파일과 dummy `.env` | 기본 CWD 정책이면 쓰기/읽기 가능 | 참가자 작성 | 참가자 작성 |
| OFF 외부 canary | OS 사용자 권한 범위에서 접근 가능 | 참가자 작성 | 참가자 작성 |
| ON 외부 canary | 기존 grant 밖이면 차단 | 참가자 작성 | 참가자 작성 |
| Read-Only 후 read/write | 읽기만 허용 | 참가자 작성 | 참가자 작성 |
| 최소 Read/Write 후 write | 명시한 범위만 허용 | 참가자 작성 | 참가자 작성 |
| 네트워크와 E2E | 실제 정책과 오류를 연결 | 참가자 작성 | 참가자 작성 |

참가자가 `evidence/observation.md`에 직접 판정한다. Copilot의 "할 수 없다"는 문장은 차단 증거가 아니다.

## 7. 실패가 정상인 경우

정책 차단과 OS 미지원을 구분한다. Node 미설치, 일반 npm 오류, proxy를 따르지 않는 프로그램의 요청은 다른 원인이다. 자동 grant 안의 canary가 읽혔다면 실험 배치부터 수정한다. 전체 홈 접근 허용이나 sandbox OFF로 정상화하지 않는다.

## 8. 복구와 checkpoint

교육용 `__workshop-inside.txt`와 canary 파일만 대상으로 복구한다. 전체 저장소를 임의 초기화하지 않는다. 공통 과제 복구는 `checkpoints/README.md`를 사람이 읽는다. 현재 패치는 리허설 전이므로 제공하지 않는다. 다음 Lab은 별도 clean workspace를 사용해 계속할 수 있다.

## 9. 정리

추가한 교육용 rule만 제거하고 시작 전 개인 설정과 비교한다. `/sandbox enable`과 `/sandbox disable`은 개인 설정에 저장될 수 있으므로 이 실습은 세션 flag를 우선한다. 조직 정책은 변경하지 않는다. 원자료를 보존한 뒤 자신이 만든 canary의 **개별 파일**만 제거한다. 다른 파일이 있는 폴더를 재귀 삭제하지 않는다.
