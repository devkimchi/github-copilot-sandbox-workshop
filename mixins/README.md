# 180분 확장용 v3 제작 골격

[Lab 2B](../docs/04-docker-mixins.md)에서 사용한다. **build/적용 미검증**이다. 인자와 생성 파일 내용을 참가자가 직접 고친다. 150분 과정은 published Playwright mixin만 사용한다.

`workshop-greeting.yaml`은 `schemaVersion: "3"`, `kind: mixin`, `provides`, argument/buildArg와 inline build를 보여 준다. greeting은 영문 소문자만 받는다. 내용은 `/etc/workshop-greeting`에 만들며 시작 명령을 교체하지 않는다. credential과 runtime network capability는 추가하지 않는다. build에는 base image 다운로드가 필요하다.

Docker의 [MOTD 공식 예제](https://github.com/docker/sandbox-kit-spec/blob/f852d816048374eb0fae706836e236ff3416c23f/examples/motd/motd.yaml)를 참고해 이름과 파일 경로, 생성 내용을 바꾼 파생 예시다. 원본은 Copyright 2026 Docker, Inc., Apache-2.0이며 [원본 라이선스](LICENSE-APACHE-2.0)와 [NOTICE](NOTICE)를 유지한다. 워크숍 MIT 초안으로 원본 라이선스를 대체하지 않는다.

필요한 source build 도구, workload digest, base image digest, CPU architecture와 argument 접두사 문법은 `TBD(검증 필요)`다. OCI publish는 필수가 아니다. 완성본은 예행 연습 후 `checkpoints/mixin-example/`에 별도로 생성할 예정이다.
