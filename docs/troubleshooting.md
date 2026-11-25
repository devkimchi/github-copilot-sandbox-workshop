# 문제 해결

**아래 진단 명령과 제품별 기대 결과는 미검증**이다. [출처](sources.md), [강사 운영](instructor-guide.md). 실제 오류를 원자료에 남기며 성공처럼 바꾸지 않는다.

## 공통 진단 순서

실행 위치와 CWD, tool/version과 OS/backend, 실제 도구 호출/승인, stdout/stderr/종료 코드, 유효 정책과 decision을 순서대로 확인한다. 같은 명령을 사람이 HOST에서 실행한 성공을 sandbox 성공으로 대체하지 않는다. 모델 거부나 HTTP 오류만으로 정책 차단을 확정하지 않는다.

| 증상 | 확인 | 제한된 복구와 기록 |
| --- | --- | --- |
| 추출 대상 존재 | `workspace*` 경로와 기존 내용 | 덮어쓰지 않는다. 다른 이름으로 시작. 부분 결과는 보존 |
| 추출 다운로드 실패 | GitHub archive redirect, `github.com`/`codeload.github.com`, 도구와 종료 코드 | 실제 network 문제부터 해결. 다른 SHA/전체 clone으로 바꾸지 않음 |
| Git 기준 commit 실패 | Git 설치/버전, 잠금, 로컬 정책 | 부분 workspace 보존, 원격/전역 identity를 임의 변경하지 않음 |
| PowerShell 스크립트가 구버전 오류 | `$PSVersionTable.PSVersion` | 추출/복구는 PowerShell 7로 실행. 조직 execution policy 우회 금지 |
| baseline unit 실패 | HOST `npm ci`, Node >=22.13, 원본 파일과 lock | 일반 환경부터 해결. sandbox 차단으로 오분류 금지 |
| ON/OFF가 같음 | 실제 status/정책, 같은 도구와 명령인지, canary 경로/자동 grant | 임시 폴더와 부모 Git 저장소 밖의 기존 dummy 파일로 재배치 |
| sandbox 미지원 | 실제 OS build/KB와 backend | `UNSUPPORTED` 기록, 조직 정책 우회 없이 지원 환경 사용 |
| grant해도 deny | explicit Denied 우선순위와 기존 사용자/조직 정책 | 본인이 추가한 교육용 deny만 제거. 전체 홈 grant 금지 |
| CLI 네트워크 차단이 일관되지 않음 | proxy 사용과 Windows host rules 한계, localhost/private-network 의미 | 해당 도구/요청 범위만 결론. 통제 우회 실습으로 확장하지 않음 |
| E2E 실패 | browser 설치, cache 경로, localhost, 일반 build 오류 | 원인별 최소 허용. 무조건 모든 network 허용하지 않음 |
| Docker 시작 실패 | 지원 OS/CPU, hypervisor/KVM, VM이면 중첩 가상화 | Docker Desktop 성공으로 대체 판정하지 않음 |
| Direct native package 오류 | Windows/macOS host의 node_modules 공유 여부 | clean `workspace-docker`와 Clone에서 VM 내부 `npm ci` 사용 |
| Clone source 쓰기 실패 | `/run/sandbox/source`와 실제 read-only 오류 | 정상 기대. source가 읽힌다는 점과 별개로 기록 |
| Clone fetch 실패 | 실행 중인지, 앱 저장소의 실제 sandbox remote/branch | 먼저 해당 sandbox 상태 확인. fetch가 VM을 자동 시작하지 않음 |
| mixin 버전/feature 충돌 | v3 `requires`/`provides`, descriptor와 workload 정합 | 새 이름의 sandbox로 검증. v2/legacy와 `sbx kit add`로 우회 금지 |
| Playwright mixin 후에도 E2E 실패 | 프로젝트 1.65.0, 전역과 로컬 패키지, Chromium release | 원인이 맞을 때만 브라우저 설치. download decision 별도 기록 |
| source mixin build 실패 | Docker/Buildx, base image 접근과 architecture | 제작 경로 문제로 분류. published 사용과 전제를 혼동하지 않음 |
| Copilot 인증 실패 | PAT 유형/만료/Requests, entitlement, 정확한 endpoint | Git/gh 성공을 모델 성공으로 취급하지 않음 |
| sbx credential 오류 | `copilot` service와 별도 `github` service | 필요한 service만 본인 보안 입력. 강사 token 공유 금지 |
| ACA doctor/RBAC 실패 | 본인 구독/group과 Data Owner, 권한 전파 | group 생성 성공을 data plane 성공으로 취급하지 않음 |
| ACA 모델 호출 실패 | credential ID와 injection, egress denied host/정책 전파 | 인증/정책 분리. wildcard 확대나 default Allow로 해결하지 않음 |
| ACA 원격 다운로드 실패 | archive redirect와 npm allowlist | 확인된 호스트만 좁게 추가. 다른 실행 위치인지도 확인 |
| ACA stop/resume 판정 혼란 | 정확한 같은 ID, state 전환 완료, remote 절대 경로 | 새 create 금지. 파일 hash를 memory 복원으로 일반화하지 않음 |
| ACA `Disabled` 등 예외 상태 | `aca sandbox get --id <ID> -o json` | 원문 오류 기록, 정상 흐름 성공으로 채우지 않음 |
| ACA 회수 후 hash 다름 | HOST 문자열 저장/줄바꿈/인코딩 | lifecycle hash는 remote끼리 비교, 회수본은 검토용으로 표시 |
| checkpoint 없음/검사 실패 | 실제 패치 파일과 고정 앱 snapshot | 현재 패치 미제공. 빈 패치 생성 금지, backup 보존, clean 다음 Lab 진행 |
| 복구 스크립트 중단 | 대상 독립 .git/이름, backup 위치, realpath 지원, 특수 파일명 | snapshot을 별도 새 폴더에 풀어 확인. 기존 위에 무작정 덮어쓰지 않음 |
| VM 배포 실패 | 라이선스 자격, 이미지 버전, 지역/SKU/Bastion/quota | 실제 Azure 오류 확인. 보안 유형 자동 하향 금지 |
| VM Run Command에서 한글이 깨지고 `TerminatorExpectedAtEndOfString` 발생 | `stage-workshop-tools`의 실제 오류와 전달 스크립트 인코딩 | Windows PowerShell 5.1에서 BOM 없는 UTF-8을 잘못 읽을 수 있다. Run Command 진입 스크립트는 ASCII로 유지하고, 전달하는 설치 스크립트는 UTF-8 BOM을 포함한다. 수정 후 같은 azd 환경에서 다시 배포하며 기존 자원을 임의로 삭제하지 않는다 |
| VM 설치 스크립트 실패 | 실제 사용자 관리자 세션, WinGet, 버전 가용성과 checksum | SYSTEM 실행 금지. 기존 도구 경고와 부분 설치를 기록 |
| VM Docker만 실패 | 승인된 중첩 가상화/보안 조합에서 sbx microVM 실제 실행 | 미검증이면 개인 PC에서 해당 모듈 진행 |
| 삭제 명령 실패/비용 남음 | 정확한 ID/이름과 snapshot/disk/volume/NAT/IP | 자원별 실제 상태 확인. 공용 group 일괄 삭제 금지 |

## 복구 전에 반드시 보존할 것

실제 명령과 실행 위치, 원래 설정, 관련 파일의 전후 상태, 출력과 policy decision을 먼저 저장한다. 패치 복구는 [체크포인트 운영](../checkpoints/README.md), 정리는 [마지막 실습](06-review-and-cleanup.md)을 따른다. token과 비밀이 들어간 원자료는 공유하지 않는다.

`MODEL_REFUSAL`, `APPROVAL_REQUIRED`, `POLICY_DENIED`, `UNSUPPORTED`, `ENVIRONMENT_FAILURE`, `SUCCESS`의 분류 기준을 유지한다. 로그가 부족하면 불명확하다고 쓰고 재현하지 않은 원인을 확정하지 않는다.
