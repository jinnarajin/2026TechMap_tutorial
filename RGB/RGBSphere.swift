//
//  RGBSphere.swift
//  RGB
//
//  Created by Minjae Son on 8/10/26.
//

import RealityKit
import UIKit


// =============================================================
// MARK: - RGB Color Component
// =============================================================

struct RGBColorComponent: Component {

    var color: RGBColor
}


// =============================================================
// MARK: - Material
// =============================================================

func makeRGBMaterial(
    color: UIColor
) -> PhysicallyBasedMaterial {

    var material =
        PhysicallyBasedMaterial()


    // ---------------------------------------------------------
    // Core color
    // ---------------------------------------------------------

    material.baseColor =
        .init(
            tint:
                color
        )


    // ---------------------------------------------------------
    // Matte surface
    //
    // Keeps the sphere from looking like a plastic balloon.
    // ---------------------------------------------------------

    material.metallic =
        0.0

    material.roughness =
        0.85


    // ---------------------------------------------------------
    // CORE SPHERE OPACITY
    //
    // The sphere itself is slightly transparent so that
    // overlapping colored spheres are easier to see.
    //
    // The radiating glow is NOT affected by this value.
    // ---------------------------------------------------------

    material.blending =
        .transparent(
            opacity:
                PhysicallyBasedMaterial.Opacity(
                    floatLiteral:
                        0.75
                )
        )


    // ---------------------------------------------------------
    // Core emission
    // ---------------------------------------------------------

    material.emissiveColor =
        .init(
            color:
                color
        )

    material.emissiveIntensity =
        3.0


    return material
}


// =============================================================
// MARK: - RGB Sphere
// =============================================================

func makeRGBSphere(
    color: UIColor,
    rgbColor: RGBColor
) -> ModelEntity {

    // ---------------------------------------------------------
    // REAL interactive sphere
    // ---------------------------------------------------------

    let sphere =
        ModelEntity(
            mesh:
                .generateSphere(
                    radius:
                        0.15
                ),

            materials: [
                makeRGBMaterial(
                    color:
                        color
                )
            ]
        )


    sphere.name =
        "RGBSphere"


    // ---------------------------------------------------------
    // Store RGB information.
    //
    // SphereOverlapSystem depends on this.
    // ---------------------------------------------------------

    sphere.components.set(
        RGBColorComponent(
            color:
                rgbColor
        )
    )


    // ---------------------------------------------------------
    // Add radiating glow.
    // ---------------------------------------------------------

    addRadiatingGlow(
        to:
            sphere,

        color:
            color
    )


    return sphere
}


// =============================================================
// MARK: - Radiating Glow
// =============================================================
//
// This function is intentionally NOT private.
//
// SphereInteractionManager uses the same glow for:
//
// - permanent RGB spheres
// - RGB clones
// - mixed spheres
//
// =============================================================

func addRadiatingGlow(
    to sphere: ModelEntity,
    color: UIColor
) {

    guard
        let texture =
            makeRadialGlowTexture(
                color:
                    color
            )
    else {
        return
    }


    // =========================================================
    // ONE glow plane
    //
    // We intentionally use one plane.
    //
    // The previous two-plane approach created the visible
    // intersection line in the green sphere.
    // =========================================================

    let glow =
        makeGlowPlane(
            texture:
                texture,

            size:
                0.50
        )


    glow.name =
        "RGBGlow"


    // ---------------------------------------------------------
    // Slightly offset from the sphere core.
    // ---------------------------------------------------------

    glow.position =
        SIMD3<Float>(
            0,
            0,
            0.015
        )


    // ---------------------------------------------------------
    // Billboard
    //
    // Keeps the radial glow facing the viewer.
    // ---------------------------------------------------------

    glow.components.set(
        BillboardComponent()
    )


    // ---------------------------------------------------------
    // Add visual glow to the sphere.
    // ---------------------------------------------------------

    sphere.addChild(
        glow
    )
}


// =============================================================
// MARK: - Glow Plane
// =============================================================

private func makeGlowPlane(
    texture: TextureResource,
    size: Float
) -> ModelEntity {

    var material =
        UnlitMaterial(
            texture:
                texture
        )


    // ---------------------------------------------------------
    // Transparent blending.
    //
    // The texture itself contains the radial alpha gradient.
    // ---------------------------------------------------------

    material.blending =
        .transparent(
            opacity:
                PhysicallyBasedMaterial.Opacity(
                    floatLiteral:
                        1.0
                )
        )


    // ---------------------------------------------------------
    // Create glow plane.
    // ---------------------------------------------------------

    let plane =
        ModelEntity(
            mesh:
                .generatePlane(
                    width:
                        size,

                    height:
                        size
                ),

            materials: [
                material
            ]
        )


    // ---------------------------------------------------------
    // VISUAL ONLY
    //
    // No collision.
    // No input target.
    // No manipulation.
    // No RGBColorComponent.
    // ---------------------------------------------------------

    plane.name =
        "RGBGlow"


    return plane
}


// =============================================================
// MARK: - Radial Glow Texture
// =============================================================

private func makeRadialGlowTexture(
    color: UIColor
) -> TextureResource? {
    
    let imageSize =
    512
    
    
    let renderer =
    UIGraphicsImageRenderer(
        size:
            CGSize(
                width:
                    imageSize,
                
                height:
                    imageSize
            )
    )
    
    
    let image =
    renderer.image { context in
        
        let cgContext =
        context.cgContext
        
        
        // -------------------------------------------------
        // Center of glow
        // -------------------------------------------------
        
        let center =
        CGPoint(
            x:
                CGFloat(imageSize) / 2.0,
            
            y:
                CGFloat(imageSize) / 2.0
        )
        
        
        // -------------------------------------------------
        // UIColor → RGB
        // -------------------------------------------------
        
        var red:
        CGFloat = 0
        
        var green:
        CGFloat = 0
        
        var blue:
        CGFloat = 0
        
        var alpha:
        CGFloat = 1
        
        
        color.getRed(
            &red,
            green:
                &green,
            blue:
                &blue,
            alpha:
                &alpha
        )
        
        
        // =================================================
        // RADIAL LIGHT
        //
        // Bright center
        // Soft middle
        // Fading outer glow
        // Transparent edge
        // =================================================
        
        let colors = [
            
            CGColor(
                red:
                    red,
                
                green:
                    green,
                
                blue:
                    blue,
                
                alpha:
                    0.75
            ),
            
            CGColor(
                red:
                    red,
                
                green:
                    green,
                
                blue:
                    blue,
                
                alpha:
                    0.35
            ),
            
            CGColor(
                red:
                    red,
                
                green:
                    green,
                
                blue:
                    blue,
                
                alpha:
                    0.10
            ),
            
            CGColor(
                red:
                    red,
                
                green:
                    green,
                
                blue:
                    blue,
                
                alpha:
                    0.0
            )
        ]
        
        
        let locations:
        [CGFloat] = [
            
            0.0,
            0.25,
            0.55,
            1.0
        ]
        
        
        guard
            let gradient =
                CGGradient(
                    colorsSpace:
                        CGColorSpaceCreateDeviceRGB(),
                    
                    colors:
                        colors as CFArray,
                    
                    locations:
                        locations
                )
        else {
            return
        }
        
        
        let radius =
        CGFloat(imageSize) / 2.0
        
        
        cgContext.drawRadialGradient(
            gradient,
            
            startCenter:
                center,
            
            startRadius:
                0,
            
            endCenter:
                center,
            
            endRadius:
                radius,
            
            options:
                [
                    .drawsAfterEndLocation
                ]
        )
    }
    
    
    // =========================================================
    // UIImage → CGImage
    // =========================================================
    
    guard
        let cgImage =
            image.cgImage
    else {
        return nil
    }
    
    
    // =========================================================
    // UNIQUE TEXTURE NAME
    //
    // This prevents the red texture from being reused for
    // green and blue.
    // =========================================================
    
    var red:
    CGFloat = 0
    
    var green:
    CGFloat = 0
    
    var blue:
    CGFloat = 0
    
    var alpha:
    CGFloat = 1
    
    
    color.getRed(
        &red,
        green:
            &green,
        blue:
            &blue,
        alpha:
            &alpha
    )
    
    
    let redValue =
    Int(
        red * 255
    )
    
    let greenValue =
    Int(
        green * 255
    )
    
    let blueValue =
    Int(
        blue * 255
    )
    
    
    let textureName =
    "RGBRadialGlow_\(redValue)_\(greenValue)_\(blueValue)"
    
    
    // =========================================================
    // CGImage → RealityKit TextureResource
    // =========================================================
    
    return try? TextureResource(
        image:
            cgImage,
        
        withName:
            textureName,
        
        options:
                .init(
                    semantic:
                            .color
                )
    )
}
