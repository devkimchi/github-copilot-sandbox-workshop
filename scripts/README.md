# 앱 추출 스크립트

**실행 미검증.** PowerShell 7 이상 또는 Bash에서, 개인 워크숍 저장소 루트를 현재 위치로 사용한다. Git, curl과 tar가 필요하다. Windows PowerShell 5.1의 `curl` 별칭을 피하려고 `.ps1`은 `curl.exe`와 `tar.exe`를 명시한다.

```powershell
pwsh -File .\scripts\get-tailspin.ps1 -Target workspace
```

```bash
bash scripts/get-tailspin.sh workspace
```

대상은 현재 폴더 바로 아래 `workspace` 또는 `workspace-이름`만 허용한다. 기존 대상은 덮어쓰지 않는다. 다운로드/추출 임시 폴더만 자동 정리한다. Git 단계에서 실패해 생긴 부분 workspace는 보존하며 오류를 보고한다. 실패한 대상은 사람이 확인하고 **다른 이름으로 다시 시작**한다.

고정 SHA `9cd9a450f923c7a084bd47d661877d82ff710826`의 압축본을 받고 명시 목록만 추출한다. 네트워크에서는 전체 스냅샷 압축본을 받지만 최종 폴더에는 앱 파일만 남는다. `.github/`, `.vscode/`, `.devcontainer/`와 원본 문서는 제외한다. 원본 `.gitignore`와 MIT `LICENSE`는 유지한다.

새 독립 Git 저장소의 `main`에 기준 커밋과 `baseline` 태그를 만들고 remote는 추가하지 않는다. 원본 SHA와 로컬 기준 commit SHA는 다르며 참가자끼리 로컬 SHA를 같게 만들 필요는 없다. `core.autocrlf=false`는 새 workspace 로컬 설정이다. 원본 commit의 내용은 고정하지만 별도 배포용 압축본 checksum은 `TBD(검증 필요)`다.

다음은 참가자가 실행할 확인 명령이며 **미검증**이다.

```powershell
git -C .\workspace status --short
git -C .\workspace remote -v
git -C .\workspace ls-files
git -C .\workspace rev-parse baseline
git status --short --ignored
```

기대는 clean, remote 없음, 앱 파일만 존재, 바깥 저장소에서 workspace 무시다. 과거 연구 부록 A.7은 54개 추적 파일을 보고했지만 이 스크립트의 실행 결과가 아니다. OS별 파일 목록과 내용의 동일성은 예행 연습에서 확인한다.

`npm ci`, 테스트, Copilot, Docker와 Azure는 실행하지 않는다. [Lab 0/1](../docs/02-copilot-local-sandbox.md)에서 다음 절차를 확인한다.
