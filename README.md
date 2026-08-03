# WaterLight — RealityKit in visionOS DocC 튜토리얼

visionOS 완전 몰입 공간에서 물속에 들어가, 머리 위 수면을 통해
들어오는 빛을 핸드 트래킹으로 조정하는 예제를 단계별로 배우는
DocC 튜토리얼입니다.

## 로컬 미리보기

```bash
swift package --disable-sandbox preview-documentation --target WaterLightTutorial
```

브라우저에서 `http://localhost:8080/tutorials/meetwaterlight` 접속.

## GitHub Pages 배포

1. GitHub 저장소 **Settings → Pages → Source**를 **GitHub Actions**로 설정
2. `main`에 push하면 `.github/workflows/docs.yml`이 자동 빌드·배포

배포 후 주소:
`https://<username>.github.io/<repo-name>/tutorials/meetwaterlight`

## 완성 예제 실행

[ExampleApp/WaterLight.xcodeproj](ExampleApp/README.md)를 Xcode에서 열면
바로 빌드·실행됩니다 (Xcode 16+, visionOS 2.0+).

## 구성

- `Sources/WaterLightTutorial/Documentation.docc/Tutorials/` — 튜토리얼 챕터 4개
  1. 프로젝트와 Full Immersive 공간
  2. 심해 돔 + 머리 위 수면 (PBR 머티리얼 + Shimmer 시스템)
  3. 핸드 트래킹 (`ARKitSession` + `HandTrackingProvider`)
  4. 손으로 빛 조정 (검지 → 수면 위 태양 위치, 핀치 → 세기/물결)
- `Tutorials/Resources/*.swift` — 각 스텝의 코드 리스팅

핸드 트래킹은 실제 Vision Pro에서만 동작합니다 (시뮬레이터 불가).
`Info.plist`에 `NSHandsTrackingUsageDescription` 필요.
