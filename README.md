# RGB — Interactive RGB Light Experience

빛의 삼원색(R/G/B) 구를 손으로 집어 옮기고, 겹친 자리에서 혼합색 구를 꺼내고,
오른손 손바닥을 돌려 밝기를 조절하는 visionOS 앱입니다. 앱을 만들며 RealityKit과
ARKit Hand Tracking을 단계별로 배우는 튜토리얼을 함께 제공합니다.

**튜토리얼:** https://jinnarajin.github.io/2026TechMap_tutorial/ (영어 / 한국어)

https://github.com/user-attachments/assets/9c322ecd-12b8-41a4-b8c9-b82178fb6279

## 튜토리얼 구성

| 섹션 | 내용 |
|---|---|
| 1. Create the Immersive Space | 프로젝트 생성, `WindowGroup`과 Full `ImmersiveSpace` |
| 2. Create the RGB Spheres | `ModelEntity`, `PhysicallyBasedMaterial`, 퍼지는 글로우 |
| 3. Make the Spheres Interactive | `InputTargetComponent`, `CollisionComponent`, `ManipulationComponent`, 선택 링 |
| 4. Mix Colors | RGB 가산혼합, 겹침 판정 |
| 5. Add Overlap Targets | 겹친 지점에서 혼합색 구 꺼내기 |
| 6. Adjust Sphere Brightness with Hand Tracking | `HandTrackingProvider`로 손바닥 회전 → 밝기 |

## 요구 사항

- Xcode 26 이상, visionOS 26.5 이상 (배포 타깃)
- Apple Vision Pro: Hand Tracking(섹션 6)은 visionOS Simulator에서 동작하지 않습니다.
  Simulator에서는 Immersive 배치와 빌드만 확인할 수 있습니다.

## 실행

1. `RGB.xcodeproj`를 Xcode로 엽니다.
2. 실행 대상으로 Apple Vision Pro(또는 visionOS Simulator)를 선택하고 실행합니다.
3. 윈도우의 버튼을 눌러 Immersive Space에 들어갑니다.

## 폴더 구조

```
RGB/                  앱 소스 (Swift)
Packages/             RealityKitContent (Reality Composer Pro 에셋)
docs/index.html       튜토리얼 페이지 (GitHub Pages)
docs/images/          튜토리얼 이미지·영상
docs/retrospectives/  스터디 회고
```

## 기여

브랜치·커밋·PR 규칙은 [CONTRIBUTING.md](CONTRIBUTING.md)를 참고하세요.

Apple Developer Academy 스터디 프로젝트입니다.
