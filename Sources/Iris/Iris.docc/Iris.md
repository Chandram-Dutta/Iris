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

class MyGame: Game {
    func update(deltaTime: Double, debug: DebugInfo) {
        // game logic here
    }
    
    func draw(_ g: Graphics, debug: DebugInfo) {
        g.clear(Color(r: 0.1, g: 0.1, b: 0.2))
        g.fillRect(x: 100, y: 100, width: 50, height: 50, color: .red)
        g.drawText("Hello Iris", x: 100, y: 200, font: Font.system(size: 24), color: .white)
    }
}

@MainActor func main() {
    Engine().run(game: MyGame())
}

main()
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

### Audio
- ``Sound``
- ``Music``

### Physics & Collision
- ``Hitbox``
- ``HitboxShape``
- ``CollisionDetection``
- ``PixelMask``
- ``ConvexHullGenerator``
