# WaterLight 예제 앱 (완성본)

튜토리얼 전 챕터를 합친 실행 가능한 Xcode 프로젝트입니다.

**요구 사항**: Xcode 16+, visionOS 2.0+ (`SpotLightComponent`가 visionOS 2부터 지원).
visionOS 시뮬레이터 대상 `xcodebuild` 빌드 통과 확인됨.

## 실행 방법

1. `WaterLight.xcodeproj`를 Xcode에서 열기
2. 타깃의 **Signing & Capabilities**에서 본인 Team 선택
   (번들 ID `com.example.WaterLight`는 필요시 변경)
3. 실기기(Apple Vision Pro) 또는 visionOS 시뮬레이터에서 실행 → "수면 열기" 버튼

`NSHandsTrackingUsageDescription`은 빌드 설정(`INFOPLIST_KEY_...`)에 이미 포함되어 있습니다.

> 시뮬레이터에서도 수면과 물결 애니메이션까지는 보이지만,
> 핸드 트래킹(빛 조정)은 실기기에서만 동작합니다.

## 조작

- **오른손 검지** — 빛(SpotLight)이 검지 위쪽 1m 지점으로 따라옴
- **엄지+검지 핀치** — 쥘수록 빛이 강해지고(최대 25,000lm) 물결이 잔잔해져 반사가 또렷해짐
