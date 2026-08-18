# VisionTechmap — RGB 튜토리얼 앱

visionOS 학습 프로젝트. 빛의 삼원색(R/G/B) 구를 핀치·드래그로 조작하고,
겹친 구에서 혼합색 구를 추출하는 인터랙티브 튜토리얼 앱을 만들며 배운다.

**진행 방식**: 학습이 목표. 코드를 한 번에 생성하지 않고, 단계별로 개념 설명 →
코드 작성 → 한 줄씩 리뷰 → 시뮬레이터 확인 순으로 진행. 사용자가 Xcode에서 직접 작성한다.

**브랜치**: `elena/main`에서 작업.

## 학습 단계

- [ ] **Step 1 — visionOS 앱의 뼈대**: `App`, `WindowGroup` vs `ImmersiveSpace`(Full), 프로젝트 생성
- [ ] **Step 2 — RealityKit으로 구 하나 띄우기**: `Entity`, `ModelEntity`, `Material`, `openImmersiveSpace`, 어두운 배경(스카이박스)
- [ ] **Step 3 — 핀치 앤 드래그**: `InputTargetComponent`, `CollisionComponent`, `DragGesture` 연결
- [ ] **Step 4 — 겹침 판정**: 매 프레임 거리 계산 (중심 간 거리 < 반지름 합), 중간점에 선택 영역 구 표시
- [ ] **Step 5 — 혼합색 추출**: 선택 영역 핀치 → 혼합색 구 생성 → 드래그로 추출, RGB 가산혼합
- [ ] **Step 6 — 온보딩 + 내비게이션**: attachment로 공간 내 텍스트/CTA 표시, 표준 버튼으로 페이지 전환

## 확정된 설계 결정

| 항목 | 결정 |
|---|---|
| 공간 구조 | ImmersiveSpace(Full) + 어두운 배경(검은 스카이박스), 온보딩은 공간 내 attachment |
| 구 이동 | 핀치 앤 드래그 |
| 혼합색 추출 | 겹침 중간점의 선택 영역 구를 핀치 앤 드래그 |
| 겹침 판정 | 중심 간 거리 < 반지름 합 |
| 페이지 이동 | 표준 내비게이션 (버튼) |
| 3색 → 흰색 | 포함 (최종 미션 후보) |

## 보류 (P2)

- ⊕ 제스처: 겹친 색 저장 (선택사항)
- 로테이트: 빛 세기 조절
- flick 페이지 넘기기 (표준 내비게이션으로 대체)
