# Copilot CLI의 실행 경계를 설계하고 검증하기

같은 Tailspin Toys 과제를 Copilot CLI 자체 샌드박스, Docker Sandboxes, Azure Container Apps(ACA) Sandboxes에서 수행하고 파일, 네트워크, 자격 증명과 결과 회수 경계를 비교하는 대면 워크숍이다. 대상은 AI 코딩 도구를 사용하는 중고급 개발자다.

> **작성 단계 초안:** 모든 실습 명령과 기대 결과는 **미검증**이다. 정적 검사와 실제 실행 검증은 다르다. 제품 설치, 샌드박스 실행, Tailspin 다운로드, 빌드, 테스트, 모델 호출과 Azure 배포를 이 자료 제작 과정에서 실행하지 않는다. `TBD(검증 필요)` 값을 확정하기 전에는 현장 배포본으로 사용하지 않는다.

## 개인 실습 저장소 준비

이 자료는 public template으로 공개할 예정이다. 원격 저장소 생성, public 전환과 template 플래그 설정은 후속 작업이다. 예시 URL은 실제 배포 주소가 아니다.

1. 강사가 안내한 템플릿에서 **Use this template > Create a new repository**를 선택한다.
2. 소유자는 **개인 계정**, 공개 범위는 **Private 권장**으로 선택한다. fork가 아니라 별도 저장소를 만든다.
3. 개인 저장소를 클론한다. 그 루트를 `<WORKSHOP_DIR>`로 사용한다.

CLI를 쓴다면 아래 자리표시자를 실제 값으로 바꾼다(미검증).

```powershell
gh repo create <개인계정>/<실습저장소> --template <템플릿소유자>/<템플릿저장소> --private --clone
Set-Location <실습저장소>
```

템플릿은 기본 브랜치의 파일만 복사된다고 가정한다. 원본 커밋 이력, 태그와 브랜치를 복구 기준으로 삼지 않는다. 과제는 `tasks/`, 복구 자료는 `checkpoints/`의 파일로 제공한다.

## 목표와 시간표

승인, 모델 거부와 정책 차단을 구분하고, 최소 grant, Direct/Clone, v3 mixin, ACA 원격 상태 보존과 결과 검토를 증거로 설명한다. 제품의 안전성 순위를 매기지 않는다.

| 순서 | 내용 | 기본 | 확장 |
| --- | --- | ---: | ---: |
| 1 | 승인과 격리 경계 | 10분 | 10분 |
| 2 | 현장 preflight와 baseline | 10분 | 10분 |
| 3 | Copilot OFF/ON와 최소 grant | 30분 | 30분 |
| 4 | Docker Direct/Clone와 네트워크 | 30분 | 30분 |
| 5 | published v3 mixin / 직접 만들기 | 20분 | 50분 |
| 6 | 휴식 | 5분 | 5분 |
| 7 | ACA 원격 실행과 회수 | 35분 | 35분 |
| 8 | 비교와 정리 | 10분 | 10분 |
| 합계 | 설치와 계정 준비 제외 | 150분 | 180분 |

## 자료 구조

`docs/`는 순서대로 읽는 실습 문서, `tasks/`는 고정 SHA의 과제 원문, `scripts/`는 앱 추출 도우미다. `mixins/`는 180분 확장 골격, `windows-vm/`은 선택 사전 준비용 자립형 azd 템플릿이다. `checkpoints/`의 패치는 예행 연습 후 생성한다.

`workspace*/`는 앱의 독립 Git 저장소이며 실습 자료 저장소에서 추적하지 않는다. `evidence/`는 사람이 원자료와 관찰표를 저장하는 폴더다. 앱 안의 `workspace/evidence/summary.md`는 Copilot이 작성하는 과제 산출물로, 사람이 작성하는 관찰 기록과 다르다.

관찰표는 참가자가 확인 명령의 출력을 파일로 저장한 뒤 직접 작성한다. Copilot은 마지막 비교에서 원자료 요약만 보조한다. GitHub 이슈는 만들지 않는다.

## 안전 범위

개인 PC와 개인 Azure 구독, 본인의 짧은 만료 fine-grained PAT(`Copilot Requests`)를 사용한다. 토큰, 구독 ID와 고객 자료를 기록하거나 공개 저장소에 올리지 않는다. 실제 비밀 대신 dummy 파일만 쓴다. `gitignore`는 접근 통제가 아니다.

GitHub cloud sandbox와 Docker cloud는 비교 설명만 한다. 원격 push, PR 작성, 앱 배포, ACA ingress 공개는 실습에서 제외한다. 기존 조직 정책과 보안 기준을 낮추거나 우회하지 않는다. Windows VM은 별도 사전 준비 경로이지 네 번째 샌드박스 제품이 아니다.

템플릿에는 `.github/copilot-instructions.md`, MCP 설정, custom agent, Actions workflow를 넣지 않는다. 참가자의 전역 설정과 조직 정책은 별도로 기록한다.

## 근거와 라이선스

2026-11-24 조사와 2026-11-25 VM 추가 조사를 기준으로 작성했다. [공식 출처와 고정 revision](docs/sources.md)을 확인한다.

**라이선스 종류 확정 필요:** 워크숍 자료의 [LICENSE](LICENSE)는 MIT 초안이다. 원격 공개 전에 권리자와 종류를 확정한다. Tailspin 원문에는 별도의 원본 MIT 고지를 유지한다.
