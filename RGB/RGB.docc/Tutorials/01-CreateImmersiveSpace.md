# 01-CreateImmersiveSpace

## Overview

Create the immersive space that will contain the RGB light experience.

The app starts in a regular SwiftUI window. When the user opens the
immersive space, RealityKit creates a separate 3D environment where the
RGB spheres will be placed and interacted with.

### Create the App Model

The `AppModel` keeps track of the immersive space's current state.

@Code(name: "AppModel.swift")

The `immersiveSpaceID` identifies the immersive space, while
`immersiveSpaceState` keeps track of whether the space is closed,
opening or closing, or currently open.

### Define the App's Scenes

The `App` structure defines both the regular window and the immersive
space.

@Code(name: "RGBApp.swift")

The `WindowGroup` displays the initial SwiftUI interface. The
`ImmersiveSpace` scene contains the `ImmersiveView`, which will later
contain the RGB spheres.

When the immersive space appears, the app changes its state to
`open`. When it disappears, the state returns to `closed`.

### Open and Close the Immersive Space

The `ToggleImmersiveSpaceButton` controls whether the immersive space
is open.

@Code(name: "ToggleImmersiveSpaceButton.swift")

`openImmersiveSpace` opens the immersive space using its identifier,
while `dismissImmersiveSpace` closes it.

The app uses the `inTransition` state while the immersive space is
opening or closing. This prevents the button from being used again
during the transition.

### Create the Initial View

The regular window only needs a button to enter the immersive
experience.

@Code(name: "ContentView.swift")

At this point, the app can open and close an empty immersive space.
The RGB spheres will be added in the next section.
