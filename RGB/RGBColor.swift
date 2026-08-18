//
//  RGBColor.swift
//  RGB
//
//  Created by Minjae Son on 8/10/26.
//

import UIKit

struct RGBColor: Codable {
    let red: Float
    let green: Float
    let blue: Float

    // MARK: - Primary Colors

    static let red = RGBColor(red: 1, green: 0, blue: 0)
    static let green = RGBColor(red: 0, green: 1, blue: 0)
    static let blue = RGBColor(red: 0, green: 0, blue: 1)

    // MARK: - Mixing

    func mixed(with other: RGBColor) -> RGBColor {
        RGBColor(
            red: red + other.red,
            green: green + other.green,
            blue: blue + other.blue
        ).normalized()
    }

    static func mixed(colors: [RGBColor]) -> RGBColor {
        guard !colors.isEmpty else {
            return RGBColor(red: 0, green: 0, blue: 0)
        }

        return RGBColor(
            red: colors.reduce(0) { $0 + $1.red },
            green: colors.reduce(0) { $0 + $1.green },
            blue: colors.reduce(0) { $0 + $1.blue }
        ).normalized()
    }

    // MARK: - Normalization

    /// Keeps additive RGB values within the 0...1 range while preserving their proportions.
    func normalized() -> RGBColor {
        let maximum = max(red, green, blue)

        guard maximum > 1 else { return self }

        return RGBColor(
            red: red / maximum,
            green: green / maximum,
            blue: blue / maximum
        )
    }

    // MARK: - UIColor

    var uiColor: UIColor {
        UIColor(
            red: CGFloat(min(max(red, 0), 1)),
            green: CGFloat(min(max(green, 0), 1)),
            blue: CGFloat(min(max(blue, 0), 1)),
            alpha: 1
        )
    }
}
