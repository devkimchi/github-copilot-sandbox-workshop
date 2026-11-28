# Lab 2. Docker Direct/Clone와 네트워크

## 1. 목표와 시간

30분(환경 5분, 공유 방식 12분, 도구 5분, 네트워크 8분). 로컬 Linux microVM의 격리 방식과 코드 회수 방식을 비교한다. **모든 명령과 기대 결과는 미검증**이다. workload는 `latest` tag를 사용한다. [출처](sources.md), [개요](../README.md).

## 2. 실행 위치

`sbx`, hash와 fetch는 **HOST**, `npm`, source 쓰기 probe와 코딩은 **DOCKER VM**에서 실행한다. 기본 Copilot workload는 `--yolo`로 시작하므로 실행 승인과 VM 격리를 별개로 해석한다.

## 3. 사전 조건과 현재 상태

Copilot CLI 실습에서 HOST용 `node_modules`를 설치한 폴더는 재사용하지 않는다. 플랫폼별 native 바이너리가 Linux와 맞지 않을 수 있다. 서로 다른 샌드박스가 같은 작업 트리를 동시에 수정하게 하지 않는다.

```powershell
# HOST, <REPOSITORY_ROOT>
./scripts/download-sample.ps1 -Target workspace-direct
./scripts/download-sample.ps1 -Target workspace-docker
New-Item -ItemType Directory ./evidence/lab-2 -ErrorAction Stop
git -C ./workspace-direct status --short | Out-File ./evidence/lab-2/direct-before.txt
git -C ./workspace-docker status --short | Out-File ./evidence/lab-2/clone-before.txt
git -C ./workspace-docker remote -v | Out-File ./evidence/lab-2/remotes-before.txt
Get-FileHash ./workspace-direct/package.json | Out-File ./evidence/lab-2/direct-hash-before.txt
```

POSIX에서는 `bash scripts/download-sample.sh workspace-direct`와 `workspace-docker`를 각각 사용한다. Git 기준 commit `baseline`, remote 없음과 clean 상태를 확인한다.

## 4. 실행 명령과 프롬프트

### Direct

```powershell
# HOST
Set-Location ./workspace-direct
sbx run --name ws-direct sbx/copilot:latest .
```

DOCKER VM의 Copilot에게 아래 명령을 호출하도록 요청한다. 도구 출력 원문을 사람이 `evidence/lab-2/`에 저장한다.

```bash
pwd
uname -a
node --version
copilot --version
git status --short
printf '\n' >> package.json
```

이 파일은 테스트용 줄바꿈만 추가한다. HOST의 다른 터미널에서 전파를 확인한다.

```powershell
# HOST, <REPOSITORY_ROOT>
Get-FileHash ./workspace-direct/package.json | Out-File ./evidence/lab-2/direct-hash-after.txt
git -C ./workspace-direct diff --binary --output=../evidence/lab-2/direct.patch
```

### Clone

```powershell
# HOST, <REPOSITORY_ROOT>
Set-Location ./workspace-docker
sbx run --clone --name ws-clone sbx/copilot:latest .
```

DOCKER VM에서:

```bash
pwd
node --version
git remote -v
touch /run/sandbox/source/__workshop-write-probe
```

마지막 명령은 read-only 오류를 기대한다(미검증). 읽을 수 있는 source mount이므로 "host 파일을 전혀 볼 수 없다"고 설명하지 않는다. 실제 비밀은 원본에 두지 않는다.

Copilot에 Copilot CLI 실습에서 사용한 공통 프롬프트를 입력하고, 그 뒤에 **05번 과제 원문**을 붙인다. 아래 명령과 단위 테스트 결과도 기록하게 한다.

```bash
git switch -c workshop/task05
npm ci
npm run test:unit
git status --short
```

코드 검토 후 **DOCKER VM 안에서만** 결과를 로컬 커밋한다. `git add -A` 전에 새 파일과 package script, agent 설정 등도 확인한다. `evidence/summary.md`는 과제 산출물이며 사람의 관찰표가 아니다.

```bash
git add -A
git -c user.name=workshop -c user.email=workshop@example.invalid commit -m "feat: catalog summary"
```

HOST에서 sandbox가 실행 중일 때만 fetch한다. 실제 remote 이름을 `git remote -v`에서 확인한다.

```powershell
# HOST, <REPOSITORY_ROOT>
git -C ./workspace-docker remote -v | Out-File ./evidence/lab-2/remotes-after.txt
git remote -v | Out-File ./evidence/lab-2/outer-remotes.txt
git -C ./workspace-docker status --short | Out-File ./evidence/lab-2/clone-after.txt
Test-Path ./workspace-docker/node_modules | Out-File ./evidence/lab-2/host-node-modules.txt
Test-Path ./workspace-docker/tailspin.db | Out-File ./evidence/lab-2/host-db.txt
git -C ./workspace-docker fetch sandbox-ws-clone
git -C ./workspace-docker diff baseline..sandbox-ws-clone/workshop/task05 --binary --output=../evidence/lab-2/clone.patch
git -C ./workspace-docker status --short | Out-File ./evidence/lab-2/after-fetch.txt
```

remote와 branch 이름이 다르면 확인한 실제 값으로 바꾼다. fetch는 commit을 받지만 working tree를 바꾸지 않는다. 코드 실행이나 checkout/merge는 검토 후 사람의 별도 판단이다. 원격 push와 PR은 만들지 않는다.

### 내부 도구와 네트워크

DOCKER VM에서 `docker info`를 확인하고, 사전에 준비한 `hello-world` 이미지가 있다면 `docker run --rm hello-world`를 실행한다. VM 안 sudo/Engine은 host 관리자 권한/daemon과 다르다. 이미지 다운로드와 network 허용은 별도 조건이다.

HOST에서:

```powershell
sbx policy ls | Out-File ./evidence/lab-2/policy-before.txt
sbx policy deny network --sandbox ws-clone example.com
sbx policy check network --sandbox ws-clone example.com
sbx policy log
```

DOCKER VM에서 `curl -I --max-time 8 https://example.com`을 실행하고 종료 코드와 실제 decision을 함께 저장한다. HOST에서 교육용 deny만 제거하고 좁은 allow를 시험한다.

```powershell
sbx policy rm network --sandbox ws-clone --resource example.com
sbx policy allow network --sandbox ws-clone example.com
sbx policy check network --sandbox ws-clone example.com
```

DOCKER VM에서 같은 `curl`을 반복한다. Balanced preset은 최소 allowlist가 아니다. `npm ci`가 이미 허용되어 있으면 실패를 연출하지 말고 npm 요청 decision만 기록한다. 정확한 필요한 호스트는 로그로 확인하며 조직 deny를 사용자 allow로 넓히지 않는다.

## 5. 관찰 항목

Direct 전후 hash/diff, Clone host working tree, `/run/sandbox/source` 오류, 양쪽 Git remote, VM의 Node 버전과 unit 결과, network decision, fetch 전후 상태를 원자료 파일로 남긴다. `sbx policy log`의 다른 작업 정보는 공유 전 지운다.

## 6. 기대와 실제 결과

| 시험 | 기대 결과(미검증) | 실제/판정 | 근거 파일 |
| --- | --- | --- | --- |
| Direct 수정 | host 파일 즉시 변경 | 참가자 작성 | 참가자 작성 |
| Clone 수정/설치 | host working tree, node_modules와 DB 불변 | 참가자 작성 | 참가자 작성 |
| Clone source 쓰기 | read-only 오류 | 참가자 작성 | 참가자 작성 |
| Clone 생성 | host 앱 저장소에 sandbox remote가 추가될 수 있음 | 참가자 작성 | 참가자 작성 |
| fetch | commit만 회수, working tree 불변 | 참가자 작성 | 참가자 작성 |
| deny/allow | 실제 요청과 decision 연결 | 참가자 작성 | 참가자 작성 |

## 7. 실패가 정상인 경우

source 쓰기 실패는 기대 결과다. microVM 시작 실패, Node 버전 부족과 native package 오류는 일반 환경 문제다. hostname 규칙은 IP 공유, 복호화하지 않는 연결 등 제한이 있으므로 `ping`이나 한 번의 HTTP 오류를 전체 egress 보장으로 해석하지 않는다.

## 8. 복구와 checkpoint

Direct probe 폴더는 다음 실습에 사용하지 않는다. Clone은 clean baseline에서 시작하며 시간 초과 시 사람이 checkpoint 운영 문서를 따른다. 현재 완성 패치는 없다. `sbx policy reset`이나 전역 자격 증명 삭제로 해결하지 않는다.

## 9. 정리

Clone 결과 fetch를 먼저 마친다. `sbx stop ws-clone` 후에는 fetch가 실패할 수 있다. 결과를 보관한 뒤 자신이 만든 sandbox만 `sbx rm ws-direct`, `sbx rm ws-clone`으로 제거한다. 뒤의 mixin 비교를 위해 `ws-clone`을 잠시 유지할 수 있다. 교육용 network rule만 원상 복구하고 공유 host 파일이 자동으로 복구되지 않음을 확인한다.
