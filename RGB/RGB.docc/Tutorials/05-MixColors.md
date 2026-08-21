# 05-MixColors

Learn how to detect overlapping RGB spheres and create a new sphere with
the resulting mixed color.

## Overview

In this section, you will build the color-mixing logic for the RGB light
experience.

When two movable spheres overlap, their RGB values are combined to produce
a new color. For example, combining red and green produces yellow, while
combining red and blue produces magenta.

The color calculation is separated from the RealityKit scene so that the
RGB values can be reused independently of the visual representation.

### Create the RGB Color Model

The `RGBColor` structure stores red, green, and blue values as floating-point
numbers.

@Code(name: "RGBColor.swift", file: "05-MixColors.swift")

Each primary light is represented using one RGB component:

- Red: `(1, 0, 0)`
- Green: `(0, 1, 0)`
- Blue: `(0, 0, 1)`

### Combine RGB Colors

The `mixed(with:)` function combines the RGB components of two colors.

@Code(name: "Mix RGB colors", file: "05-MixColors.swift")

The RGB values are added together and then normalized so that the resulting
values remain within the `0...1` range.

For example:

- Red + Green → Yellow
- Red + Blue → Magenta
- Green + Blue → Cyan

When all three primary lights overlap, the result becomes white.

### Detect Overlapping Spheres

Create a `SphereOverlapSystem` to determine when two movable spheres are
close enough to overlap.

@Code(name: "SphereOverlapSystem.swift", file: "05-MixColors.swift")

The system compares the world-space positions of every pair of movable
spheres.

The distance between two sphere centers is compared with the combined
sphere diameter. If the distance is smaller than the overlap distance, the
two spheres are considered to be overlapping.

The midpoint between the two spheres is then used as the location of the
color-mixing interaction.

### Create an Overlap Key

Each pair of overlapping spheres receives a unique key.

The key allows the interaction manager to identify the same overlap target
when the spheres move or when the overlap is removed.

This prevents duplicate interaction targets from being created for the same
pair of spheres.

### Calculate the Mixed Color

When an overlap is detected, retrieve the `RGBColorComponent` from both
spheres and combine their colors.

@Code(name: "Calculate mixed color", file: "05-MixColors.swift")

The resulting `RGBColor` is stored in the `SphereOverlap` value together with
the two spheres, the midpoint, and the overlap key.

The overlap system therefore describes **what is overlapping**, **where the
overlap occurs**, and **what color should be produced**.

### Prepare the Overlap for Interaction

The overlap system only calculates the overlap. It does not create a visible
mixed sphere.

The `SphereInteractionManager` uses the overlap information to create the
mixed sphere and place it at the overlap position.

@Code(name: "SphereInteractionManager.swift", file: "05-MixColors.swift")

The mixed sphere uses the calculated RGB color and becomes part of the
movable sphere collection, allowing it to participate in future overlaps.

The next section adds an invisible interaction target at the overlap
position so the user can directly interact with the resulting mixed color.
