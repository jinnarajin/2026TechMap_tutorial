# 협업 컨벤션

## 브랜치 전략

- 기본 브랜치: `docc-waterlight-tutorial`
- 작업 브랜치: `<타입>/<간단한-설명>` (예: `docs/contributing`, `feat/hand-tracking-step`)
- 기본 브랜치에 직접 push 하지 않고 PR로 머지합니다.

## 커밋 메시지

`<타입>: <한 줄 요약>` 형식. 타입은 아래 중 하나:

| 타입 | 용도 |
|------|------|
| `feat` | 기능/튜토리얼 내용 추가 |
| `fix` | 버그·오타 수정 |
| `docs` | 문서 (README, 회고, 컨벤션 등) |
| `style` | 코드 스타일, 포맷팅 |
| `chore` | 빌드 설정, CI 등 |

예: `docs: 협업 컨벤션 추가`

## PR 규칙

- 제목은 커밋 메시지와 같은 형식
- 본문에 관련 이슈 연결: `Closes #번호`
- 리뷰 1명 이상 승인 후 머지 (스터디원끼리 상호 리뷰)
- 머지 방식: squash merge

## 이슈

- 작업 시작 전 이슈를 먼저 파고, 브랜치·PR을 이슈에 연결합니다.

## 코드 스타일

- [DeveloperAcademy-POSTECH/swift-style-guide](https://github.com/DeveloperAcademy-POSTECH/swift-style-guide)를 따릅니다.

## AI 협업

- AI(Claude 등)와 작업할 때는 [CLAUDE.md](CLAUDE.md)를 먼저 읽게 합니다.
