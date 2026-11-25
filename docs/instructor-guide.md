# 강사용 운영 가이드

현재는 **작성 단계 초안**이다. 정적 검사와 실습 리허설은 다르며 아래 제품 실행, 네트워크, 시간과 비용은 모두 **미검증**이다. [전체 흐름](../README.md), [출처](sources.md).

## 수업 운영

설치와 Azure 준비는 사전 과제다. 150분은 승인/접근 범위 10, baseline 10, Copilot 30, Docker 30, mixin 20, 휴식 5, ACA 35, 비교/정리 10분이다. 180분은 mixin 직접 제작 30분만 추가한다.

| 구간 | 시간 제한과 다음 이동 |
| --- | --- |
| baseline | 10분 안에 일반 환경 실패를 분류. 미지원이면 승인된 대체 환경/실제 예행 기록 사용 |
| Copilot | OFF 5, ON 8, 최소 grant 6, network/tool 6, 설명/복구 5분. 기능 구현 완료보다 동일 probe 비교 우선 |
| Docker | 환경 5, Direct/Clone 12, 내부 도구 5, network 8분. 결과 회수 전에 VM 삭제 금지 |
| mixin | 기본 20분, 확장만 추가 30분. 버전 불일치와 browser 다운로드를 분리 |
| ACA | 제어 5, 생성 6, egress 7, 과제 6, lifecycle 7, 회수 4분. 비동기 state 전환을 기다림 |
| 비교/정리 | 관찰표 수기 완성과 정확한 자원 삭제, 잔존 비용 확인 |

05번 과제를 기본으로 쓴다. 02번 대안을 고르면 세 환경 모두 같은 과제를 사용한다. 01번 검색, 앱 현대화 전체 실행, PR/앱 배포, ACA ingress와 memory 복원 심화는 넣지 않는다.

시간 초과 시 [체크포인트 운영](../checkpoints/README.md)을 사용하되 **현재 패치는 없다**. 리허설에서 생성/검증 전이면 다음 모듈의 clean workspace로 이동하고 미실행을 기록한다. 실제로 수행하지 않은 결과를 성공 증거로 제공하지 않는다.

## 기록과 피드백

참가자가 명령 출력을 파일로 저장하고 [관찰표](../evidence-template/observation.md)와 [비교표](../evidence-template/comparison.md)를 직접 채운다. GitHub 이슈를 만들거나 Copilot으로 표를 자동 판정하지 않는다. Copilot은 마지막에 비밀을 제거한 원자료 요약만 보조한다.

모델 거부, 승인 대기, 정책 차단, 미지원, 일반 오류와 성공을 분리한다. `.env`와 ignore 규칙을 접근 통제 수단으로 가르치지 않는다. 결과가 다르면 실행 위치, 실제 도구, 유효 정책과 명령 출력을 먼저 확인한다.

## 설치 정책과 실제 버전 기록(리허설 후 채움)

| 항목 | 조사 근거/참고값 | 배포본의 확정 값 |
| --- | --- | --- |
| Tailspin 원본 SHA | `9cd9a450f923c7a084bd47d661877d82ff710826` | 고정, OS별 추출 내용 검증 필요 |
| Node | nvm으로 24.x 최신 버전 설치 | 실제 버전 기록 |
| Playwright 프로젝트 lock | 1.65.0 | 원본 고정, browser 정합 검증 필요 |
| Git, Azure CLI, Copilot CLI, sbx CLI, aca CLI | 설치 경로에서 제공하는 최신 버전, 기존 설치는 자동 업데이트하지 않음 | 실제 버전 기록 |
| Copilot의 각 OS/build/backend | 공식 지원 조건 | `TBD(검증 필요)` |
| workload와 Playwright v3 mixin | 실제 사용한 tag와 digest 기록 | `TBD(검증 필요)` |
| Playwright mixin 호출 인자 | `--kit-arg playwright.version=1.65.0` | 실제 browser 정합과 E2E 리허설 필요 |
| source mixin build/frontend/base digest/architecture | Docker/Buildx와 busybox 참고 | `TBD(검증 필요)` |
| ACA image ID/revision, tier/architecture | public copilot image 후보 | `TBD(검증 필요)` |
| exact-host allowlist | 모델/npm/archive/browser 각각 기록 | `TBD(검증 필요)` |
| Azure region/quota/예상 비용 | Korea Central 후보, 개인 구독별 확인 | `TBD(검증 필요)` |
| Windows VM 이미지/SKU | appmod-box 참고값, Trusted Launch 유지 | `TBD(검증 필요)` |
| VM 도구 버전/설치 checksum/중첩 가상화 | 선택 경로 | `TBD(검증 필요)` |
| checkpoint 패치와 확장 완성본 | 리허설 후 생성 | `TBD(검증 필요)` |
| 실제 모듈 소요 시간/다운로드/cache | 현장과 같은 network에서 확인 | `TBD(검증 필요)` |
| 원격 template URL/public/template 설정/자료 라이선스 | 원격 생성 전 확정 | `TBD(검증 필요)` |

계정, 구독 ID와 token은 공개 버전표에 쓰지 않는다.

## 리허설 필수 통과 조건

다음은 **현재 미통과**이며 실제 실행 전 자원, 권한, 비용과 모델 호출에 대한 별도 승인을 확인한다.

- [ ] 각 지원 OS에서 동일 명령의 OFF/ON 결과, 실제 도구와 bypass 없음 확인
- [ ] 자동 grant 밖의 외부 canary와 Denied 우선순위, 최소 Read-Only/Read-Write 차이 확인
- [ ] host ON, Docker v3 기본, Playwright 조합, ACA에서 `npm ci`, unit, build와 E2E 각각 기록
- [ ] mixin `version=1.65.0`, 실제 browser 정합과 추가 다운로드 필요 여부 확인
- [ ] 각 OS와 ACA에서 앱 추출 파일 목록/내용 동일성, clean 기준 commit, baseline 태그와 remote 없음 확인
- [ ] 추출 앱에서 원본 agent 설정과 MCP가 로드되지 않음 확인
- [ ] 템플릿의 `AGENTS.md` 로드 여부와 실습 결과에 미치는 영향을 각 환경에서 확인하고 기록
- [ ] 템플릿에 `.github/copilot-instructions.md`, MCP 설정, custom agent와 승인된 구문 검사 외의 workflow가 없음 확인
- [ ] sandbox ON에서 부모 실습 문서와 `checkpoints/` 접근 확인. 패치가 읽히면 **강사 시점 배포로 운영 변경**
- [ ] 바깥 저장소의 `workspace*/`와 `evidence/` 추적 제외, 참가자 전역 설정 영향 기록
- [ ] Copilot 모델 인증과 Git/gh 인증을 분리하고 필요한 service만 설정
- [ ] 고정 v3 workload/mixin 조합, 지원 CPU architecture와 설치 시간 확인
- [ ] clean 앱에서 Direct 즉시 전파와 Clone read-only source, VM/host 양쪽 remote와 fetch/diff 확인
- [ ] 각 network 요청의 허용/차단 decision과 실제 결과 연결, OS별 한계 기록
- [ ] 직접 제작 mixin의 source build/인자/파일과 기존 접근 범위 비교, OCI publish 없이 수행
- [ ] ACA 정확한 ID의 Running/Stopped/Running과 remote 같은 파일 hash 확인
- [ ] 결과 파일 회수와 untracked/ignored/실행 코드 검토, 문자 인코딩/줄바꿈 한계 확인
- [ ] 중복 이름/자원 없이 cleanup 후 snapshot/disk/volume와 비용 자원 잔존 확인
- [ ] VM 선택 경로는 별도 승인 후 배포/Bastion/도구/재부팅/모듈별 통과/회수/VM 환경 삭제 확인
- [ ] 승인된 VM 보안 유형을 낮추지 않고 실제 Docker 중첩 microVM을 확인. 미통과면 개인 PC 경로 안내
- [ ] 실제 현장 network에서 처음부터 끝까지 진행하고 시간표/녹화/진단표 수정

녹화와 스크린샷에는 실행 날짜와 버전을 표시한다. 합성 터미널 출력을 실제 기록처럼 쓰지 않는다.

## 패치 제작과 자료 배포

검증된 앱 결과만 baseline 대비 binary patch로 만든다. [체크포인트 절차](../checkpoints/README.md)를 따라 별도 clean 추출본에 적용하고 테스트한다. 패치는 템플릿의 `checkpoints/` 파일로 배포하며 제작 커밋 SHA를 참가자 복구 기준으로 삼지 않는다.

원격 공개 전에 MIT 초안의 권리자/라이선스와 제3자 고지를 확인한다. public template 플래그 설정 후 **별도 개인 계정의 새 private 저장소**를 만들어 기본 브랜치 파일만으로 안내를 진행할 수 있는지 확인한다. fork를 요구하거나 템플릿 원격에 참가자 push를 요청하지 않는다.

## 현재 정적 검사 범위

허용 검사는 PowerShell `Parser.ParseFile`, `bash -n`, `az bicep build`와 Markdown 상대 링크다. 실행 스크립트 자체를 돌리거나, Tailspin 압축본을 다운로드하거나, Copilot/Docker/ACA/VM 실행과 Azure 배포, 모델 호출을 하지 않는다.

정적 검사의 실제 결과는 최종 인계에 기록한다. 이 절의 체크박스는 정적 검사 성공만으로 체크하지 않는다.
