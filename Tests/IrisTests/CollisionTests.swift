import Testing
import simd

@testable import Iris

@Suite("Collision Detection Tests")
struct CollisionDetectionTests {

    @Test("AABB vs AABB - Overlapping")
    func testAABBOverlapping() {
        let a = Hitbox.rect(x: 0, y: 0, width: 10, height: 10)
        let b = Hitbox.rect(x: 5, y: 5, width: 10, height: 10)

        #expect(CollisionDetection.collides(a, b) == true)
    }

    @Test("AABB vs AABB - Not Overlapping")
    func testAABBNotOverlapping() {
        let a = Hitbox.rect(x: 0, y: 0, width: 10, height: 10)
        let b = Hitbox.rect(x: 20, y: 20, width: 10, height: 10)

        #expect(CollisionDetection.collides(a, b) == false)
    }

    @Test("AABB vs AABB - Edge Touching")
    func testAABBEdgeTouching() {
        let a = Hitbox.rect(x: 0, y: 0, width: 10, height: 10)
        let b = Hitbox.rect(x: 10, y: 0, width: 10, height: 10)

        // Edge touching should not be a collision (using < not <=)
        #expect(CollisionDetection.collides(a, b) == false)
    }

    @Test("Circle vs Circle - Overlapping")
    func testCircleOverlapping() {
        let a = Hitbox.circle(centerX: 0, centerY: 0, radius: 10)
        let b = Hitbox.circle(centerX: 15, centerY: 0, radius: 10)

        #expect(CollisionDetection.collides(a, b) == true)
    }

    @Test("Circle vs Circle - Not Overlapping")
    func testCircleNotOverlapping() {
        let a = Hitbox.circle(centerX: 0, centerY: 0, radius: 10)
        let b = Hitbox.circle(centerX: 25, centerY: 0, radius: 10)

        #expect(CollisionDetection.collides(a, b) == false)
    }

    @Test("Circle vs Circle - Touching")
    func testCircleTouching() {
        let a = Hitbox.circle(centerX: 0, centerY: 0, radius: 10)
        let b = Hitbox.circle(centerX: 20, centerY: 0, radius: 10)

        // Exactly touching circles don't collide (distance equals sum of radii)
        // This is intentional - overlap requires penetration
        #expect(CollisionDetection.collides(a, b) == false)
    }

    @Test("Circle vs AABB - Overlapping")
    func testCircleVsAABBOverlapping() {
        let circle = Hitbox.circle(centerX: 15, centerY: 5, radius: 10)
        let rect = Hitbox.rect(x: 0, y: 0, width: 10, height: 10)

        #expect(CollisionDetection.collides(circle, rect) == true)
    }

    @Test("Circle vs AABB - Not Overlapping")
    func testCircleVsAABBNotOverlapping() {
        let circle = Hitbox.circle(centerX: 30, centerY: 30, radius: 5)
        let rect = Hitbox.rect(x: 0, y: 0, width: 10, height: 10)

        #expect(CollisionDetection.collides(circle, rect) == false)
    }

    @Test("Circle vs AABB - Circle inside AABB")
    func testCircleInsideAABB() {
        let circle = Hitbox.circle(centerX: 50, centerY: 50, radius: 5)
        let rect = Hitbox.rect(x: 0, y: 0, width: 100, height: 100)

        #expect(CollisionDetection.collides(circle, rect) == true)
    }

    @Test("Polygon vs Polygon - Overlapping Triangles")
    func testPolygonOverlapping() {
        let triA = Hitbox.polygon(
            x: 0, y: 0,
            vertices: [
                SIMD2<Float>(0, 0),
                SIMD2<Float>(10, 0),
                SIMD2<Float>(5, 10),
            ])
        let triB = Hitbox.polygon(
            x: 3, y: 0,
            vertices: [
                SIMD2<Float>(0, 0),
                SIMD2<Float>(10, 0),
                SIMD2<Float>(5, 10),
            ])

        #expect(CollisionDetection.collides(triA, triB) == true)
    }

    @Test("Polygon vs Polygon - Not Overlapping")
    func testPolygonNotOverlapping() {
        let triA = Hitbox.polygon(
            x: 0, y: 0,
            vertices: [
                SIMD2<Float>(0, 0),
                SIMD2<Float>(10, 0),
                SIMD2<Float>(5, 10),
            ])
        let triB = Hitbox.polygon(
            x: 20, y: 0,
            vertices: [
                SIMD2<Float>(0, 0),
                SIMD2<Float>(10, 0),
                SIMD2<Float>(5, 10),
            ])

        #expect(CollisionDetection.collides(triA, triB) == false)
    }

    @Test("Point inside polygon")
    func testPointInsidePolygon() {
        let square = [
            SIMD2<Float>(0, 0),
            SIMD2<Float>(10, 0),
            SIMD2<Float>(10, 10),
            SIMD2<Float>(0, 10),
        ]

        #expect(CollisionDetection.pointInPolygon(SIMD2<Float>(5, 5), polygon: square) == true)
    }

    @Test("Point outside polygon")
    func testPointOutsidePolygon() {
        let square = [
            SIMD2<Float>(0, 0),
            SIMD2<Float>(10, 0),
            SIMD2<Float>(10, 10),
            SIMD2<Float>(0, 10),
        ]

        #expect(CollisionDetection.pointInPolygon(SIMD2<Float>(15, 5), polygon: square) == false)
    }

    @Test("Hitbox contains point - Circle")
    func testHitboxContainsPointCircle() {
        let circle = Hitbox.circle(centerX: 0, centerY: 0, radius: 10)

        #expect(circle.containsPoint(SIMD2<Float>(5, 0)) == true)
        #expect(circle.containsPoint(SIMD2<Float>(15, 0)) == false)
    }

    @Test("Hitbox contains point - AABB")
    func testHitboxContainsPointAABB() {
        let rect = Hitbox.rect(x: 0, y: 0, width: 10, height: 10)

        #expect(rect.containsPoint(SIMD2<Float>(5, 5)) == true)
        #expect(rect.containsPoint(SIMD2<Float>(15, 5)) == false)
    }

    @Test("Bounding box - Circle")
    func testBoundingBoxCircle() {
        let circle = Hitbox.circle(centerX: 10, centerY: 10, radius: 5)
        let box = circle.boundingBox

        #expect(box.x == 5)
        #expect(box.y == 5)
        #expect(box.w == 10)
        #expect(box.h == 10)
    }

    @Test("Bounding box - AABB")
    func testBoundingBoxAABB() {
        let rect = Hitbox.rect(x: 5, y: 10, width: 20, height: 30)
        let box = rect.boundingBox

        #expect(box.x == 5)
        #expect(box.y == 10)
        #expect(box.w == 20)
        #expect(box.h == 30)
    }
}

@Suite("Pixel Mask Tests")
struct PixelMaskTests {

    @Test("PixelMask from pixels - Alpha threshold")
    func testPixelMaskFromPixels() {
        // Create 2x2 RGBA image data
        // Pixel 0: opaque (alpha=255)
        // Pixel 1: transparent (alpha=0)
        // Pixel 2: semi-transparent (alpha=100, below threshold)
        // Pixel 3: semi-opaque (alpha=200, above threshold)
        let pixels: [UInt8] = [
            255, 0, 0, 255,  // Red, opaque
            0, 255, 0, 0,  // Green, transparent
            0, 0, 255, 100,  // Blue, below threshold
            255, 255, 0, 200,  // Yellow, above threshold
        ]

        let mask = PixelMask.fromPixels(pixels, width: 2, height: 2, alphaThreshold: 128)

        #expect(mask.isSolid(x: 0, y: 0) == true)  // Pixel 0
        #expect(mask.isSolid(x: 1, y: 0) == false)  // Pixel 1
        #expect(mask.isSolid(x: 0, y: 1) == false)  // Pixel 2
        #expect(mask.isSolid(x: 1, y: 1) == true)  // Pixel 3
    }

    @Test("PixelMask - Out of bounds")
    func testPixelMaskOutOfBounds() {
        let mask = PixelMask(width: 10, height: 10)

        #expect(mask.isSolid(x: -1, y: 0) == false)
        #expect(mask.isSolid(x: 0, y: -1) == false)
        #expect(mask.isSolid(x: 10, y: 0) == false)
        #expect(mask.isSolid(x: 0, y: 10) == false)
    }
}

@Suite("Convex Hull Tests")
struct ConvexHullTests {

    @Test("Gift wrap - Square points")
    func testGiftWrapSquare() {
        let points = [
            SIMD2<Float>(0, 0),
            SIMD2<Float>(10, 0),
            SIMD2<Float>(10, 10),
            SIMD2<Float>(0, 10),
            SIMD2<Float>(5, 5),  // Interior point should be excluded
        ]

        let hull = ConvexHullGenerator.giftWrap(points: points)

        #expect(hull.count == 4)
    }

    @Test("Gift wrap - Triangle")
    func testGiftWrapTriangle() {
        let points = [
            SIMD2<Float>(0, 0),
            SIMD2<Float>(10, 0),
            SIMD2<Float>(5, 10),
        ]

        let hull = ConvexHullGenerator.giftWrap(points: points)

        #expect(hull.count == 3)
    }

    @Test("Simplified hull - Reduces vertices")
    func testSimplifiedHull() {
        // Create many points in a circle
        var points: [SIMD2<Float>] = []
        for i in 0..<32 {
            let angle = Float(i) * (2 * .pi / 32)
            points.append(SIMD2<Float>(cos(angle) * 10, sin(angle) * 10))
        }

        let simplified = ConvexHullGenerator.simplifiedHull(points: points, maxVertices: 8)

        #expect(simplified.count <= 8)
    }
}
