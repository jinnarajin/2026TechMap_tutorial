# 04-MakeSpheresInteractive

## Overview

Make the RGB spheres interactive so they can be selected and moved in
the immersive space.

### Prepare a Sphere for Interaction

The `configureSphereForInteraction` function adds the components needed
to interact with a sphere.

@Code(name: "SphereInteraction.swift")

An `InputTargetComponent` allows the entity to receive input.

A `CollisionComponent` defines the area that can be targeted.

A `ManipulationComponent` enables the user to move the sphere.

### Handle Manipulation Events

The `SphereInteractionManager` responds to manipulation events.

@Code(name: "SphereInteractionManager.swift")

The manager handles three stages:

1. Beginning a manipulation.
2. Updating the sphere's position.
3. Releasing the sphere.

Original spheres remain fixed while movable clones follow the user's
interaction.

Existing clones can also be selected and moved directly.
