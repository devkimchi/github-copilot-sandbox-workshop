# 관찰 기록

이 파일을 `<REPOSITORY_ROOT>/evidence/observation.md`로 복사한 뒤 **참가자가 직접** 작성한다. 아래 양식은 실행 결과가 아니다. 기대 결과는 모두 **미검증**이다.

원자료는 사람이 명령 출력을 `evidence/setup/`, `evidence/copilot-cli/`, `evidence/lab-2/`, `evidence/lab-2b/`, `evidence/lab-3/`에 저장한다. 정확한 명령과 실행 위치를 함께 쓴다. 토큰, 구독 ID, 실제 credential 내용과 고객 자료를 쓰지 않는다. 앱 내부 `workspace/evidence/summary.md`는 이 관찰 기록과 다르다.

## 환경과 원자료

| 항목 | 실제 값 | 근거 파일 |
| --- | --- | --- |
| OS/build와 실행 위치 | 참가자 작성 | 참가자 작성 |
| Copilot/Node/Git/sbx/aca 버전 | 참가자 작성 | 참가자 작성 |
| CWD와 baseline, sandbox 이름/ID(비공개 보관) | 참가자 작성 | 참가자 작성 |
| 시작 전 설정과 조직 정책 | 참가자 작성 | 참가자 작성 |

## 실습 단계별 관찰(행을 복사해 사용)

| 실습 단계 | 위치와 정확한 명령 | 기대 결과(미검증) | 실제 stdout/stderr와 종료 코드 | 실제 승인/도구 호출/정책 | 전후 hash 또는 diff | 근거 파일 | 판정 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| <실습 단계> | <HOST 또는 도구와 정확한 명령> | <미검증 기대 결과> | <실제 stdout/stderr와 종료 코드> | <실제 승인, 도구 호출과 정책> | <전후 hash 또는 diff> | <evidence 파일 경로> | <판정과 이유> |

판정은 `MODEL_REFUSAL`, `APPROVAL_REQUIRED`, `POLICY_DENIED`, `UNSUPPORTED`, `ENVIRONMENT_FAILURE`, `SUCCESS` 중 하나를 쓰고 이유를 적는다. 시간 초과/미실행은 실제 결과에 명시하고 성공으로 채우지 않는다.

명령에 `|`가 있으면 Markdown 표가 깨지지 않도록 `\|`로 적는다. 비밀, 토큰, 구독 ID와 고객 자료는 기록하지 않는다.

모델 거부는 실제 작업 차단 증거가 아니다. 오류만으로 deny라고 단정하지 않으며 정책 decision과 연결한다. transcript가 누락되거나 일부를 가렸다면 범위와 사유를 쓴다.

## 복구와 정리

| 대상 | 내가 만든 자원/설정 | 보존한 결과 | 정리/복구 명령과 실제 결과 | 잔존 자원 확인 |
| --- | --- | --- | --- | --- |
| Copilot 교육용 grant/deny | 참가자 작성 | 참가자 작성 | 참가자 작성 | 참가자 작성 |
| Docker 이름/정책 | 참가자 작성 | 참가자 작성 | 참가자 작성 | 참가자 작성 |
| ACA ID/저장 자원/PAT | 참가자 작성 | 참가자 작성 | 참가자 작성 | 참가자 작성 |
| 선택 VM 전용 환경 | 참가자 작성 | 참가자 작성 | 참가자 작성 | 참가자 작성 |
