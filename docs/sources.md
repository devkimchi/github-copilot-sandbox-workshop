# 출처와 검증 범위

조사 보고서 §3~§12, §13과 부록 A.7을 실습 자료로 구성했다. 보고서는 제품 실행 결과가 아니라 공식 문서와 고정 소스에 근거한 설계다. 부록 A.7의 이전 Windows 추출 확인을 이번 스크립트 실행 검증으로 승계하지 않는다.

## 고정 소스

| 자료 | revision과 용도 |
| --- | --- |
| [Tailspin Toys](https://github.com/github-samples/tailspin-toys/tree/9cd9a450f923c7a084bd47d661877d82ff710826) | `9cd9a450f923c7a084bd47d661877d82ff710826`, 앱 파일, 05/02 과제와 MIT 고지 |
| [appmod-box](https://github.com/justinyoo/agent-box/tree/18bd8c0ec534c02f83827a7d3917b590cb992ae0/appmod-box) | `18bd8c0ec534c02f83827a7d3917b590cb992ae0`, Windows VM, Bastion, NAT와 사용자 설치 방식 참고 |
| [MOTD v3 예제](https://github.com/docker/sandbox-kit-spec/blob/f852d816048374eb0fae706836e236ff3416c23f/examples/motd/motd.yaml) | `f852d816048374eb0fae706836e236ff3416c23f`, v3 mixin 구조 참고 |

## 공식 제품 문서

- Copilot: [사용](https://docs.github.com/en/copilot/how-tos/cloud-and-local-sandboxes/using-local-sandboxing), [설정](https://docs.github.com/en/copilot/how-tos/cloud-and-local-sandboxes/configuring-local-sandbox-settings), [정책 적용과 한계](https://docs.github.com/en/copilot/concepts/security-governance-and-network-settings/understanding-local-sandboxing), [CLI와 인증](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference).
- Docker: [설치](https://docs.docker.com/ai/sandboxes/install/), [보안](https://docs.docker.com/ai/sandboxes/security/), [기본 상태](https://docs.docker.com/ai/sandboxes/security/defaults/), [Git](https://docs.docker.com/ai/sandboxes/workflows/git/), [v3 kit 사용](https://docs.docker.com/ai/sandboxes/customize/use-kits/), [mixin 제작](https://docs.docker.com/ai/sandboxes/customize/author/tool-mixins/), [네트워크](https://docs.docker.com/ai/governance/local/network-rules/), [Copilot workload](https://hub.docker.com/r/sbx/copilot), [Playwright mixin](https://hub.docker.com/r/sbx/playwright).
- ACA: [개요](https://learn.microsoft.com/azure/container-apps/sandboxes-overview), [CLI 설치](https://sandboxes.azure.com/docs/sandboxes/quickstart/setup-cli), [그룹과 RBAC](https://sandboxes.azure.com/docs/sandboxes/sandbox-groups), [egress](https://sandboxes.azure.com/docs/sandboxes/sandbox/egress), [수명주기](https://sandboxes.azure.com/docs/sandboxes/sandbox/lifecycle), [credential](https://sandboxes.azure.com/docs/sandboxes/credentials), [파일](https://sandboxes.azure.com/docs/sandboxes/sandbox/files), [identity](https://sandboxes.azure.com/docs/sandboxes/identity), [quota](https://sandboxes.azure.com/docs/sandboxes/limits), [지역](https://sandboxes.azure.com/docs/sandboxes/regions), [이미지](https://sandboxes.azure.com/docs/sandboxes/disk-images), [ingress](https://sandboxes.azure.com/docs/sandboxes/sandbox/ports).
- Windows VM: [중첩 가상화](https://learn.microsoft.com/windows-server/virtualization/hyper-v/enable-nested-virtualization).

이 링크들의 현재 내용을 실행해 재검증한 것은 아니다. 최종 버전, kit digest, ACA image와 allowlist, 지역, 비용, VM 호환성과 실제 소요 시간은 `TBD(검증 필요)`다.
