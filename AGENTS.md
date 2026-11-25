# 에이전트 작업 지침

## 프로젝트 목적

이 저장소는 Copilot CLI, Docker Sandboxes, Azure Container Apps Sandboxes의 파일, 네트워크, 자격 증명 접근 범위를 비교하는 워크숍 템플릿이다.

## 프로젝트 구조

```text
.
├── .github/            # 저장소 설정과 구문 검사 워크플로
├── checkpoints/        # 복구 자료
├── docs/               # 실습 문서와 강사용 가이드
├── evidence-template/  # 관찰 기록 양식
├── mixins/             # 확장 실습
├── scripts/            # 앱 추출 스크립트
├── tasks/              # 과제 원문
└── windows-vm/         # 선택적 VM 템플릿
```

## 작업 원칙

- 문서는 한국어로 작성하고 명령, 경로, 제품 이름은 정확히 유지한다.
- 한국어 문서 작성과 수정에는 `/korean-technical-writing` 스킬을 사용한다. 스킬을 사용할 수 없으면 기존 문서의 표현과 형식을 따른다.
- 요청한 범위에서 작업하고 기존 실습 흐름과 참가자 기록을 보존한다.
- 검증하지 않은 명령과 기대 결과는 미검증으로 표시한다. 실제 실행 결과나 성공 여부를 추측하지 않는다.
- 고정된 출처와 제3자 라이선스 고지를 유지한다.

## 검증

- 저장소 루트에서 변경 범위에 맞는 검사를 실행한다. 아래 스크립트 구문 검사는 Git에서 추적하는 파일만 대상으로 하므로 새 미추적 스크립트는 별도로 검사한다.
- Bash 스크립트 구문은 Bash에서 확인한다.

  ```bash
  set -o pipefail
  git ls-files -z -- '*.sh' | while IFS= read -r -d '' file; do
    bash -n "$file" || exit 1
  done
  ```

- PowerShell 스크립트 구문은 PowerShell에서 확인한다.

  ```powershell
  git ls-files -- '*.ps1' | ForEach-Object {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
      (Join-Path $PWD $_), [ref]$tokens, [ref]$errors
    ) | Out-Null
    if ($errors) { throw ($errors | Out-String) }
  }
  ```

- Azure CLI가 설치된 환경에서 Bicep 변경 사항을 `az bicep build --file windows-vm/infra/main.bicep --stdout`으로 확인한다.
- Markdown 링크를 확인한다. 스크립트 동작 테스트와 Markdown 린트는 아직 구성되지 않았다. 도입하면 실행 방법을 여기에 추가한다.
- 정적 검사와 실습 리허설을 구분하고 수행하지 못한 검증을 명시한다.
- 리허설 결과, 버전과 환경은 `docs/instructor-guide.md`를 기준으로 기록한다.

## 안전과 승인

- 다운로드, 리허설, 모델 호출, Azure 자원 배포는 실행 전에 사용자 승인을 받는다.
- 비밀, 개인 데이터, 참가자 기록과 인계 아카이브를 공개하지 않는다. `.gitignore`를 접근 통제로 취급하지 않는다.
- 기존 데이터와 사용자 변경 사항을 임의로 삭제하거나 보안 정책을 낮추지 않는다.

## 커밋과 풀 리퀘스트

- 워크숍 자료를 개발할 때는 논리적으로 독립된 변경마다 원자적(atomic) 커밋을 만들고 Conventional Commits 형식을 따른다.
- 개발 변경 사항은 원격 작업 브랜치에 푸시하는 것을 기본으로 한다. 사용자가 푸시를 금지하거나 다른 제한을 지정한 경우에는 그 지시를 따른다.
- 풀 리퀘스트를 만들기 전에 최신 기준 브랜치를 반영하고 변경 내용, 검증 결과, 미검증 사항을 기록한다.
- 참가자 실습에서는 원격 푸시와 풀 리퀘스트를 수행하지 않는다. 공개 배포와 기본 브랜치 반영은 별도 승인을 받는다.

## 배포 준비

- `docs/release-checklist.md`의 항목은 확인한 뒤에만 완료로 표시한다.
- 이 파일은 참가자의 템플릿 저장소에도 포함된다. 리허설에서 지침의 로드 여부와 실습 결과에 미치는 영향을 확인하고 기록한다.
