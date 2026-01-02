import Foundation
import simd

enum DrawCommand {
    case clear(Color)
    case fillRect(
        x: Float, y: Float, width: Float, height: Float, color: Color, transform: matrix_float4x4)
    case fillCircle(x: Float, y: Float, radius: Float, color: Color, transform: matrix_float4x4)
    case drawLine(
        x1: Float, y1: Float, x2: Float, y2: Float, width: Float, color: Color,
        transform: matrix_float4x4)
    case fillPolygon(points: [SIMD2<Float>], color: Color, transform: matrix_float4x4)
    case strokeCircle(
        x: Float, y: Float, radius: Float, width: Float, color: Color, transform: matrix_float4x4)
    case strokeRect(
        x: Float, y: Float, width: Float, height: Float, strokeWidth: Float, color: Color,
        transform: matrix_float4x4)
    case strokePolygon(
        points: [SIMD2<Float>], width: Float, color: Color, transform: matrix_float4x4)
    case fillRectGradient(
        x: Float, y: Float, width: Float, height: Float, gradient: Gradient,
        transform: matrix_float4x4)
    case drawImage(image: Image, x: Float, y: Float, transform: matrix_float4x4)
    case drawText(
        text: String, x: Float, y: Float, font: Font, color: Color, transform: matrix_float4x4)
    case setBlendMode(BlendMode)
}

// MARK: - Polygon Triangulation

/// Ear clipping triangulation for complex polygons
struct PolygonTriangulator {
    /// Triangulates a polygon using ear clipping algorithm
    /// Returns triangle indices (groups of 3) into the original points array
    static func triangulate(_ points: [SIMD2<Float>]) -> [Int] {
        guard points.count >= 3 else { return [] }

        // For simple polygons (convex), use fan, for complex use ear clipping
        if points.count == 3 {
            return [0, 1, 2]
        }

        // Ear clipping algorithm
        var indices: [Int] = []
        var availableIndices = Array(0..<points.count)

        while availableIndices.count > 3 {
            var earFound = false

            for i in 0..<availableIndices.count {
                let prev = availableIndices[
                    (i - 1 + availableIndices.count) % availableIndices.count]
                let curr = availableIndices[i]
                let next = availableIndices[(i + 1) % availableIndices.count]

                if isEar(
                    points: points, indices: availableIndices, prev: prev, curr: curr, next: next)
                {
                    // Found an ear, add triangle
                    indices.append(contentsOf: [prev, curr, next])
                    availableIndices.remove(at: i)
                    earFound = true
                    break
                }
            }

            // Safety: if no ear found, break to avoid infinite loop (degenerate polygon)
            if !earFound {
                break
            }
        }

        // Add the last triangle
        if availableIndices.count == 3 {
            indices.append(contentsOf: availableIndices)
        }

        return indices
    }

    private static func isEar(
        points: [SIMD2<Float>], indices: [Int], prev: Int, curr: Int, next: Int
    ) -> Bool {
        let p1 = points[prev]
        let p2 = points[curr]
        let p3 = points[next]

        // Check if triangle is counter-clockwise (convex at this vertex)
        let cross = (p2.x - p1.x) * (p3.y - p1.y) - (p2.y - p1.y) * (p3.x - p1.x)
        if cross <= 0 { return false }

        // Check if any other point is inside the triangle
        for idx in indices {
            if idx == prev || idx == curr || idx == next { continue }
            if pointInTriangle(points[idx], p1, p2, p3) {
                return false
            }
        }

        return true
    }

    private static func pointInTriangle(
        _ p: SIMD2<Float>, _ a: SIMD2<Float>, _ b: SIMD2<Float>, _ c: SIMD2<Float>
    ) -> Bool {
        let sign = { (p1: SIMD2<Float>, p2: SIMD2<Float>, p3: SIMD2<Float>) -> Float in
            return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)
        }

        let d1 = sign(p, a, b)
        let d2 = sign(p, b, c)
        let d3 = sign(p, c, a)

        let hasNeg = (d1 < 0) || (d2 < 0) || (d3 < 0)
        let hasPos = (d1 > 0) || (d2 > 0) || (d3 > 0)

        return !(hasNeg && hasPos)
    }
}

final class GraphicsContext: Graphics {
    private(set) var commands: [DrawCommand] = []

    // State stacks
    private var transformStack: [matrix_float4x4] = []
    private var currentTransform: matrix_float4x4 = matrix_identity_float4x4

    private var blendModeStack: [BlendMode] = []
    private var currentBlendMode: BlendMode = .normal

    // Track if blend mode changed to emit command
    private var lastEmittedBlendMode: BlendMode = .normal

    func clear(_ color: Color) {
        commands.append(.clear(color))
    }

    func fillRect(x: Float, y: Float, width: Float, height: Float, color: Color) {
        ensureBlendMode()
        commands.append(
            .fillRect(
                x: x, y: y, width: width, height: height, color: color, transform: currentTransform)
        )
    }

    func fillCircle(x: Float, y: Float, radius: Float, color: Color) {
        ensureBlendMode()
        commands.append(
            .fillCircle(x: x, y: y, radius: radius, color: color, transform: currentTransform))
    }

    func drawLine(x1: Float, y1: Float, x2: Float, y2: Float, width: Float, color: Color) {
        ensureBlendMode()
        commands.append(
            .drawLine(
                x1: x1, y1: y1, x2: x2, y2: y2, width: width, color: color,
                transform: currentTransform))
    }

    func fillPolygon(points: [SIMD2<Float>], color: Color) {
        ensureBlendMode()
        commands.append(
            .fillPolygon(points: points, color: color, transform: currentTransform))
    }

    func strokeCircle(x: Float, y: Float, radius: Float, width: Float, color: Color) {
        ensureBlendMode()
        commands.append(
            .strokeCircle(
                x: x, y: y, radius: radius, width: width, color: color, transform: currentTransform)
        )
    }

    func strokeRect(
        x: Float, y: Float, width: Float, height: Float, strokeWidth: Float, color: Color
    ) {
        ensureBlendMode()
        commands.append(
            .strokeRect(
                x: x, y: y, width: width, height: height, strokeWidth: strokeWidth, color: color,
                transform: currentTransform))
    }

    func strokePolygon(points: [SIMD2<Float>], width: Float, color: Color) {
        ensureBlendMode()
        commands.append(
            .strokePolygon(points: points, width: width, color: color, transform: currentTransform))
    }

    func fillRectGradient(x: Float, y: Float, width: Float, height: Float, gradient: Gradient) {
        ensureBlendMode()
        commands.append(
            .fillRectGradient(
                x: x, y: y, width: width, height: height, gradient: gradient,
                transform: currentTransform))
    }

    func drawImage(_ image: Image, x: Float, y: Float) {
        ensureBlendMode()
        commands.append(.drawImage(image: image, x: x, y: y, transform: currentTransform))
    }

    func drawText(_ text: String, x: Float, y: Float, font: Font, color: Color) {
        ensureBlendMode()
        commands.append(
            .drawText(text: text, x: x, y: y, font: font, color: color, transform: currentTransform)
        )
    }

    // MARK: - Transformations

    func rotate(angle: Float) {
        // Z-axis rotation for 2D
        let c = cos(angle)
        let s = sin(angle)

        let rotation = matrix_float4x4(
            columns: (
                SIMD4<Float>(c, s, 0, 0),
                SIMD4<Float>(-s, c, 0, 0),
                SIMD4<Float>(0, 0, 1, 0),
                SIMD4<Float>(0, 0, 0, 1)
            ))

        currentTransform = matrix_multiply(currentTransform, rotation)
    }

    func scale(x: Float, y: Float) {
        let scaling = matrix_float4x4(
            columns: (
                SIMD4<Float>(x, 0, 0, 0),
                SIMD4<Float>(0, y, 0, 0),
                SIMD4<Float>(0, 0, 1, 0),
                SIMD4<Float>(0, 0, 0, 1)
            ))

        currentTransform = matrix_multiply(currentTransform, scaling)
    }

    func translate(x: Float, y: Float) {
        let translation = matrix_float4x4(
            columns: (
                SIMD4<Float>(1, 0, 0, 0),
                SIMD4<Float>(0, 1, 0, 0),
                SIMD4<Float>(0, 0, 1, 0),
                SIMD4<Float>(x, y, 0, 1)
            ))

        currentTransform = matrix_multiply(currentTransform, translation)
    }

    func save() {
        transformStack.append(currentTransform)
        blendModeStack.append(currentBlendMode)
    }

    func restore() {
        if let transform = transformStack.popLast() {
            currentTransform = transform
        }

        if let blendMode = blendModeStack.popLast() {
            currentBlendMode = blendMode
            // No need to emit command here, it will be emitted on next draw if needed
            // But we might want to force it if next draw relies on it.
            // My ensureBlendMode logic handles this.
        }
    }

    func setBlendMode(_ mode: BlendMode) {
        currentBlendMode = mode
    }

    private func ensureBlendMode() {
        if lastEmittedBlendMode != currentBlendMode {
            commands.append(.setBlendMode(currentBlendMode))
            lastEmittedBlendMode = currentBlendMode
        }
    }

    func reset() {
        commands.removeAll(keepingCapacity: true)
        transformStack.removeAll(keepingCapacity: true)
        currentTransform = matrix_identity_float4x4
        blendModeStack.removeAll(keepingCapacity: true)
        currentBlendMode = .normal
        lastEmittedBlendMode = .normal
    }
}
