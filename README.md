# WaterLight — RealityKit in visionOS DocC 튜토리얼

핸드 트래킹으로 물 표면에 반사되는 빛을 조정하는 visionOS 예제를
단계별로 배우는 DocC 튜토리얼입니다.

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

[ExampleApp/](ExampleApp/README.md)에 전 챕터를 합친 실행 가능한 전체 코드가 있습니다.
Xcode visionOS App 템플릿에 파일 5개를 넣으면 바로 실행됩니다 (visionOS 2.0+).

## 구성

- `Sources/WaterLightTutorial/Documentation.docc/Tutorials/` — 튜토리얼 챕터 4개
  1. 프로젝트와 이머시브 공간
  2. 물 표면 만들기 (PBR 머티리얼 + Shimmer 시스템)
  3. 핸드 트래킹 (`ARKitSession` + `HandTrackingProvider`)
  4. 손으로 빛 조정 (검지 위치 → 조명, 핀치 → 세기/물결)
- `Tutorials/Resources/*.swift` — 각 스텝의 코드 리스팅

핸드 트래킹은 실제 Vision Pro에서만 동작합니다 (시뮬레이터 불가).
`Info.plist`에 `NSHandsTrackingUsageDescription` 필요.
