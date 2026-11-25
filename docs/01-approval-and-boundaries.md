# 승인과 접근 범위

## 1. 목표와 시간

10분. 승인 요청, 모델의 거부와 정책에 따른 차단을 구분한다. 아래 기대 동작은 **미검증**이며 공식 문서에 근거한 비교 모델이다. [출처](sources.md), [개요](../README.md).

## 2. 실행 위치

HOST는 개인 PC 또는 실습용 Windows VM이다. COPILOT CLI는 HOST에서 실행하는 자체 샌드박스 세션, DOCKER VM은 로컬 Linux microVM 내부, ACA REMOTE는 Azure microVM의 원격 셸이다.

## 3. 사전 조건과 현재 상태

교육용 데이터만 사용한다. 실제 홈 credential, SSH key, 회사 `.env`와 고객 자료를 제거하는 것이 아니라, **그런 자료가 없는 별도 교육용 폴더를 선택**한다. 전역 설정, 조직 정책과 기존 grant를 먼저 기록한다.

## 4. 비교와 질문

| 항목 | Copilot 자체 샌드박스 | Docker 로컬 | ACA |
| --- | --- | --- | --- |
| CLI 위치 | HOST | Linux microVM | Azure microVM |
| 격리 방식과 접근 제한 | 도구별 OS 정책과 CLI 내부 정책 검사 | 별도 커널 VM과 공유/프록시 정책 | 원격 VM, RBAC와 egress |
| 파일 | 유효 경로 grant | Direct 공유 또는 Clone | 원격 파일, 자동 host mount 없음 |
| 기본 네트워크 설명 | outbound ON, local-network OFF가 기본이며 OS 차이 있음 | preset/kit/개인/조직 정책 조합 | 정책이 없으면 unrestricted outbound |
| 결과 | host에 남음 | Direct 즉시 반영, Clone 명시적 회수 | 파일 API 등 명시적 회수 |

Copilot의 셸, 로컬 MCP/LSP와 자식 프로세스에는 OS 샌드박스가 적용된다. 내장 파일 도구는 CLI 내부 소프트웨어 정책 검사다. CLI 전체가 VM으로 옮겨지는 것은 아니다. 원격 MCP 서버의 실행 권한을 로컬 파일 정책이 제한하지도 않는다.

`--yolo`와 `allow-all`은 실행 승인 설정이다. Docker Copilot workload가 `copilot --yolo`로 시작해도 VM의 격리 방식과 mount, credential, network의 접근 범위는 별개로 유지된다. 반대로 승인 창이 떴다는 사실은 격리를 입증하지 않는다.

토의 프롬프트:

> 같은 작업이 승인되었는데 실패했다. 어떤 실행 위치, 명령, 정책과 파일 상태를 확인해야 원인을 말할 수 있는가?

## 5. 관찰 항목

정확한 도구 호출과 실행 위치, 승인 여부, 종료 코드, stdout/stderr, 파일 전후 hash와 정책 decision을 구분한다. 모델의 설명은 원자료를 대체하지 못한다.

## 6. 기대와 실제 결과

| 상황 | 기대 판정(미검증) | 실제 결과/근거 |
| --- | --- | --- |
| 모델이 명령을 호출하지 않음 | `MODEL_REFUSAL` | 참가자 작성 |
| 실행 승인에서 멈춤 | `APPROVAL_REQUIRED` | 참가자 작성 |
| 실행과 일치하는 policy deny 확인 | `POLICY_DENIED` | 참가자 작성 |
| OS/backend 미지원 | `UNSUPPORTED` | 참가자 작성 |
| DNS, 인증, package, quota 오류 | `ENVIRONMENT_FAILURE` | 참가자 작성 |
| 의도한 위치에서 상태 확인 | `SUCCESS` | 참가자 작성 |

## 7. 실패가 정상인 경우

정책 실험에서 실제 deny를 기대할 수 있다. HTTP/DNS 오류만으로 deny라고 단정하지 않는다. Windows Copilot host rules는 proxy를 따르지 않는 프로그램에 한계가 있고, Docker hostname 규칙도 IP 공유와 복호화하지 않는 연결 등 제한이 있다. 우회 공격을 실습하지 않으며 관찰한 도구와 요청 범위 안에서만 결론을 쓴다.

## 8. 복구와 checkpoint

개념 단계에는 패치가 없다. 미지원이면 승인된 대체 환경이나 강사의 **버전이 표시된 실제** 예행 기록을 사용하고 직접 실행과 구분한다. 전체 grant나 조직 deny 해제로 해결하지 않는다.

## 9. 정리

아직 리소스를 만들지 않는다. 이후 각 실습에서 만든 자원과 설정만 기록하고 되돌린다.
