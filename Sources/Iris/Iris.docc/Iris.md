# ``Iris``

A minimal 2D game engine in Swift.

## Overview

Iris is designed to be a "bare-to-the-metal" 2D game engine for Swift developers. It provides the essential primitives for game development—windowing, game loops, graphics primitives, and input handling—without imposing a specific architecture like Scenes or ECS.

### Core Philosophy

The philosophy behind Iris is simplicity:
- **No magic**: You control the loop.
- **Minimal API**: Only what you need to draw pixels and handle keys.
- **Metal-powered**: High performance rendering on macOS.

## Getting Started

To create your first game, define a class that conforms to the ``Game`` protocol:

```swift
import Iris

class HelloWorld: Game {
    func update(deltaTime: TimeInterval, debug: DebugInfo) {
        // Logic here
    }
    
    func draw(_ g: Graphics, debug: DebugInfo) {
        g.clear(.black)
        g.drawText("Hello World", x: 10, y: 10, font: .system(size: 20), color: .white)
    }
}

@MainActor func main() {
    Engine().run(game: HelloWorld())
}
```

## Topics

### Core Engine
- ``Engine``
- ``Game``
- ``DebugInfo``

### Graphics & Rendering
- ``Graphics``
- ``Color``
- ``Image``
- ``Font``
- ``Gradient``

### Input
- ``Input``
- ``Key``

### Physics & Collision
- ``Hitbox``
- ``HitboxShape``
- ``CollisionDetection``
- ``PixelMask``
- ``ConvexHullGenerator``
