# Lab 3. ACA 원격 격리, egress와 상태 보존

## 1. 목표와 시간

35분(제어 5분, 생성 6분, egress 7분, 과제 6분, stop/resume 7분, 회수 4분). **모든 명령과 기대 결과는 미검증**이다. region/image/credential ID와 exact-host allowlist는 `TBD(검증 필요)`다. [출처](sources.md), [개요](../README.md).

## 2. 실행 위치

`aca`는 **HOST** 제어 클라이언트다. Copilot과 앱은 **ACA REMOTE**에서 실행한다. Windows VM을 HOST로 써도 ACA는 그 VM과 분리된 원격 환경에서 실행된다. `az containerapp`과 ACA Sandboxes CLI를 혼동하지 않는다.

## 3. 사전 조건과 현재 상태

개인 구독, 교육 전용 group, 본인의 Data Owner, 정확한 Copilot credential을 사전에 준비한다. `az login` 인증과 모델 PAT는 별개다. 이미지와 quota, 예상 비용을 확인한다.

```powershell
# HOST, <WORKSHOP_DIR>
New-Item -ItemType Directory .\evidence\lab-3 -ErrorAction Stop
aca --version | Out-File .\evidence\lab-3\aca-version.txt
aca doctor
aca config show
aca sandboxgroup disk list-public
```

config/doctor 출력은 계정과 구독 정보를 포함할 수 있다. 원자료를 공유할 때 민감한 식별자를 지우고 무엇을 지웠는지 표시한다. label은 접근 통제가 아니며 목록 첫 credential을 고르지 않는다.

## 4. 실행 명령과 프롬프트

### 생성과 최초 정책

HOST에서 **새 sandbox를 생성할 때부터** default Deny를 적용한다. `<UNIQUE_NAME>`은 본인의 고유한 교육용 이름, `<CREDENTIAL_ID>`는 확인한 정확한 ID다.

```text
aca sandbox create --disk copilot --credential <CREDENTIAL_ID> --label name=<UNIQUE_NAME> --egress-default Deny --traffic-inspection Full
aca sandbox get -l name=<UNIQUE_NAME> -o json
```

반환된 **정확한 `<SANDBOX_ID>`**를 개인 기록에 보관한다. `copilot` public image는 최신 이미지를 사용한다. Node 버전을 확인한다. 위 상태에서는 모델 요청이 실패할 수 있으므로 다음 allowlist를 확정하고 적용한 뒤 모델을 호출한다.

```text
aca sandbox egress set --id <SANDBOX_ID> --default Deny --traffic-inspection Full --rule "github.com:Allow" --rule "codeload.github.com:Allow" --rule "registry.npmjs.org:Allow" --rule "<VERIFIED_MODEL_HOST>:Allow" --rule "example.com:Deny"
aca sandbox egress show --id <SANDBOX_ID>
aca sandbox shell --id <SANDBOX_ID>
```

`<VERIFIED_MODEL_HOST>`는 실행 가능한 기본값이 아니다. 실제 필요한 모델 호스트마다 `--rule`을 반복한다. Playwright 다운로드는 E2E를 실행할 때만 확인된 호스트를 추가한다. `egress set`으로 정책 전체를 교체할 수 있으므로 **이번에 만든 sandbox에만** 적용한다. `*.github.com`이 `api.githubcopilot.com`을 포함한다고 가정하지 않는다. credential 전달과 egress 허용은 별개다.

### 같은 스냅샷 준비

HOST에서 원격 전용 디렉터리를 만들고 제공 스크립트를 전송한다.

```text
aca sandbox exec --id <SANDBOX_ID> -c "mkdir -p /home/aca-workshop"
aca sandbox fs write --id <SANDBOX_ID> --path /home/aca-workshop/download-sample.sh --file scripts/download-sample.sh
```

이 경로의 쓰기 권한은 image별 `TBD(검증 필요)`다. 권한 오류이면 실제 writable 작업 경로를 확인하고 모든 후속 절대 경로를 일관되게 바꾼다. HOST 경로가 자동 mount된다고 가정하지 않는다.

ACA REMOTE 셸에서:

```bash
command -v curl tar git node
cd /home/aca-workshop
bash download-sample.sh workspace
cd workspace
pwd
node --version
git status --short
git remote -v
npm ci
```

추출 스크립트는 고정 commit 압축본에서 앱만 추출하고 `baseline` 태그를 만든다. 원본 agent 설정과 MCP는 가져오지 않는다. 최종 다운로드 범위와 최소 도구를 확인한다.

### 원격 파일과 egress

ACA REMOTE에서 `test -e 'C:\SandboxCanary\read.txt'`를 실행해 HOST의 파일이 자동 연결되지 않음을 확인한다. 경로 부재는 "정책이 읽기를 차단했다"는 뜻이 아니다. 원격 파일시스템에 해당 host 파일이 없다는 관찰이다.

ACA REMOTE에서 각각 실행한다.

```bash
curl -I --max-time 8 https://github.com
curl -I --max-time 8 https://example.com
```

HOST에서 출력과 대응 decision을 저장한다.

```text
aca sandbox egress show --id <SANDBOX_ID>
aca sandbox egress decisions --id <SANDBOX_ID> -o json
```

ACA advanced rule은 **첫 matching rule**이 적용된다. Docker의 deny 우선 설명을 그대로 옮기지 않는다. 정책이 없으면 unrestricted outbound라는 사실을 설명하되 권한 있는 sandbox에서 정책을 통째로 해제하지 않는다. 필요하면 강사가 credential 없는 dummy sandbox에서 별도 시연한다.

### 공통 과제

ACA REMOTE의 `workspace`에서 `copilot`을 실행하고 Lab 1 공통 프롬프트와 **05번 원문**을 붙인다. `npm run test:unit`과 과제 산출물 `evidence/summary.md`를 남긴다. checkpoint나 완성 예시는 읽히지 않으며 원격 push, PR과 앱 배포를 하지 않는다.

원격 셸에서 실제 파일의 절대 경로와 hash를 기록한다.

```bash
pwd
realpath evidence/summary.md
sha256sum evidence/summary.md
git status --short
git diff --binary > /home/aca-workshop/result.patch
```

`git diff`에는 untracked 파일이 들어가지 않는다. 새 파일 목록을 별도로 확인하고 필요한 파일을 파일 API로 회수하거나 검토 후 로컬 커밋한 diff로 보관한다. 앱 내부 `evidence/summary.md`와 HOST의 관찰 기록은 다르다.

### 같은 ID의 stop/resume

HOST에서:

```text
aca sandbox lifecycle set --id <SANDBOX_ID> --auto-suspend enable --mode Memory --idle-timeout-seconds 900
aca sandbox get --id <SANDBOX_ID> -o json
aca sandbox stop --id <SANDBOX_ID>
aca sandbox get --id <SANDBOX_ID> -o json
```

`Stopped` 전환을 실제로 확인한 뒤:

```text
aca sandbox resume --id <SANDBOX_ID>
aca sandbox get --id <SANDBOX_ID> -o json
aca sandbox shell --id <SANDBOX_ID>
```

`Running` 전환 후 ACA REMOTE에서 **같은 절대 경로**의 `sha256sum`을 반복한다. 새 create는 resume의 증거가 아니다. 파일 hash 비교는 파일 보존만 입증하며 **memory 복원은 입증하지 않는다**. timeout 설정만으로 auto-suspend가 검증되는 것도 아니다. 인터랙티브 연결은 idle 판정에 영향을 줄 수 있다.

### 결과 회수

HOST PowerShell에서 실제 경로와 ID를 대입해 저장한다.

```powershell
aca sandbox fs cat --id <SANDBOX_ID> --path /home/aca-workshop/workspace/evidence/summary.md |
  Out-File .\evidence\lab-3\remote-summary.txt
aca sandbox fs cat --id <SANDBOX_ID> --path /home/aca-workshop/result.patch |
  Out-File .\evidence\lab-3\remote-diff-review.txt
aca sandbox egress decisions --id <SANDBOX_ID> -o json |
  Out-File .\evidence\lab-3\egress-decisions.json
```

PowerShell 인코딩/줄바꿈 변환은 바이트를 바꿀 수 있다. 위 diff는 **검토용 텍스트**이지 바이트 보존 패치가 아니다. host/remote 파일 hash 일치를 주장하지 않는다. lifecycle은 remote 동일 파일끼리 비교한다.

## 5. 관찰 항목

명령의 실제 위치, remote CWD, Node/image, 최초 egress 설정, 실제 request/decision과 종료 코드, 정확한 ID의 Running/Stopped/Running JSON, 전후 remote hash, 회수한 결과를 저장한다. 정책/상태 출력은 각 명령 직후 별도 파일로 복사한다.

## 6. 기대와 실제 결과

| 시험 | 기대 결과(미검증) | 실제 결과 | 근거 파일 |
| --- | --- | --- | --- |
| host canary 절대 경로 | remote에 없음, 자동 mount 아님 | 참가자 작성 | 참가자 작성 |
| remote 수정 | host working tree 불변 | 참가자 작성 | 참가자 작성 |
| 허용/거부 공개 호스트 | 정책 decision과 요청 결과 연결 | 참가자 작성 | 참가자 작성 |
| 동일 ID stop/resume | 상태 전환, 같은 파일 hash | 참가자 작성 | 참가자 작성 |
| 결과 회수 | 검토할 텍스트 확보 | 참가자 작성 | 참가자 작성 |

## 7. 실패가 정상인 경우

deny 시험의 차단과 RBAC/인증/quota 오류를 구분한다. `Disabled` 등 예외 상태는 기록하고 진단한다. 모델 요청 실패 시 전체 allow로 바꾸지 말고 정확한 denied endpoint와 인증을 각각 확인한다. provider token 주입과 egress `secretRef` header transform의 비밀 보장을 일반화하지 않는다.

## 8. 복구와 checkpoint

수작업 시간 초과이면 패치가 준비된 경우에만 사람이 HOST에서 `aca sandbox fs write --id <SANDBOX_ID> --path /home/aca-workshop/task05-result.patch --file checkpoints/task05-result.patch`로 전송한다. ACA REMOTE에서 변경과 untracked 파일을 먼저 백업하고, clean baseline으로 복구한 뒤 `git apply --check`와 `git apply`를 순서대로 실행한다. 자동 복구 스크립트를 사용할 경우 `.sh`도 전송하고 backup 경로를 원격으로 지정한다. **현재 패치는 미제공**이므로 제공 결과라고 꾸미지 말고 생략/부분 수행을 기록한다.

## 9. 정리

필요한 결과부터 회수하고 HOST에서 정확한 ID로 `aca sandbox delete --id <SANDBOX_ID> --yes`를 실행한다. 이후 `aca sandbox list -o json`에서 해당 ID가 사라졌는지 확인한다. 자신이 만든 snapshot, disk와 volume을 따로 확인한다. 공유 group 전체 삭제를 기본 명령으로 사용하지 않는다. ingress와 앱 배포는 실습하지 않는다.
