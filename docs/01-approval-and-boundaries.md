# 1. 실습 공통 기준

이 문서는 이후 실습 문서 02~05에서 공통으로 적용할 기준을 안내한다. 실습에 앞서 안전 수칙과 실행 위치를 확인하고, 실행 승인, 모델의 거부와 정책 차단을 구분해 관찰 결과를 기록하는 방법을 익힌다. 이 문서에서는 리소스를 만들거나 설정을 변경하지 않는다.

## 실습 전 확인

교육용 데이터만 사용한다. 실제 자격 증명, SSH 키, 회사 `.env`와 고객 자료를 삭제하지 말고, 처음부터 이런 자료가 없는 별도의 교육용 폴더를 선택한다. 전역 설정, 조직 정책과 기존 허용 설정(grant)을 먼저 기록한다.

## 실행 위치

이후 실습에서는 다음 표기로 명령을 실행할 위치를 구분한다.

- **HOST**: 개인 PC 또는 실습용 Windows VM
- **COPILOT CLI**: HOST에서 실행하는 Copilot CLI의 자체 샌드박스 세션과 그 도구
- **DOCKER VM**: 로컬 Linux microVM 내부
- **ACA REMOTE**: Azure microVM의 원격 셸

Docker Sandboxes와 ACA의 제어 명령인 `sbx`와 `aca`는 HOST에서 실행한다.

## 환경별 비교

| 항목 | Copilot CLI 자체 샌드박스 | Docker Sandboxes | ACA Sandboxes |
| --- | --- | --- | --- |
| Copilot 작업 실행 위치 | HOST | 로컬 Linux microVM | Azure microVM |
| 격리와 접근 제한 | 도구별 OS 샌드박스와 CLI 내부 정책 검사 | 별도 커널을 가진 VM과 공유/프록시 정책 | 원격 VM, RBAC와 egress |
| 파일 접근 | 유효한 경로 허용 설정에 따름 | Direct 공유 또는 Clone | 원격 파일 사용, HOST 자동 마운트 없음 |
| 네트워크 설정 | `outbound` ON, `local-network` OFF가 기본이며 OS별 차이 있음 | preset, kit, 개인 및 조직 정책의 조합 | 정책이 없으면 나가는 트래픽 제한 없음 |
| 작업 결과 | HOST에 남음 | Direct는 HOST에 즉시 반영, Clone은 별도 회수 | 파일 API 등으로 별도 회수 |

## 승인과 정책 차단

Copilot의 실행을 `--yolo` 또는 `--allow-all`을 통해 자동 승인해도 샌드박스의 파일 및 네트워크 접근 제한은 별도로 적용된다.

## 관찰과 기록

02 실습의 준비 단계에서 [관찰 기록 양식](../evidence-template/observation.md)을 `<WORKSHOP_DIR>/evidence/observation.md`로 복사한다. 이후 각 실습에서 확인을 마칠 때마다 관찰표의 `Lab별 관찰`에 한 행씩 직접 작성한다. 명령 출력과 로그 파일은 해당 실습 문서에 안내된 `evidence/lab-*` 폴더에 저장하고, 관찰표의 `근거 파일`에 경로를 적는다.

각 행에는 실습 단계, 실행 위치와 정확한 명령, 기대 결과, 실제 출력과 종료 코드, 승인 및 정책 결정, 파일 변경 전후 해시를 적는다. 실행하지 않았거나 시간 초과한 항목도 그대로 표시한다. 비밀이나 개인 데이터는 기록하지 않는다.

아래 표는 관찰표의 `판정` 열에 넣을 값을 고르는 참고표다. 실제 결과를 이 문서에 적지 않는다. 모델의 설명은 실제 명령 출력과 같은 원자료를 대신하지 못한다.

| 상황 | 판정 |
| --- | --- |
| 모델이 요청을 거부해 명령을 호출하지 않음 | `MODEL_REFUSAL` |
| 실행 승인을 기다리는 중 | `APPROVAL_REQUIRED` |
| 실행한 요청과 일치하는 정책 차단 기록 확인 | `POLICY_DENIED` |
| 운영체제 또는 백엔드 미지원 | `UNSUPPORTED` |
| DNS, 인증, 패키지 또는 할당량 오류 | `ENVIRONMENT_FAILURE` |
| 의도한 위치에서 상태 확인 | `SUCCESS` |

## 실패 원인과 복구

HTTP나 DNS 오류만으로 정책 차단이라 단정하지 말고, 실행과 연결된 정책 기록이 없으면 원인을 미확정으로 남긴다. 차단을 확인하거나 해결하려고 정책을 우회하거나 전체 권한을 허용하지 않는다.

## 다음 실습

다음 실습에서 위 기준을 적용하고 결과를 비교한다.

1. [Copilot CLI 자체 샌드박스](02-copilot-local-sandbox.md)를 끈 상태, 켠 상태와 최소 권한을 부여한 상태를 비교한다.
2. [Docker Sandboxes](03-docker-workspaces-and-network.md)의 Direct와 Clone 공유 방식 및 네트워크 정책을 살펴본다.
3. [Docker mixin](04-docker-mixins.md)으로 도구를 추가하고 접근 제한이 달라지는지 확인한다.
4. [ACA Sandboxes](05-aca-sandboxes.md)에서 원격 파일과 네트워크를 확인하고, 중지 후 재개와 결과 회수를 살펴본다.
