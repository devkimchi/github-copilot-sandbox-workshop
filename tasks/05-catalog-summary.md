# 기본 과제: 카탈로그 요약

출처: <https://github.com/github-samples/tailspin-toys/blob/9cd9a450f923c7a084bd47d661877d82ff710826/.github/bootstrap-issues/05-catalog-summary.md>

고정 SHA: `9cd9a450f923c7a084bd47d661877d82ff710826`

아래 원문 구간을 번역하거나 요약하지 않고 공통 프롬프트 뒤에 붙인다. 워크숍은 GitHub 이슈를 생성하지 않는다. 원문과 실제 앱 실행은 별개이며 구현 결과는 **미검증**이다.

<!-- BEGIN ORIGINAL -->
# Show a catalog summary on the home page

The home page jumps straight into the featured games grid without giving visitors a sense of the catalog's size or quality. Adding a small summary — such as the total number of games and the average star rating — gives backers useful at-a-glance context and makes the landing page feel more alive. This builds entirely on data already available in the data layer.

## Acceptance criteria

- [ ] The home page displays the total number of games in the catalog
- [ ] The home page displays the average star rating across games that have a rating
- [ ] The summary handles edge cases gracefully (no games, or no rated games)
- [ ] The summary follows the project's styling and accessibility guidelines and includes `data-testid` attributes
- [ ] A data-access helper computes the summary deterministically, with unit test coverage, and Playwright e2e tests verify it renders on the home page
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
