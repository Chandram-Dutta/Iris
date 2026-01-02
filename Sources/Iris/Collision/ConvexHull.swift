import Foundation

/// Generates convex hulls from point sets or image transparency data.
public struct ConvexHullGenerator {

    /// Generates a convex hull from a set of points using the Gift Wrapping algorithm.
    /// - Parameter points: A set of 2D points
    /// - Returns: The vertices of the convex hull in counter-clockwise order
    public static func giftWrap(points: [SIMD2<Float>]) -> [SIMD2<Float>] {
        guard points.count >= 3 else {
            return points
        }

        // Find the leftmost point
        var leftmost = 0
        for i in 1..<points.count {
            if points[i].x < points[leftmost].x {
                leftmost = i
            } else if points[i].x == points[leftmost].x && points[i].y < points[leftmost].y {
                leftmost = i
            }
        }

        var hull: [SIMD2<Float>] = []
        var current = leftmost

        repeat {
            hull.append(points[current])
            var next = 0

            for i in 1..<points.count {
                if next == current {
                    next = i
                } else {
                    let cross = crossProduct(
                        origin: points[current],
                        a: points[next],
                        b: points[i]
                    )

                    // If i is more counter-clockwise or collinear but farther
                    if cross < 0 {
                        next = i
                    } else if cross == 0 {
                        // Collinear: choose the farther point
                        let distNext = (points[next] - points[current]).lengthSquared()
                        let distI = (points[i] - points[current]).lengthSquared()
                        if distI > distNext {
                            next = i
                        }
                    }
                }
            }

            current = next

            // Safety limit to prevent infinite loops
            if hull.count > points.count {
                break
            }

        } while current != leftmost

        return hull
    }

    /// Generates a simplified convex hull by sampling edge points.
    /// More efficient for large point sets (e.g., from images).
    /// - Parameters:
    ///   - points: A set of 2D points (typically edge pixels from an image)
    ///   - maxVertices: Maximum number of vertices in the resulting hull
    /// - Returns: The simplified convex hull vertices
    public static func simplifiedHull(
        points: [SIMD2<Float>],
        maxVertices: Int = 16
    ) -> [SIMD2<Float>] {
        let fullHull = giftWrap(points: points)

        guard fullHull.count > maxVertices else {
            return fullHull
        }

        // Douglas-Peucker simplification
        return douglasPeucker(
            points: fullHull, epsilon: calculateEpsilon(fullHull, targetCount: maxVertices))
    }

    /// Generates a convex hull from a pixel mask.
    /// - Parameters:
    ///   - mask: The pixel mask to analyze
    ///   - simplified: Whether to simplify the hull to fewer vertices
    /// - Returns: The convex hull vertices in local coordinates
    public static func fromPixelMask(_ mask: PixelMask, simplified: Bool = true) -> [SIMD2<Float>] {
        let edgePoints = mask.edgePixelCoordinates()

        guard edgePoints.count >= 3 else {
            // Fallback to bounding box
            return [
                SIMD2<Float>(0, 0),
                SIMD2<Float>(Float(mask.width), 0),
                SIMD2<Float>(Float(mask.width), Float(mask.height)),
                SIMD2<Float>(0, Float(mask.height)),
            ]
        }

        if simplified {
            return simplifiedHull(points: edgePoints, maxVertices: 12)
        } else {
            return giftWrap(points: edgePoints)
        }
    }

    private static func crossProduct(
        origin: SIMD2<Float>,
        a: SIMD2<Float>,
        b: SIMD2<Float>
    ) -> Float {
        return (a.x - origin.x) * (b.y - origin.y) - (a.y - origin.y) * (b.x - origin.x)
    }

    private static func douglasPeucker(points: [SIMD2<Float>], epsilon: Float) -> [SIMD2<Float>] {
        guard points.count > 2 else {
            return points
        }

        // Find the point with the maximum distance from the line (first to last)
        var maxDist: Float = 0
        var maxIndex = 0

        let first = points[0]
        let last = points[points.count - 1]

        for i in 1..<(points.count - 1) {
            let dist = perpendicularDistance(point: points[i], lineStart: first, lineEnd: last)
            if dist > maxDist {
                maxDist = dist
                maxIndex = i
            }
        }

        // If the max distance is greater than epsilon, recursively simplify
        if maxDist > epsilon {
            let firstHalf = Array(points[0...maxIndex])
            let secondHalf = Array(points[maxIndex...])

            let simplifiedFirst = douglasPeucker(points: firstHalf, epsilon: epsilon)
            let simplifiedSecond = douglasPeucker(points: secondHalf, epsilon: epsilon)

            // Combine (removing duplicate point at the join)
            return simplifiedFirst.dropLast() + simplifiedSecond
        } else {
            // All points between first and last are within epsilon
            return [first, last]
        }
    }

    private static func perpendicularDistance(
        point: SIMD2<Float>,
        lineStart: SIMD2<Float>,
        lineEnd: SIMD2<Float>
    ) -> Float {
        let dx = lineEnd.x - lineStart.x
        let dy = lineEnd.y - lineStart.y

        let lengthSq = dx * dx + dy * dy

        if lengthSq == 0 {
            return (point - lineStart).length()
        }

        let area = abs(
            dy * point.x - dx * point.y + lineEnd.x * lineStart.y - lineEnd.y * lineStart.x)
        return area / sqrt(lengthSq)
    }

    private static func calculateEpsilon(_ hull: [SIMD2<Float>], targetCount: Int) -> Float {
        guard hull.count > 2 else { return 0 }

        // Calculate perimeter
        var perimeter: Float = 0
        for i in 0..<hull.count {
            let j = (i + 1) % hull.count
            perimeter += (hull[j] - hull[i]).length()
        }

        // Epsilon is roughly proportional to how much we need to simplify
        let reductionRatio = Float(hull.count) / Float(targetCount)
        return perimeter / Float(hull.count) * (reductionRatio - 1) * 0.5
    }
}
