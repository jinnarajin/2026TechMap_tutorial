# CLAUDE.md — AI 협업 가이드

AI(Claude 등)와 이 저장소에서 작업하기 전에 이 문서를 먼저 읽습니다.
사람 온보딩에도 같은 문서를 씁니다.

## 프로젝트 개요

visionOS RealityKit **DocC 튜토리얼** 프로젝트입니다. 물속 몰입 공간에서
핸드 트래킹으로 수면 빛을 조정하는 예제를 4개 챕터로 가르칩니다.

## 먼저 읽을 파일

1. [README.md](README.md) — 미리보기·배포 방법, 튜토리얼 구성
2. [CONTRIBUTING.md](CONTRIBUTING.md) — 브랜치/커밋/PR 컨벤션
3. `Sources/WaterLightTutorial/Documentation.docc/Tutorials/` — 튜토리얼 본문
4. [ExampleApp/README.md](ExampleApp/README.md) — 완성 예제 실행 방법

## 구조

- `Sources/WaterLightTutorial/Documentation.docc/` — DocC 튜토리얼 (본체)
  - `Tutorials/Resources/*.swift` — 각 스텝의 코드 리스팅
- `ExampleApp/WaterLight/` — 완성 예제 앱 (Xcode 16+, visionOS 2.0+)
- `.github/workflows/docs.yml` — GitHub Pages 자동 배포

## 주의할 점

- **코드 리스팅과 예제 앱은 항상 동기화**: `Tutorials/Resources/*.swift`를
  고치면 `ExampleApp/WaterLight`의 대응 코드도 같이 고쳐야 합니다 (반대도 동일).
- 튜토리얼 스텝 순서는 리스팅 파일의 diff로 표현되므로, 중간 스텝 파일을
  고치면 이후 스텝 파일들도 확인해야 합니다.
- 핸드 트래킹은 실기기 전용 — 시뮬레이터 동작을 전제로 한 수정 금지.
- 문서/튜토리얼 본문은 한국어로 작성합니다.

## 검증 방법

```bash
swift package --disable-sandbox preview-documentation --target WaterLightTutorial
```

예제 앱은 `ExampleApp/WaterLight.xcodeproj`를 visionOS 시뮬레이터로 빌드.

## 코드 스타일

[DeveloperAcademy-POSTECH/swift-style-guide](https://github.com/DeveloperAcademy-POSTECH/swift-style-guide) + `.swiftlint.yml`
