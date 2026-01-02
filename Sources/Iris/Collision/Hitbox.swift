import Foundation
import simd

/// Shape types for collision detection with varying accuracy and performance characteristics.
public enum HitboxShape: Sendable {
    /// Axis-aligned bounding box (fastest collision checks)
    case aabb(width: Float, height: Float)

    /// Circle hitbox (good for balls, bullets, radial objects)
    case circle(radius: Float)

    /// Convex polygon (can be auto-generated from image or manually specified)
    case polygon(vertices: [SIMD2<Float>])

    /// Pixel-perfect mask from image transparency
    case pixelMask(mask: PixelMask)

    /// Compound shape combining multiple hitboxes
    case compound(shapes: [(offset: SIMD2<Float>, shape: HitboxShape)])
}

/// Represents a positioned hitbox with shape and optional rotation.
public struct Hitbox: Sendable {
    /// World position (typically the center or top-left depending on shape)
    public var position: SIMD2<Float>

    public var shape: HitboxShape

    /// Rotation in radians (applies to polygon shapes)
    public var rotation: Float

    /// Creates a new hitbox with specified position and shape.
    /// - Parameters:
    ///   - position: World position of the hitbox
    ///   - shape: The collision shape type
    ///   - rotation: Rotation in radians (default 0)
    public init(position: SIMD2<Float>, shape: HitboxShape, rotation: Float = 0) {
        self.position = position
        self.shape = shape
        self.rotation = rotation
    }

    /// Convenience initializer with x, y coordinates.
    public init(x: Float, y: Float, shape: HitboxShape, rotation: Float = 0) {
        self.position = SIMD2<Float>(x, y)
        self.shape = shape
        self.rotation = rotation
    }

    /// Returns the axis-aligned bounding box of this hitbox.
    public var boundingBox: (x: Float, y: Float, w: Float, h: Float) {
        switch shape {
        case .aabb(let width, let height):
            return (position.x, position.y, width, height)

        case .circle(let radius):
            return (position.x - radius, position.y - radius, radius * 2, radius * 2)

        case .polygon(let vertices):
            let transformed = transformedVertices(vertices)
            guard let first = transformed.first else {
                return (position.x, position.y, 0, 0)
            }
            var minX = first.x
            var maxX = first.x
            var minY = first.y
            var maxY = first.y
            for v in transformed.dropFirst() {
                minX = min(minX, v.x)
                maxX = max(maxX, v.x)
                minY = min(minY, v.y)
                maxY = max(maxY, v.y)
            }
            return (minX, minY, maxX - minX, maxY - minY)

        case .pixelMask(let mask):
            return (position.x, position.y, Float(mask.width), Float(mask.height))

        case .compound(let shapes):
            guard let first = shapes.first else {
                return (position.x, position.y, 0, 0)
            }
            let firstHitbox = Hitbox(
                position: position + first.offset,
                shape: first.shape,
                rotation: rotation
            )
            var box = firstHitbox.boundingBox
            for (offset, subShape) in shapes.dropFirst() {
                let subHitbox = Hitbox(
                    position: position + offset,
                    shape: subShape,
                    rotation: rotation
                )
                let subBox = subHitbox.boundingBox
                let minX = min(box.x, subBox.x)
                let minY = min(box.y, subBox.y)
                let maxX = max(box.x + box.w, subBox.x + subBox.w)
                let maxY = max(box.y + box.h, subBox.y + subBox.h)
                box = (minX, minY, maxX - minX, maxY - minY)
            }
            return box
        }
    }

    /// Checks if a point is inside this hitbox.
    /// - Parameter point: The point to test
    /// - Returns: True if the point is inside the hitbox
    public func containsPoint(_ point: SIMD2<Float>) -> Bool {
        switch shape {
        case .aabb(let width, let height):
            return point.x >= position.x && point.x <= position.x + width && point.y >= position.y
                && point.y <= position.y + height

        case .circle(let radius):
            let delta = point - position
            return simd_length(delta) <= radius

        case .polygon(let vertices):
            let transformed = transformedVertices(vertices)
            return CollisionDetection.pointInPolygon(point, polygon: transformed)

        case .pixelMask(let mask):
            let localX = Int(point.x - position.x)
            let localY = Int(point.y - position.y)
            return mask.isSolid(x: localX, y: localY)

        case .compound(let shapes):
            for (offset, subShape) in shapes {
                let subHitbox = Hitbox(
                    position: position + offset, shape: subShape, rotation: rotation)
                if subHitbox.containsPoint(point) {
                    return true
                }
            }
            return false
        }
    }

    /// Checks if this hitbox collides with another hitbox.
    /// - Parameter other: The other hitbox to test against
    /// - Returns: True if the hitboxes overlap
    public func collides(with other: Hitbox) -> Bool {
        return CollisionDetection.collides(self, other)
    }

    private func transformedVertices(_ vertices: [SIMD2<Float>]) -> [SIMD2<Float>] {
        if rotation == 0 {
            return vertices.map { $0 + position }
        }

        let cos_r = cos(rotation)
        let sin_r = sin(rotation)

        return vertices.map { v in
            let rotated = SIMD2<Float>(
                v.x * cos_r - v.y * sin_r,
                v.x * sin_r + v.y * cos_r
            )
            return rotated + position
        }
    }
}

extension Hitbox {
    /// Creates a rectangular AABB hitbox.
    public static func rect(x: Float, y: Float, width: Float, height: Float) -> Hitbox {
        return Hitbox(x: x, y: y, shape: .aabb(width: width, height: height))
    }

    /// Creates a circular hitbox centered at the given position.
    public static func circle(centerX: Float, centerY: Float, radius: Float) -> Hitbox {
        return Hitbox(x: centerX, y: centerY, shape: .circle(radius: radius))
    }

    /// Creates a polygon hitbox from vertices (relative to position).
    public static func polygon(x: Float, y: Float, vertices: [SIMD2<Float>]) -> Hitbox {
        return Hitbox(x: x, y: y, shape: .polygon(vertices: vertices))
    }
}
