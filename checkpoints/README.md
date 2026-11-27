# 체크포인트 운영

**스크립트 실행 미검증. 패치는 리허설 후 생성한다.** 정답/채점 자료가 아니라 시간이 초과했을 때 같은 기준 파일에서 다음 비교를 시작하기 위한 복구 자료다.

| 예정 파일 | 상태 |
| --- | --- |
| `task05-result.patch` | `TBD(검증 필요)`, 현재 파일 없음 |
| `task02-result.patch` | `TBD(검증 필요)`, 현재 파일 없음 |
| `mixin-example/` | `TBD(검증 필요)`, 확장 완성본은 아직 없음 |

빈 `.patch`를 성공 결과처럼 제공하지 않는다. Lab마다 같은 baseline에서 공통 과제를 반복하므로 누적 Lab 패치는 두지 않는다. 템플릿에 복사되지 않을 수 있는 제작 저장소 커밋 SHA/태그에 의존하지 않는다. 앱 추출 스크립트가 각 workspace에 만든 `baseline` 태그와 파일 내용을 기준으로 삼는다.

## 사용 전

Copilot 세션과 앱 프로세스를 종료한다. 백업에는 **ignored 파일, node_modules와 .git도 포함**되므로 공간과 시간이 필요하다. 교육용 dummy 외 실제 비밀을 넣지 않는다. 백업에 민감 정보가 있으면 공유하지 않는다.

복구 대상은 `workspace` 또는 `workspace-이름`의 **독립 Git 저장소**여야 한다. 워크숍 저장소 자체와 linked worktree는 받지 않는다. 패치와 backup은 대상 밖에 둔다. 다른 프로세스와 동시에 실행하지 않는다.

```powershell
# HOST, <REPOSITORY_ROOT>, 실제 패치가 검증되어 배포된 후에만
pwsh -File .\checkpoints\restore-checkpoint.ps1 -Target .\workspace -Patch .\checkpoints\task05-result.patch
```

```bash
bash checkpoints/restore-checkpoint.sh workspace checkpoints/task05-result.patch
```

Linux/ACA Bash 복구에는 GNU `realpath`의 `-m`이 필요하다. macOS에서 미지원이면 스크립트를 강행하지 말고 강사의 검증된 도구 경로 또는 수동 복구를 사용한다.

## 동작과 한계

1. 대상, 패치와 `baseline`을 검사한다.
2. `evidence/backup/`의 고유 폴더에 전체 snapshot, baseline 대비 binary diff와 상태를 저장한다. 백업 실패면 복구를 시작하지 않는다.
3. 사람이 정확한 대상과 백업 위치를 확인하고 **RESTORE**를 입력해야 진행한다.
4. untracked(ignored 제외) 파일을 백업 폴더로 옮긴다. tracked 파일과 index를 `git restore --source=baseline --staged --worktree -- .`로 복구한다. **HEAD와 브랜치는 움직이지 않으며 기존 commit 이력은 보존**한다.
5. `git apply --check`가 성공한 경우에만 `git apply`한다. 실패하면 오류를 알리고 중단한다. 자동 rollback 성공을 가장하지 않는다.

ignored 파일은 백업하되 workspace에서 제거하지 않는다. `node_modules`, DB와 cache는 필요 시 사람이 **정확한 파일/디렉터리**를 검토해 별도 정리한다. staged/unstaged 상태와 ignored 파일까지 이전 상태로 돌아가려면 snapshot을 **새 별도 폴더**에 풀어 확인한다. 기존 대상 위에 무작정 덮어쓰지 않는다.

복구 후 `git diff baseline`, `git status --short`와 실제 테스트를 확인하고 "제공 패치 사용"을 관찰표에 적는다. HEAD가 이전 feature commit에 남아 있으면 `git diff HEAD`는 baseline 대비 결과와 다를 수 있다.

## ACA 수동 경로

HOST에서 `aca sandbox fs write`로 실제 패치와 `.sh` 복구 스크립트를 전송한다. [ACA Lab](../docs/05-aca-sandboxes.md)의 절대 경로를 확인한다. ACA REMOTE에서 예컨대 `bash restore-checkpoint.sh /home/aca-workshop/workspace /home/aca-workshop/task05-result.patch /home/aca-workshop/backup`으로 실행한다. 백업은 원격에 생기므로 필요한 증거를 삭제 전에 회수한다.

## 리허설에서 생성할 때

clean baseline에 검증한 구현만 적용하고 새 파일도 staging한 뒤 `git diff --cached --binary baseline --output=<대상 밖 파일>`로 패치를 만든다. 별도 clean 추출본에서 `git apply --check`, 적용과 앱 테스트를 확인한 뒤 이 폴더에 배포한다. 생성 도구/버전, 원본 SHA와 파일 목록, 검증 로그를 강사 기록에 남긴다.

Copilot은 이 폴더를 과제 해결에 참조하지 않는다. ON 상태에서 부모 `checkpoints/`를 읽을 수 있는지 리허설한다. 읽을 수 있으면 **배포 방식을 강사 시점 배포로 변경**하고 문서도 고친다. 프롬프트 금지만으로 접근 통제가 된다고 주장하지 않는다.
