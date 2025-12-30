// Iris - A minimal 2D game engine
//
// Public API:
//   Engine.run(game:)  - Entry point
//   Game               - Protocol your game implements
//   Graphics           - Drawing interface (clear, fillRect, drawImage, drawText)
//   Color              - RGBA color (Float 0-1)
//   Image              - Loaded image asset (Image.load)
//   Font               - Font for text (Font.system)
//   Input              - Keyboard state (Input.shared.isKeyDown)
//   Key                - Key enum (arrows, WASD, space, escape)
//   DebugInfo          - Frame timing (fps, deltaTime, frameNumber)
//
// Coordinate system:
//   Origin: top-left, X right, Y down, units: pixels
//
// Error handling:
//   Missing image file: returns nil, logs warning
//   Drawing outside screen: allowed (clipped by GPU)
//   Double-loading assets: cached (returns same handle)
//   Invalid font: falls back to system font

