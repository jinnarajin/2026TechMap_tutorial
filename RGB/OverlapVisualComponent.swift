//
//  OverlapVisualComponent.swift
//  RGB
//
//  Created by Minjae Son on 8/11/26.
//

import RealityKit

/// Stores the information needed by an invisible overlap target.
///
/// The target itself has no visible mesh. It only lets the user
/// grab the mixed-color interaction point.
struct OverlapVisualComponent: Component {
    let overlapKey: String
    let mixedColor: RGBColor
}
