# 결과 검토와 정리

## 1. 목표와 시간

10분. 원자료를 근거로 비교표를 완성하고 자신이 만든 자원만 정리한다. **아래 명령과 기대 결과는 미검증**이다. [출처](sources.md), [개요](../README.md).

## 2. 실행 위치

비교표와 host 코드 검토는 **HOST**, 최종 원격 파일 확인은 **ACA REMOTE/DOCKER VM**, 제어 명령은 HOST다.

## 3. 사전 조건과 현재 상태

삭제하기 전에 Clone commit과 ACA 결과를 회수한다. `evidence/observation.md`, `evidence/comparison.md`를 참가자가 직접 작성한다. 앱 내부의 `evidence/summary.md`는 과제 산출물이며 정책 증거가 아니다.

## 4. 검토 명령과 요약 프롬프트

HOST에서 회수한 diff, 새 파일, package/build script, CI, IDE task와 agent 설정을 검토한다. 샌드박스에서 나온 코드도 HOST에서 실행하면 HOST 권한으로 작동할 수 있다. 바로 `npm install`이나 build를 실행하지 않는다.

```powershell
# HOST, <REPOSITORY_ROOT>
git -C ./workspace status --short | Out-File ./evidence/review-status.txt
git -C ./workspace diff baseline --stat | Out-File ./evidence/review-stat.txt
Get-ChildItem ./evidence -Recurse -File
```

`.git/hooks`, ignored 파일과 전역 설정 등 `git diff`만으로 보이지 않는 상태도 검토한다. Direct 공유 경로 위험과 commit으로 회수한 코드 위험은 다르며 **fetch가 상대 `.git/hooks`까지 복사한다고 설명하지 않는다**.

Copilot을 활용한다면 사람이 골라서 비밀을 제거한 원자료만 제공한다.

```text
제공한 실제 명령 출력과 관찰표만 요약한다. 각 결론에 근거 파일을 연결하고
미실행, 기록 누락과 모순은 그대로 표시한다. 차단 원인을 추측하거나 빈 표를
성공으로 채우지 않는다. 판정과 비교표의 최종 작성은 참가자가 한다.
GitHub 이슈나 PR은 만들지 않는다.
```

## 5. 관찰 항목

"승인은 되었지만 막혔다", "ON에서도 읽을 수 있다", "Direct 즉시 반영", "Clone 회수", "mixin 요구 권한", "ACA 원격 격리와 상태 보존"의 여섯 문장을 원자료와 연결한다. 정책 강제, OS 지원, 일반 오류를 혼동하지 않는다.

## 6. 기대와 실제 결과

| 확인 | 기대 결과(미검증) | 실제/근거 |
| --- | --- | --- |
| 수기 비교표 | 실행 위치와 근거 파일 연결 | 참가자 작성 |
| 과제 산출물 검토 | 변경/새 파일과 실행 코드 확인 | 참가자 작성 |
| cleanup | 정확한 자원 삭제와 잔존 상태 확인 | 참가자 작성 |
| 비용/권한 | 남은 저장소/네트워크와 PAT 확인 | 참가자 작성 |

자신의 작업에 맞는 접근 범위를 선택하고 허용한 자원의 비용/위험을 설명한다. 안전성 순위는 매기지 않는다.

## 7. 실패가 정상인 경우

미실행과 기록 누락은 실패를 감추지 않고 명시한다. 원자료가 부족하면 차단 성공이나 memory 복원을 주장하지 않는다. 삭제가 실패하면 종료했다고 쓰지 말고 정확한 오류와 남은 자원을 기록한다.

## 8. 복구와 checkpoint

원자료가 부족하면 이미 확보한 로그로 설명할 수 있는 범위까지만 쓴다. checkpoint 사용은 별도 표시한다. 앱 복구는 [체크포인트 운영](../checkpoints/README.md)을 따르며 관찰표를 checkpoint 결과로 채우지 않는다.

## 9. 정리 체크리스트

1. Docker Clone은 **실행 중일 때** fetch하고 diff를 검토한다. `sbx stop` 후에는 remote가 자동으로 시작되지 않는다.
2. 자신이 만든 이름만 `sbx rm ws-direct`, `sbx rm ws-clone`, `sbx rm ws-mixin`으로 제거한다. 확장 참가자는 실제 custom 이름도 제거한다. 이미 삭제한 이름은 다시 지우지 않는다.
3. 교육용 `example.com` rule과 Copilot grant/deny를 시작 전 상태로 되돌린다. `sbx policy reset`은 쓰지 않는다.
4. ACA는 기록한 정확한 ID로 `aca sandbox delete --id <SANDBOX_ID> --yes`를 실행하고 `aca sandbox list -o json`으로 부재를 확인한다.
5. 본인 group의 snapshot, disk image, volume과 임시 역할을 확인한다. group 삭제는 **본인 전용이며 다른 자원이 없음**을 사람이 확인했을 때만 별도 수행한다.
6. 교육용 PAT를 회수하고 Docker/ACA에 저장한 본인 credential도 정리한다. 다른 작업의 credential을 일괄 삭제하지 않는다.
7. 선택 Windows VM은 결과를 물리 PC로 먼저 회수하고 배포했던 PC에서 정확한 VM 전용 환경에 `azd down --environment <VM_ENV_NAME>`을 실행한다. ACA cleanup과 별개다. 자동 종료는 삭제가 아니다.
8. canary는 자신이 만든 `read.txt`, `write.txt`만 지운다. workspace/evidence 보존 여부는 본인이 결정한다. 저장소 루트 전체와 홈을 재귀 삭제하는 명령을 사용하지 않는다.

삭제 후 디스크, NAT Gateway와 공인 IP 등 비용 자원이 남지 않았는지 Azure portal에서 확인한다. 정리 명령의 종료 코드만으로 비용이 0이라고 판단하지 않는다.
