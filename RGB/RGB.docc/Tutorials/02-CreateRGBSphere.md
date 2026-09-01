# 02-CreateRGBSphere

## Overview

Create the three RGB spheres that will become the main visual elements
of the immersive experience.

Each sphere is a `ModelEntity` with a spherical mesh, a colored material,
and an RGB color value.

### Create a Sphere

A RealityKit `ModelEntity` combines a mesh and one or more materials to
create a visible object in the scene.

@Code(name: "RGBSphere.swift")

The `makeRGBSphere` function creates a sphere with a radius of `0.15`
meters.

It also stores the sphere's RGB color using `RGBColorComponent`.

### Create the RGB Colors

The `RGBColor` structure stores red, green, and blue values separately.

@Code(name: "RGBColor.swift")

The primary colors are represented as:

- Red: `(1, 0, 0)`
- Green: `(0, 1, 0)`
- Blue: `(0, 0, 1)`

Keeping the RGB values separate from the visual `UIColor` makes it
possible to combine the colors later.

### Create the Sphere Material

The sphere uses a `PhysicallyBasedMaterial` to control its appearance.

The material combines its base color with transparency and emissive
color to create a luminous appearance.

### Add a Radiating Glow

A second visual layer creates the soft glow around each sphere.

@Code(name: "RGBSphere.swift")

The glow uses a radial gradient texture applied to a plane.

A `BillboardComponent` keeps the glow facing the viewer.

The glow is visual only and does not contain interaction components.

### Place the RGB Spheres

The three spheres are created and positioned in `ImmersiveView`.

@Code(name: "ImmersiveView.swift")

At this point, the spheres are visible in the immersive space, but they
cannot be manipulated yet.
