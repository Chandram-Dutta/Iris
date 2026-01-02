# Iris

![Space Shooter Demo](Assets/space_shooter.mov)

A minimal 2D game engine in Swift.

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FChandram-Dutta%2FIris%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/Chandram-Dutta/Iris)

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FChandram-Dutta%2FIris%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/Chandram-Dutta/Iris)

## Philosophy

Iris provides the bare minimum to make games: a window, a game loop, drawing primitives, and input. No scenes, no ECS, no editor. You write code, you draw pixels.

## Public API

```swift
Engine.run(game:)     // Entry point
Game                  // Protocol: update() + draw()
Graphics              // Drawing: clear, fillRect, drawImage, drawText
Color                 // RGBA (Float 0-1)
Image                 // Image.load("path.png")
Font                  // Font.system(size: 16)
Input                 // Input.shared.isKeyDown(.space)
Key                   // .left, .right, .up, .down, .w, .a, .s, .d, .space, .escape
DebugInfo             // fps, deltaTime, frameNumber
```

## Hello Game

```swift
import Iris

class MyGame: Game {
    func update(deltaTime: TimeInterval, debug: DebugInfo) {
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

## Coordinate System

- Origin: top-left corner
- X: increases right
- Y: increases down
- Units: pixels

## Error Handling

| Situation | Behavior |
|-----------|----------|
| Missing image file | Returns nil, logs warning |
| Drawing outside screen | Allowed (GPU clips) |
| Double-loading assets | Returns cached handle |

## Requirements

- macOS (Metal)
- Swift 6.2+
