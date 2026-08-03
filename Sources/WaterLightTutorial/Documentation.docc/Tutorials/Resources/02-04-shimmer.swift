import RealityKit
import Foundation

/// 수면 반사광이 일렁이도록 roughness를 진동시키는 컴포넌트.
struct ShimmerComponent: Component {
    /// 물결 세기 (0...1). 핸드 트래킹 챕터에서 핀치로 조정한다.
    var strength: Float = 0.5
}

struct ShimmerSystem: System {
    private static let query = EntityQuery(where: .has(ShimmerComponent.self))
    private var time: Float = 0

    init(scene: Scene) {}

    mutating func update(context: SceneUpdateContext) {
        time += Float(context.deltaTime)

        for entity in context.entities(matching: Self.query,
                                       updatingSystemWhen: .rendering) {
            guard let model = entity as? ModelEntity,
                  var material = model.model?.materials.first
                    as? PhysicallyBasedMaterial,
                  let shimmer = entity.components[ShimmerComponent.self]
            else { continue }

            // 두 사인파를 겹쳐 불규칙한 일렁임을 만든다.
            let wave = sin(time * 3.1) * 0.5 + sin(time * 5.7) * 0.5
            let roughness = 0.05 + 0.15 * shimmer.strength * (wave * 0.5 + 0.5)
            material.roughness = .init(floatLiteral: roughness)
            model.model?.materials = [material]
        }
    }
}

// 앱 시작 시 한 번 등록: WaterLightApp.init에서
//   ShimmerComponent.registerComponent()
//   ShimmerSystem.registerSystem()
