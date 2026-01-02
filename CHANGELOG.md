# Changelog

All notable changes to this project will be documented in this file.

## [0.1.1] - 2026-01-02

### Added
- **Collision Detection System**:
  - New `Collision` module with support for multiple hitbox shapes (AABB, Circle, Polygon, PixelMask, and Compound).
  - Implementation of the Separating Axis Theorem (SAT) for precise polygon collision detection.
  - Automatic `PixelMask` and convex hull generation from image transparency.
- **Advanced Graphics Features**:
  - Added support for stroke primitives: `strokeCircle`, `strokeRect`, and `strokePolygon`.
  - Added gradient fill support with `fillRectGradient` (Linear and Radial).
  - Improved polygon rendering using a robust ear-clipping triangulation algorithm to handle concave shapes.
- New `Assets` directory organization and better resource management.

### Changed
- Refactored example games (Breakout, Snake, SpaceShooter) to use the new collision and graphics systems.
- Refined and cleaned up public API documentation and code comments.

### Fixed
- Improved keyboard input responsiveness and fixed input lag issues.
- Fixed resource loading issues in Swift Package Manager environments.

## [0.1.0] - 2025-12-30

### Added
- Initial release of Iris game engine.
- Core engine features.
- Examples: Breakout, Snake, SpaceShooter.

