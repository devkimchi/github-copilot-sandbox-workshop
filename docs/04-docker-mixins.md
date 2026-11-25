# Lab 2B. v3 mixin으로 도구 확장하기

## 1. 목표와 시간

기본 20분, 180분 과정에서는 **직접 만드는 mixin 30분을 추가해 총 50분**이다. 환경 확장과 권한 확대를 구분한다. **모든 명령과 기대 결과는 미검증**이다. [출처](sources.md), [개요](../README.md).

## 2. 실행 위치

생성과 descriptor 검토는 **HOST**, tool version과 Tailspin E2E는 **DOCKER VM**이다. source build는 host의 Docker/Buildx를 사용할 수 있다.

## 3. 사전 조건과 현재 상태

v3 전용이다. `schemaVersion: "3"`, `kind`, `requires`, `provides`, network/credential/lifecycle capability와 신뢰할 출처를 검토한다. `<VERIFIED_TAG>`는 `TBD(검증 필요)`다.

Tailspin lock 파일의 `@playwright/test`, `playwright`, `playwright-core`는 **1.65.0**이다. mixin 호출 시 `--kit-arg playwright.version=1.65.0`으로 샘플 앱이 요구하는 버전을 지정한다. compatible Debian 13 workload, apt/Bash와 package repository 접근도 확인한다. 실제 브라우저 정합과 E2E 실행은 리허설에서 확인한다.

`requires`는 자동 다운로드가 아니다. 중복 feature는 충돌할 수 있다. v3에는 `sbx kit add`로 기존 sandbox에 mixin을 추가하지 않는다. 새 sandbox를 만든다.

## 4. 실행 명령과 프롬프트

### published mixin, 기본 20분

기존 `ws-clone`의 DOCKER VM에서 `npm run test:e2e`를 실행한다. browser나 시스템 라이브러리 부재로 실패하는지 기록한다. 이미 통과하면 실패를 연출하지 않는다.

HOST의 clean `workspace-docker`에서, 다른 이름으로 생성한다.

```text
sbx run --clone --name ws-mixin sbx/copilot:<VERIFIED_TAG> . --kit sbx/playwright:<VERIFIED_TAG> --kit-arg playwright.version=1.65.0
```

실제 사용한 workload와 mixin의 tag와 digest를 기록한다. 버전 인자를 지정했다고 실제 브라우저 정합과 E2E 성공까지 확인한 것으로 취급하지 않는다.

새 DOCKER VM에서:

```bash
node --version
npm ci
npx playwright --version
npm run test:e2e
touch /run/sandbox/source/__workshop-write-probe
```

Copilot 요청:

```text
이 환경에서 Tailspin E2E를 실행하고 tool version, 실패 원인과 필요한 접근을
기록한다. host source에 쓰거나 checkpoints를 읽지 않는다.
기본 환경과 같은 접근 제한 확인 작업을 반복하되 정책 우회는 하지 않는다.
```

프로젝트에 로컬 패키지가 있으면 mixin의 전역 Playwright가 아니라 프로젝트 패키지를 사용한다. mixin의 Chromium과 프로젝트 고정 release가 맞지 않으면 리허설 결과에 따라 `npm run test:e2e:install`로 맞는 브라우저를 설치하는 단계를 추가한다. **다른 원인까지 브라우저 설치로 덮지 않는다.** npm과 browser download의 exact-host decision을 각각 기록한다.

기존 `example.com` deny를 새 sandbox에 자동 승계한다고 가정하지 않는다. HOST에서 `sbx policy ls`, `sbx policy check network --sandbox ws-mixin example.com`으로 확인하고 필요한 경우 **새 sandbox 범위에** 같은 교육용 deny를 설정한 후 VM의 같은 `curl`과 decision을 비교한다.

headless Chromium만 다룬다. headed mode, codegen/UI runner는 display가 별도로 필요하고 Firefox/WebKit도 자동 준비된다고 가정하지 않는다. Tailspin E2E는 VM 안의 `localhost:4321`을 사용하며 host localhost와 다르다.

### 직접 제작, 확장 30분

`mixins/`의 템플릿을 사람이 검토한 뒤 `evidence/`가 아니라 별도 교육용 제작 복사본으로 복사한다. 예: `<WORKSHOP_DIR>/workspace-mixin-kit/`. 여기에는 앱이 아닌 kit만 둔다. `mixins/`는 완성 정답이 아니라 인자와 파일 추가를 연습하는 최소 템플릿이다.

1. `greeting` 인자를 읽고 교육용 문자열로 바꾼다. 입력 pattern과 buildArg를 유지한다.
2. VM의 `/etc/workshop-greeting`에 생성할 내용을 직접 수정한다. 새 credential이나 runtime network 요구를 추가하지 않는다.
3. HOST의 clean 앱 폴더에서 source kit을 참조하는 **새 sandbox**를 만든다. build network는 runtime network와 별개다.

```text
sbx run --clone --name ws-custom sbx/copilot:<VERIFIED_TAG> . --kit ../workspace-mixin-kit
```

위 경로는 HOST `workspace-docker`에서 실행할 때의 예시다. 선택한 버전의 source kit 탐색/인자 문법은 `TBD(검증 필요)`다. 공식 제작 가이드에서 이 경로의 Docker/Buildx 전제를 확인한다. OCI publish, registry 로그인과 다른 모델 호출은 필수가 아니다.

DOCKER VM에서 `cat /etc/workshop-greeting`과 `touch /run/sandbox/source/__workshop-write-probe`를 실행한다. 수정 후 같은 이름을 다시 열면 옛 kit을 사용할 수 있으므로 **다른 이름**으로 만들어 비교한다. argument, `provides`, build 단계, 최종 파일과 요구 권한을 짧게 설명한다.

## 5. 관찰 항목

기본/확장 sandbox 이름, workload와 mixin의 고정 digest, descriptor, 프로젝트와 tool version, E2E 로그, browser 설치 여부, source 쓰기 차단과 network decision을 `evidence/lab-2b/`에 사람이 저장한다.

HOST에서는 폴더를 먼저 만들고 transcript를 사용할 수 있다.

```powershell
New-Item -ItemType Directory .\evidence\lab-2b -ErrorAction Stop
sbx policy ls | Out-File .\evidence\lab-2b\policy.txt
```

도구 stdout/stderr는 실제 VM 출력에서 저장하고 모델의 요약으로 대신하지 않는다.

## 6. 기대와 실제 결과

| 시험 | 기대 결과(미검증) | 실제 결과 | 근거 파일 |
| --- | --- | --- | --- |
| 기본과 Playwright mixin | tool/browser 구성 차이 관찰 | 참가자 작성 | 참가자 작성 |
| E2E | 버전과 browser 정합 후 Chromium 테스트 실행 | 참가자 작성 | 참가자 작성 |
| source 쓰기/동일 network probe | 기존 제한과 비교, 자동 확대 가정 금지 | 참가자 작성 | 참가자 작성 |
| 직접 제작(확장만) | 새 VM에 직접 만든 파일 확인 | 참가자 작성 | 참가자 작성 |

## 7. 실패가 정상인 경우

기본 환경의 browser 부재와 source read-only는 관찰 대상이다. Playwright release 불일치, 추가 다운로드, `requires` 미충족과 feature 중복은 구분한다. mixin 추가가 egress와 host 쓰기를 모두 허용한다고 해석하지 않는다.

## 8. 복구와 checkpoint

템플릿으로 돌아가 인자 하나와 파일 하나만 추가한다. 리허설 전에는 `checkpoints/mixin-example/` 완성본을 제공하지 않는다. 실패했다고 v2 descriptor나 legacy archive로 바꾸지 않는다.

## 9. 정리

필요한 로그를 보관하고 `sbx rm ws-mixin`, 확장 참가자는 `sbx rm ws-custom`을 실행한다. 실제 사용한 이름만 제거한다. 이후 ACA는 별도 원격 workspace에서 시작한다.
