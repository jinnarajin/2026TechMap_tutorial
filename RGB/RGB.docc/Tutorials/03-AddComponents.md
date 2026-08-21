# 03-AddComponents

## Overview

Add custom RealityKit components to store information about the RGB
spheres.

Components allow an entity to carry data that describes its role or
state.

### Store RGB Color

The `RGBColorComponent` stores the RGB color associated with a sphere.

@Code(name: "RGBColorComponent")

The component contains an `RGBColor` value, keeping the color data
attached to the `ModelEntity`.

### Identify Original Spheres

The `OriginalSphereComponent` identifies the three original RGB spheres.

@Code(name: "OriginalSphereComponent")

It stores both the sphere's color and its fixed position.

This allows the original spheres to remain in their starting positions
while movable copies are created for interaction.
