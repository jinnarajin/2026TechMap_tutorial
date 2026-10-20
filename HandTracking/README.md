# visionOS Hand Skeleton Visualizer

ARKit으로 양손의 26개 관절을 추적하고 RealityKit으로 스켈레톤과 전완 회전각을
시각화하는 visionOS 실험 프로젝트다. 관절은 구, 부모-자식 관절 사이는 원기둥으로
표시한다. 왼손은 청록색, 오른손은 자홍색이다.

실행 프로젝트는 `handtracking/handtracking.xcodeproj`에 있다.

## 현재 구현

- `HandTrackingProvider.anchorUpdates`로 양손 `HandAnchor`를 실시간 수신
- `originFromAnchorTransform * anchorFromJointTransform`으로 관절의 월드 변환 계산
- 추적되지 않는 손이나 관절은 즉시 숨김
- `.upperLimbVisibility(.hidden)`으로 시스템 손 표현을 숨기고 스켈레톤만 표시
- 머리 기준 attachment에 왼손·오른손 각도를 동시에 표시
- Full Immersive Space 사용

## 전완 회전각 기준

측정 대상은 손목을 좌우로 꺾는 동작이 아니라 전완의 회내·회외
(`forearm pronation/supination`)다.

| 자세 | 표시 각도 |
|---|---:|
| 엄지가 위를 향하는 중립 자세 | `0°` |
| 손바닥이 아래를 향하는 회내 | `-90°` |
| 손바닥이 위를 향하는 회외 | `+90°` |

계산에는 다음 관절을 사용한다.

- 전완 회전축: `forearmArm → forearmWrist`
- 손바닥 평면: `indexFingerKnuckle`, `littleFingerKnuckle`, `forearmWrist`
- 손바닥 법선: 손바닥 평면을 이루는 두 벡터의 외적
- 각도: 전완축을 기준으로 중립 방향과 손바닥 법선 사이의 signed angle

왼손은 관절 배치가 오른손과 거울 대칭이므로 외적 방향과 최종 부호를 보정해 양손이
동일한 규칙으로 표시되게 했다.

## 현재 알려진 문제: `-90°` 부근 각도 점프

손바닥을 아래로 돌릴 때 값이 음수에서 갑자기 양수로 바뀌는 현상이 남아 있다.
가능성이 큰 원인은 다음 세 가지다.

1. `atan2` 결과가 `-180°...+180°`에서 순환하며 경계를 넘을 때 부호가 바뀐다.
2. 검지·새끼손가락 관절로 만든 손바닥 법선이 추적 노이즈 때문에 순간적으로
   반전되면 계산 각도가 약 `180°` 바뀐다.
3. `cross(worldUp, forearmAxis)`로 만든 중립 방향은 전완이 수직에 가까워질수록
   길이가 작아져 불안정해진다.

다음 개선에서는 이전 프레임과의 연속성을 이용해야 한다.

```swift
if simd_dot(currentPalmNormal, previousPalmNormal) < 0 {
    currentPalmNormal *= -1
}
```

이와 함께 angle unwrapping, 저역통과 필터, 비정상 프레임 거부를 적용한다. 더 안정적인
방법이 필요하면 손목 회전 쿼터니언에서 전완축의 swing-twist를 분리하는 방식으로
교체한다. 단순히 값을 `-90°...+90°`로 clamp하면 튐을 가릴 뿐 원인을 해결하지 못한다.

## Xcode에서 실행

1. `handtracking/handtracking.xcodeproj`를 연다.
2. Apple Vision Pro 실기기를 실행 대상으로 선택한다.
3. 앱을 실행하고 `스켈레톤 보기`를 누른다.
4. 처음 표시되는 손 추적 권한을 허용한다.

`Info.plist`에는 `NSHandsTrackingUsageDescription`이 설정되어 있다. 손 추적 데이터는
Full Space에서만 제공되며 시뮬레이터로 실제 추적 정확도를 검증할 수 없다.

## 다음 할 일

- [ ] 이전 손바닥 법선과 내적해 180° 반전 방지
- [ ] 각도 unwrapping으로 `atan2` 경계 연속화
- [ ] 짧은 저역통과 필터로 프레임 노이즈 완화
- [ ] 실기기에서 양손의 `0°`, `-90°`, `+90°` 기준 검증

관련 회고: `PARA/Project/2026 Spatial Computing Tech Map/튜토리얼/회고 일지/2026-08-26 Hand Tracking 스켈레톤과 전완 회전각.md`
