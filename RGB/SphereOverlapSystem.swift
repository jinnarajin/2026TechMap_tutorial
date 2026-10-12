//
//  SphereOverlapSystem.swift
//  RGB
//
//  Created by Minjae Son on 8/11/26.
//

import RealityKit
import simd

struct SphereOverlap {
    let firstSphere: ModelEntity
    let secondSphere: ModelEntity
    let position: SIMD3<Float>
    let color: RGBColor
    let key: String
}

final class SphereOverlapSystem {
    private let overlapDistance: Float = 0.30

    func checkOverlap(spheres: [ModelEntity]) -> [SphereOverlap] {
        guard spheres.count >= 2 else { return [] }

        var overlaps: [SphereOverlap] = []

        for firstIndex in 0..<(spheres.count - 1) {
            for secondIndex in (firstIndex + 1)..<spheres.count {
                let first = spheres[firstIndex]
                let second = spheres[secondIndex]

                guard first !== second else { continue }

                let firstPosition = first.position(relativeTo: nil)
                let secondPosition = second.position(relativeTo: nil)
                let distance = simd_distance(firstPosition, secondPosition)

                guard distance < overlapDistance else { continue }

                guard
                    let firstColor = first.components[RGBColorComponent.self],
                    let secondColor = second.components[RGBColorComponent.self]
                else {
                    continue
                }

                let mixedColor = firstColor.color.mixed(with: secondColor.color)
                let midpoint = (firstPosition + secondPosition) / 2
                let key = makePairKey(first, second)

                overlaps.append(
                    SphereOverlap(
                        firstSphere: first,
                        secondSphere: second,
                        position: midpoint,
                        color: mixedColor,
                        key: key
                    )
                )
            }
        }

        return overlaps
    }

    private func makePairKey(_ first: ModelEntity, _ second: ModelEntity) -> String {
        let firstID = ObjectIdentifier(first).hashValue
        let secondID = ObjectIdentifier(second).hashValue

        return firstID < secondID
            ? "\(firstID)-\(secondID)"
            : "\(secondID)-\(firstID)"
    }
}
