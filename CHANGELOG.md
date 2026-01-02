# Changelog

All notable changes to this project will be documented in this file.

## [1.1.2] - 2026-01-02

### Added
- **MIT License**: Added open-source MIT License to the project.
- **Collision Detection System**:
  - New `Collision` module with support for multiple hitbox shapes (AABB, Circle, Polygon, PixelMask, and Compound).
  - Implementation of the Separating Axis Theorem (SAT) for precise polygon collision detection.
  - Automatic `PixelMask` and convex hull generation from image transparency.
- **Advanced Graphics Features**:
  - Added support for stroke primitives: `strokeCircle`, `strokeRect`, and `strokePolygon`.
  - Added gradient fill support with `fillRectGradient` (Linear and Radial).
  - Improved polygon rendering using a robust ear-clipping triangulation algorithm to handle concave shapes.
- **New Math Module**: Created `Math.swift` with cross-platform matrix operations and SIMD utilities.
- New `Assets` directory organization and better resource management.

### Changed
- Refactored example games (Breakout, Snake, SpaceShooter) to use the new collision and graphics systems.
- Refined and cleaned up public API documentation and code comments.

### Fixed
- **Complete Cross-Platform Support**: Removed all dependencies on Apple-specific `simd` module across the entire codebase.
  - Implemented custom `matrix_float4x4` struct and matrix multiplication for cross-platform compatibility.
  - Added SIMD2 extensions (`.length()`, `.lengthSquared()`) for vector operations.
  - Affected files: `CollisionDetection.swift`, `Hitbox.swift`, `ConvexHull.swift`, `DrawCommand.swift`, `Renderer.swift`, `IrisRunner.swift`.
- **Concurrency Safety**: Made `matrix_float4x4` conform to `Sendable` for Swift 6 strict concurrency checking.
- **Linux/Multi-Platform Build**: Engine now builds successfully on Linux, Windows, and other non-Apple platforms.
- Improved keyboard input responsiveness and fixed input lag issues.
- Fixed resource loading issues in Swift Package Manager environments.

## [0.1.0] - 2025-12-30

### Added
- Initial release of Iris game engine.
- Core engine features.
- Examples: Breakout, Snake, SpaceShooter.

