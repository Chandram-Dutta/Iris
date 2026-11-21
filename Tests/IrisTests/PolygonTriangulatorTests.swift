import Testing
@testable import Iris

struct PolygonTriangulatorTests {
    @Test(arguments: [false, true])
    func convexSquare(clockwise: Bool) {
        let points: [SIMD2<Float>] = [[0, 0], [2, 0], [2, 2], [0, 2]]
        checkTriangulation(clockwise ? Array(points.reversed()) : points)
    }

    @Test(arguments: [false, true])
    func offsetSquare(clockwise: Bool) {
        let points: [SIMD2<Float>] = [
            [20000, 20000.5], [20005, 20000.5], [20005, 20005.5], [20000, 20005.5],
        ]
        checkTriangulation(clockwise ? Array(points.reversed()) : points, expectedArea: 25)
    }

    @Test(arguments: [false, true])
    func concavePolygon(clockwise: Bool) {
        let points: [SIMD2<Float>] = [[0, 0], [3, 0], [3, 1], [1, 1], [1, 3], [0, 3]]
        checkTriangulation(clockwise ? Array(points.reversed()) : points)
    }

    @Test func fewerThanThreePoints() {
        #expect(PolygonTriangulator.triangulate([]).isEmpty)
        #expect(PolygonTriangulator.triangulate([[0, 0]]).isEmpty)
        #expect(PolygonTriangulator.triangulate([[0, 0], [1, 0]]).isEmpty)
    }

    private func checkTriangulation(_ points: [SIMD2<Float>], expectedArea: Float? = nil) {
        let indices = PolygonTriangulator.triangulate(points)
        #expect(indices.count == (points.count - 2) * 3)

        var triangleArea: Float = 0
        for i in stride(from: 0, to: indices.count, by: 3) {
            let a = points[indices[i]]
            let b = points[indices[i + 1]]
            let c = points[indices[i + 2]]
            triangleArea += abs((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)) / 2
        }

        var signedArea: Float = 0
        for i in points.indices {
            let a = points[i]
            let b = points[(i + 1) % points.count]
            signedArea += a.x * b.y - b.x * a.y
        }
        #expect(abs(triangleArea - (expectedArea ?? abs(signedArea) / 2)) < 0.0001)
    }
}
