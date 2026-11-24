# 대안 과제: 게임 정렬

출처: <https://github.com/github-samples/tailspin-toys/blob/9cd9a450f923c7a084bd47d661877d82ff710826/.github/bootstrap-issues/02-sort-games.md>

고정 SHA: `9cd9a450f923c7a084bd47d661877d82ff710826`

강사가 대안 과제를 선택한 경우 세 환경 모두 이 원문을 사용한다. 검색 과제로 바꾸지 않는다. 아래 원문 구간을 그대로 프롬프트에 붙인다. 원격 push와 이슈/PR 생성은 하지 않는다. 구현 결과는 **미검증**이다.

<!-- BEGIN ORIGINAL -->
# Allow users to sort the game list

Different players browse in different ways — some want the highest-rated titles first, others prefer alphabetical order. Adding sorting options to the game list page gives backers more control over how they explore the catalog. The data layer already exposes title and star rating, so this builds on existing structures.

## Acceptance criteria

- [ ] Users can sort the game list by title (A–Z and Z–A)
- [ ] Users can sort the game list by star rating (highest first)
- [ ] Games without a star rating are ordered in a sensible, documented way when sorting by rating
- [ ] The sort control follows the project's accessibility guidelines (labeling, keyboard navigation, visible focus states) and includes a `data-testid` attribute
- [ ] Unit tests cover the sorting helper(s) and Playwright e2e tests cover the sorting behavior
<!-- END ORIGINAL -->

## 원본 라이선스 고지

원본 [LICENSE](https://github.com/github-samples/tailspin-toys/blob/9cd9a450f923c7a084bd47d661877d82ff710826/LICENSE)를 그대로 유지한다.

```text
MIT License

Copyright GitHub, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
