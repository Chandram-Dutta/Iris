import Foundation

/// Static collision detection utilities for various shape combinations.
public struct CollisionDetection {

    // MARK: - SIMD Helpers

    /// Cross-platform length squared for SIMD2<Float>
    private static func lengthSquared(_ vector: SIMD2<Float>) -> Float {
        return vector.x * vector.x + vector.y * vector.y
    }

    /// Cross-platform length for SIMD2<Float>
    private static func length(_ vector: SIMD2<Float>) -> Float {
        return sqrt(lengthSquared(vector))
    }

    /// Cross-platform dot product for SIMD2<Float>
    private static func dot(_ a: SIMD2<Float>, _ b: SIMD2<Float>) -> Float {
        return a.x * b.x + a.y * b.y
    }

    /// Checks if two hitboxes collide.
    /// Automatically dispatches to the appropriate algorithm based on shape types.
    /// - Parameters:
    ///   - a: First hitbox
    ///   - b: Second hitbox
    /// - Returns: True if the hitboxes overlap
    public static func collides(_ a: Hitbox, _ b: Hitbox) -> Bool {
        // Fast AABB pre-check for all shapes
        let boxA = a.boundingBox
        let boxB = b.boundingBox

        if !aabbOverlap(boxA, boxB) {
            return false
        }

        // Dispatch based on shape types
        return collidesShapes(a, b)
    }

    /// Fast axis-aligned bounding box overlap test.
    public static func aabbOverlap(
        _ a: (x: Float, y: Float, w: Float, h: Float),
        _ b: (x: Float, y: Float, w: Float, h: Float)
    ) -> Bool {
        return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y
    }

    /// Circle vs Circle collision.
    public static func circleVsCircle(
        centerA: SIMD2<Float>, radiusA: Float,
        centerB: SIMD2<Float>, radiusB: Float
    ) -> Bool {
        let delta = centerB - centerA
        let distSq = lengthSquared(delta)
        let radiusSum = radiusA + radiusB
        return distSq <= radiusSum * radiusSum
    }

    /// Circle vs AABB collision.
    public static func circleVsAABB(
        circleCenter: SIMD2<Float>, radius: Float,
        rectX: Float, rectY: Float, rectW: Float, rectH: Float
    ) -> Bool {
        // Find closest point on rect to circle center
        let closestX = max(rectX, min(circleCenter.x, rectX + rectW))
        let closestY = max(rectY, min(circleCenter.y, rectY + rectH))

        let deltaX = circleCenter.x - closestX
        let deltaY = circleCenter.y - closestY
        let distSq = deltaX * deltaX + deltaY * deltaY

        return distSq <= radius * radius
    }

    /// Polygon vs Polygon collision using Separating Axis Theorem.
    public static func polygonVsPolygon(
        _ polygonA: [SIMD2<Float>],
        _ polygonB: [SIMD2<Float>]
    ) -> Bool {
        guard polygonA.count >= 3 && polygonB.count >= 3 else {
            return false
        }

        // Test separating axes from polygon A
        for i in 0..<polygonA.count {
            let j = (i + 1) % polygonA.count
            let edge = polygonA[j] - polygonA[i]
            let axis = SIMD2<Float>(-edge.y, edge.x)  // Perpendicular

            if isSeparatingAxis(axis: axis, polygonA: polygonA, polygonB: polygonB) {
                return false
            }
        }

        // Test separating axes from polygon B
        for i in 0..<polygonB.count {
            let j = (i + 1) % polygonB.count
            let edge = polygonB[j] - polygonB[i]
            let axis = SIMD2<Float>(-edge.y, edge.x)  // Perpendicular

            if isSeparatingAxis(axis: axis, polygonA: polygonA, polygonB: polygonB) {
                return false
            }
        }

        // No separating axis found, polygons overlap
        return true
    }

    /// Circle vs Polygon collision.
    public static func circleVsPolygon(
        circleCenter: SIMD2<Float>, radius: Float,
        polygon: [SIMD2<Float>]
    ) -> Bool {
        guard polygon.count >= 3 else { return false }

        // Check if circle center is inside polygon
        if pointInPolygon(circleCenter, polygon: polygon) {
            return true
        }

        // Check distance to each edge
        for i in 0..<polygon.count {
            let j = (i + 1) % polygon.count
            let closest = closestPointOnSegment(
                point: circleCenter,
                segmentStart: polygon[i],
                segmentEnd: polygon[j]
            )

            let distSq = lengthSquared(circleCenter - closest)
            if distSq <= radius * radius {
                return true
            }
        }

        return false
    }

    /// Checks if a point is inside a polygon using ray casting.
    public static func pointInPolygon(_ point: SIMD2<Float>, polygon: [SIMD2<Float>]) -> Bool {
        guard polygon.count >= 3 else { return false }

        var inside = false
        var j = polygon.count - 1

        for i in 0..<polygon.count {
            let vi = polygon[i]
            let vj = polygon[j]

            if ((vi.y > point.y) != (vj.y > point.y))
                && (point.x < (vj.x - vi.x) * (point.y - vi.y) / (vj.y - vi.y) + vi.x)
            {
                inside = !inside
            }

            j = i
        }

        return inside
    }

    private static func collidesShapes(_ a: Hitbox, _ b: Hitbox) -> Bool {
        switch (a.shape, b.shape) {
        case (.aabb(let wA, let hA), .aabb(let wB, let hB)):
            return aabbOverlap(
                (a.position.x, a.position.y, wA, hA),
                (b.position.x, b.position.y, wB, hB)
            )

        case (.circle(let rA), .circle(let rB)):
            return circleVsCircle(
                centerA: a.position, radiusA: rA,
                centerB: b.position, radiusB: rB
            )

        case (.circle(let r), .aabb(let w, let h)):
            return circleVsAABB(
                circleCenter: a.position, radius: r,
                rectX: b.position.x, rectY: b.position.y, rectW: w, rectH: h
            )

        case (.aabb(let w, let h), .circle(let r)):
            return circleVsAABB(
                circleCenter: b.position, radius: r,
                rectX: a.position.x, rectY: a.position.y, rectW: w, rectH: h
            )

        case (.polygon(let vertsA), .polygon(let vertsB)):
            let transformedA = transformVertices(vertsA, position: a.position, rotation: a.rotation)
            let transformedB = transformVertices(vertsB, position: b.position, rotation: b.rotation)
            return polygonVsPolygon(transformedA, transformedB)

        case (.circle(let r), .polygon(let verts)):
            let transformed = transformVertices(verts, position: b.position, rotation: b.rotation)
            return circleVsPolygon(circleCenter: a.position, radius: r, polygon: transformed)

        case (.polygon(let verts), .circle(let r)):
            let transformed = transformVertices(verts, position: a.position, rotation: a.rotation)
            return circleVsPolygon(circleCenter: b.position, radius: r, polygon: transformed)

        case (.aabb(let w, let h), .polygon(let verts)):
            let rectVerts = [
                a.position,
                a.position + SIMD2<Float>(w, 0),
                a.position + SIMD2<Float>(w, h),
                a.position + SIMD2<Float>(0, h),
            ]
            let transformed = transformVertices(verts, position: b.position, rotation: b.rotation)
            return polygonVsPolygon(rectVerts, transformed)

        case (.polygon(let verts), .aabb(let w, let h)):
            let rectVerts = [
                b.position,
                b.position + SIMD2<Float>(w, 0),
                b.position + SIMD2<Float>(w, h),
                b.position + SIMD2<Float>(0, h),
            ]
            let transformed = transformVertices(verts, position: a.position, rotation: a.rotation)
            return polygonVsPolygon(transformed, rectVerts)

        case (.pixelMask(let maskA), .pixelMask(let maskB)):
            return maskA.collides(with: maskB, selfPosition: a.position, otherPosition: b.position)

        case (.pixelMask, _), (_, .pixelMask):
            // For pixel mask vs other shapes, use AABB approximation
            // (Full implementation would require rasterizing the other shape)
            return true  // Already passed AABB check

        case (.compound(let shapesA), _):
            for (offset, subShape) in shapesA {
                let subHitbox = Hitbox(
                    position: a.position + offset, shape: subShape, rotation: a.rotation)
                if collidesShapes(subHitbox, b) {
                    return true
                }
            }
            return false

        case (_, .compound(let shapesB)):
            for (offset, subShape) in shapesB {
                let subHitbox = Hitbox(
                    position: b.position + offset, shape: subShape, rotation: b.rotation)
                if collidesShapes(a, subHitbox) {
                    return true
                }
            }
            return false
        }
    }

    private static func isSeparatingAxis(
        axis: SIMD2<Float>,
        polygonA: [SIMD2<Float>],
        polygonB: [SIMD2<Float>]
    ) -> Bool {
        let len = length(axis)
        guard len > 0 else { return false }
        let normalizedAxis = axis / len

        // Project polygon A onto axis
        var minA = dot(polygonA[0], normalizedAxis)
        var maxA = minA
        for v in polygonA.dropFirst() {
            let proj = dot(v, normalizedAxis)
            minA = min(minA, proj)
            maxA = max(maxA, proj)
        }

        // Project polygon B onto axis
        var minB = dot(polygonB[0], normalizedAxis)
        var maxB = minB
        for v in polygonB.dropFirst() {
            let proj = dot(v, normalizedAxis)
            minB = min(minB, proj)
            maxB = max(maxB, proj)
        }

        // Check for gap
        return maxA < minB || maxB < minA
    }

    private static func closestPointOnSegment(
        point: SIMD2<Float>,
        segmentStart: SIMD2<Float>,
        segmentEnd: SIMD2<Float>
    ) -> SIMD2<Float> {
        let line = segmentEnd - segmentStart
        let lengthSq = lengthSquared(line)

        if lengthSq == 0 {
            return segmentStart
        }

        let t = max(0, min(1, dot(point - segmentStart, line) / lengthSq))
        return segmentStart + t * line
    }

    private static func transformVertices(
        _ vertices: [SIMD2<Float>],
        position: SIMD2<Float>,
        rotation: Float
    ) -> [SIMD2<Float>] {
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
