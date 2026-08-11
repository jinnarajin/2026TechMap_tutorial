//
//  RGBColor.swift
//  RGB
//
//  Created by Minjae Son on 8/10/26.
//

import UIKit

struct RGBColor:
    Codable {

    let red:
        Float

    let green:
        Float

    let blue:
        Float

    // MARK: - Primary Colors

    static let red =
        RGBColor(
            red: 1.0,
            green: 0.0,
            blue: 0.0
        )

    static let green =
        RGBColor(
            red: 0.0,
            green: 1.0,
            blue: 0.0
        )

    static let blue =
        RGBColor(
            red: 0.0,
            green: 0.0,
            blue: 1.0
        )

    // MARK: - Mixing

    func mixed(
        with other: RGBColor
    ) -> RGBColor {

        RGBColor(
            red:
                red + other.red,

            green:
                green + other.green,

            blue:
                blue + other.blue
        )
        .normalized()
    }

    static func mixed(
        colors: [RGBColor]
    ) -> RGBColor {

        guard
            !colors.isEmpty
        else {
            return RGBColor(
                red: 0,
                green: 0,
                blue: 0
            )
        }

        let totalRed =
            colors.reduce(0) {
                $0 + $1.red
            }

        let totalGreen =
            colors.reduce(0) {
                $0 + $1.green
            }

        let totalBlue =
            colors.reduce(0) {
                $0 + $1.blue
            }

        return RGBColor(
            red:
                totalRed,

            green:
                totalGreen,

            blue:
                totalBlue
        )
        .normalized()
    }

    // MARK: - Normalization

    func normalized() -> RGBColor {

        let maximum =
            max(
                red,
                green,
                blue
            )

        guard
            maximum > 1.0
        else {
            return self
        }

        return RGBColor(
            red:
                red / maximum,

            green:
                green / maximum,

            blue:
                blue / maximum
        )
    }

    // MARK: - UIColor

    var uiColor:
        UIColor {

        UIColor(
            red:
                CGFloat(
                    min(
                        max(
                            red,
                            0.0
                        ),
                        1.0
                    )
                ),

            green:
                CGFloat(
                    min(
                        max(
                            green,
                            0.0
                        ),
                        1.0
                    )
                ),

            blue:
                CGFloat(
                    min(
                        max(
                            blue,
                            0.0
                        ),
                        1.0
                    )
                ),

            alpha:
                1.0
        )
    }
}
