# WaterLight 예제 앱 (완성본)

튜토리얼 전 챕터를 합친 실행 가능한 전체 코드입니다.

**요구 사항**: Xcode 16+, visionOS 2.0+ (`SpotLightComponent`가 visionOS 2부터 지원).
visionOS 2.0 SDK 기준 타입체크 통과 확인됨.

## 실행 방법

1. Xcode → **File > New > Project > visionOS > App**
   - Product Name: `WaterLight`
   - Initial Scene: **Window** / Immersive Space Renderer: **RealityKit** / Immersive Space: **Mixed**
2. 템플릿이 만든 `WaterLightApp.swift`, `ContentView.swift`, `ImmersiveView.swift`를 삭제하고
   이 폴더의 `WaterLight/` 안 5개 파일을 프로젝트에 드래그해서 추가
3. 타깃 설정 → **Info** 탭에 키 추가:
   - `NSHandsTrackingUsageDescription` = `손 위치로 수면의 빛을 조정합니다.`
4. 실기기(Apple Vision Pro)에서 실행 → "수면 열기" 버튼

> 시뮬레이터에서도 수면과 물결 애니메이션까지는 보이지만,
> 핸드 트래킹(빛 조정)은 실기기에서만 동작합니다.

## 조작

- **오른손 검지** — 빛(SpotLight)이 검지 위쪽 1m 지점으로 따라옴
- **엄지+검지 핀치** — 쥘수록 빛이 강해지고(최대 25,000lm) 물결이 잔잔해져 반사가 또렷해짐
