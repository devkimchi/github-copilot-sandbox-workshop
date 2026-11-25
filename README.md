# # GitHub Copilot 샌드박싱 워크샵

AI 코딩 에이전트에게 어디까지 맡겨도 될까요? 이 워크숍에서는 같은 Tailspin Toys 과제를 세 가지 실행 환경에서 차례로 수행하고, 파일, 네트워크와 자격 증명에 접근할 수 있는 범위, 결과를 회수하는 방법이 어떻게 달라지는지 직접 확인합니다.

1. **Copilot CLI 자체 샌드박스**: 로컬에서 승인과 최소 권한(grant)을 다룹니다.
2. **Docker Sandboxes**: Direct와 Clone 워크스페이스, 네트워크 정책과 mixin을 다룹니다.
3. **Azure Container Apps(ACA) Sandboxes**: 원격 실행, egress, 상태 보존과 결과 회수를 다룹니다.

세 환경의 접근 범위를 순서대로 비교합니다. 제품의 안전성 순위는 매기지 않습니다. 관찰한 증거로 자신의 작업에 맞는 접근 범위를 선택합니다.

대상은 AI 코딩 도구를 사용하는 중고급 개발자입니다.

## 배우는 내용

- 사용자 승인, 모델의 거부와 정책 차단을 구분합니다.
- 필요한 만큼만 권한을 허용하고 그 결과를 증거로 남깁니다.
- Docker의 Direct와 Clone 워크스페이스, published v3 mixin을 비교합니다.
- ACA에서 원격 상태를 보존하고 결과를 안전하게 회수합니다.
- 실습이 끝나면 만든 자원과 자격 증명을 정확히 정리합니다.

## 저장소 구조

```text
.
├── docs/               # 순서대로 읽는 실습 문서
├── tasks/              # 고정 SHA 기준의 과제 원문
├── scripts/            # Tailspin 앱 추출 스크립트
├── checkpoints/        # 복구 스크립트와 단계별 패치
├── mixins/             # 180분 확장용 mixin 템플릿
├── evidence-template/  # 관찰표와 비교표 양식
└── windows-vm/         # 선택 사항인 Windows VM azd 템플릿
```

실습 중에 생기는 `workspace*/`와 `evidence/`는 이 저장소에서 추적하지 않습니다.

- `workspace*/`: 과제를 수행하는 앱의 독립 Git 저장소입니다.
- `evidence/`: 참가자가 확인 명령의 출력과 관찰표를 저장하는 폴더입니다.

앱 안의 `workspace/evidence/summary.md`는 Copilot이 작성하는 과제 산출물입니다. `evidence/` 관찰 기록은 참가자가 직접 작성합니다.

## 시작하기 전에

설치와 계정 준비는 실습 시간에 포함되지 않습니다. 워크숍 전에 [사전 준비](docs/00-prerequisites.md)를 마칩니다.

- 개인 PC와 개인 GitHub 계정
- 짧은 만료 기간의 개인 fine-grained PAT(`Copilot Requests` 권한)
- Docker Sandboxes를 실행할 수 있는 환경
- 비용을 감당할 수 있는 개인 Azure 구독과 교육 전용 리소스 그룹

로컬 환경을 준비하기 어렵다면 [선택 사항인 Windows VM](docs/00-windows-vm.md)을 사용할 수 있습니다. 이 VM은 샌드박스 실습 환경을 준비하는 데 사용합니다.

## 개인 실습 저장소 만들기

이 템플릿으로 별도의 개인 저장소를 만듭니다. 저장소는 fork하지 않습니다.

1. 이 저장소에서 **Use this template > Create a new repository**를 선택합니다.
2. 소유자는 **개인 계정**, 공개 범위는 **Private**을 권장합니다.
3. 만든 저장소를 클론합니다. 클론한 폴더의 루트를 실습 문서의 `<WORKSHOP_DIR>`로 사용합니다.

GitHub CLI를 사용한다면 다음 명령의 플레이스홀더를 바꿔 실행합니다.

```bash
# zsh/bash
gh repo create "<개인계정>/<실습저장소>" --template devkimchi/github-copilot-sandbox-workshop --private --clone
cd "<실습저장소>"
```

```powershell
# PowerShell
gh repo create "<개인계정>/<실습저장소>" --template devkimchi/github-copilot-sandbox-workshop --private --clone
Set-Location "<실습저장소>"
```

템플릿으로 만든 저장소에는 기본 브랜치의 파일만 복사되며, 원본의 커밋 이력, 태그와 브랜치는 복사되지 않습니다. 과제는 `tasks/`, 복구 자료는 `checkpoints/`의 파일을 사용합니다.

## 실습 진행

기본 과정은 150분, 확장 과정은 180분입니다. 확장 과정에서 늘어난 30분은 mixin을 직접 만드는 데 씁니다.

| 순서 | 실습 문서 | 기본 | 확장 |
| --- | --- | ---: | ---: |
| 1 | [승인과 접근 범위](docs/01-approval-and-boundaries.md) | 10분 | 10분 |
| 2 | [Lab 0/1: baseline과 Copilot OFF/ON](docs/02-copilot-local-sandbox.md) | 40분 | 40분 |
| 3 | [Lab 2: Docker Direct/Clone와 네트워크](docs/03-docker-workspaces-and-network.md) | 30분 | 30분 |
| 4 | [Lab 2B: published mixin과 직접 만들기](docs/04-docker-mixins.md) | 20분 | 50분 |
| - | 휴식 | 5분 | 5분 |
| 5 | [Lab 3: ACA 원격 격리와 상태](docs/05-aca-sandboxes.md) | 35분 | 35분 |
| 6 | [비교와 정리](docs/06-review-and-cleanup.md) | 10분 | 10분 |
| | **합계** | **150분** | **180분** |

모든 단계는 같은 과제로 진행합니다.

- 기본 과제: [05. 카탈로그 요약](tasks/05-catalog-summary.md)
- 대안 과제: [02. 게임 정렬](tasks/02-sort-games.md)

앱을 준비할 때는 [추출 스크립트](scripts/README.md)를 사용합니다. 단계를 놓쳤다면 [복구와 패치 운영](checkpoints/README.md)을 참고해 다음 단계의 시작 상태로 돌아갑니다. 문제가 생기면 [문제 해결](docs/troubleshooting.md)을 확인합니다.

## 기록과 정리

### 관찰 기록

[관찰표](evidence-template/observation.md)와 [비교표](evidence-template/comparison.md)를 `evidence/`로 복사해 사용합니다. 확인 명령의 출력을 먼저 파일로 저장한 뒤 표는 직접 작성합니다. Copilot은 마지막 비교 단계에서 원자료 요약만 돕습니다.

### 안전 수칙

- 토큰, 구독 ID와 고객 자료를 기록하거나 공개 저장소에 올리지 않습니다.
- 비밀 파일은 dummy 파일로 준비합니다. 실제 비밀은 사용하지 않습니다. `.gitignore`는 접근 통제가 아닙니다.
- 원격 push, PR 작성, 앱 배포와 ACA ingress 공개는 실습하지 않습니다.
- 조직 정책과 보안 기준을 낮추거나 우회하지 않습니다.
- GitHub cloud sandbox와 Docker cloud는 설명으로만 비교합니다.

템플릿에는 저장소 작업 지침인 [AGENTS.md](AGENTS.md)가 포함되어 있습니다. 자신의 Copilot 전역 설정과 조직 정책은 관찰 기록에 따로 적습니다.

### 비용과 정리

Azure 비용은 본인 구독에 발생합니다. 실습이 끝나면 [비교와 정리](docs/06-review-and-cleanup.md)의 체크리스트를 따릅니다.

- 결과를 먼저 회수한 뒤, 자신이 만든 Docker 샌드박스와 ACA 샌드박스를 정확한 이름이나 ID로 삭제합니다.
- compute를 중지해도 저장소와 네트워크 비용이 남을 수 있습니다. 삭제 후 Azure portal에서 남은 자원을 확인합니다.
- 교육용 PAT와 Docker, ACA에 저장한 본인 자격 증명을 회수합니다.
- Windows VM을 만들었다면 결과를 물리 PC로 먼저 회수합니다. 배포했던 PC의 `windows-vm/` 폴더에서 VM 전용 구독과 환경 이름을 확인한 뒤 삭제합니다.

Windows VM 삭제 명령은 zsh/bash와 PowerShell에서 동일합니다. `<VM_ENV_NAME>`을 실제 환경 이름으로 바꿉니다.

```bash
# zsh/bash
azd down --environment "<VM_ENV_NAME>"
```

## 강사용 자료

- [운영 가이드](docs/instructor-guide.md)
- [배포 전 체크리스트](docs/release-checklist.md)

## 출처와 라이선스

공식 출처와 고정 revision은 [출처](docs/sources.md)에서 확인합니다.

워크숍 자료는 [LICENSE](LICENSE)를 따릅니다. 다음 자료는 원본 고지를 따로 유지합니다.

- Tailspin Toys 과제 원문: 각 과제 파일의 MIT 고지
- mixin: [mixins/LICENSE-APACHE-2.0](mixins/LICENSE-APACHE-2.0), [mixins/NOTICE](mixins/NOTICE)
- Windows VM 템플릿: [windows-vm/LICENSE-UPSTREAM](windows-vm/LICENSE-UPSTREAM)

<!-- HUMANIZE-SUMMARY -->
원문 글자 수: 4,749 | 윤문본 글자 수: 4,749 | 변경률: 0.0% | 탐지: S1 0건, S2 0건 | 자체검증: 6/6 | 등급: B
변경 하이라이트: 룰북에 매핑되는 AI 티 패턴을 찾지 못해 본문을 수정하지 않았습니다.
<!-- /HUMANIZE-SUMMARY -->
