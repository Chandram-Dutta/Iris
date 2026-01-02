import Foundation

// MARK: - Cross-platform matrix types and operations

/// 4x4 matrix for transformations (cross-platform)
public struct matrix_float4x4: Sendable {
    public var columns: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>)

    public init(
        _ col0: SIMD4<Float>, _ col1: SIMD4<Float>, _ col2: SIMD4<Float>, _ col3: SIMD4<Float>
    ) {
        self.columns = (col0, col1, col2, col3)
    }

    public init(columns: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>)) {
        self.columns = columns
    }
}

/// 4x4 identity matrix
public let matrix_identity_float4x4 = matrix_float4x4(
    SIMD4<Float>(1, 0, 0, 0),
    SIMD4<Float>(0, 1, 0, 0),
    SIMD4<Float>(0, 0, 1, 0),
    SIMD4<Float>(0, 0, 0, 1)
)

/// Multiply two 4x4 matrices (cross-platform)
public func matrix_multiply(_ a: matrix_float4x4, _ b: matrix_float4x4) -> matrix_float4x4 {
    var result = matrix_identity_float4x4

    for i in 0..<4 {
        let bCol = getColumn(b, i)
        var resCol = SIMD4<Float>(0, 0, 0, 0)

        for j in 0..<4 {
            let aRow = getRow(a, j)
            let dot = aRow.x * bCol.x + aRow.y * bCol.y + aRow.z * bCol.z + aRow.w * bCol.w
            resCol[j] = dot
        }

        setColumn(&result, i, resCol)
    }

    return result
}

private func getColumn(_ mat: matrix_float4x4, _ index: Int) -> SIMD4<Float> {
    switch index {
    case 0: return mat.columns.0
    case 1: return mat.columns.1
    case 2: return mat.columns.2
    case 3: return mat.columns.3
    default: return SIMD4<Float>(0, 0, 0, 0)
    }
}

private func getRow(_ mat: matrix_float4x4, _ index: Int) -> SIMD4<Float> {
    return SIMD4<Float>(
        mat.columns.0[index],
        mat.columns.1[index],
        mat.columns.2[index],
        mat.columns.3[index]
    )
}

private func setColumn(_ mat: inout matrix_float4x4, _ index: Int, _ value: SIMD4<Float>) {
    switch index {
    case 0: mat.columns.0 = value
    case 1: mat.columns.1 = value
    case 2: mat.columns.2 = value
    case 3: mat.columns.3 = value
    default: break
    }
}

// MARK: - SIMD Helper Extensions

extension SIMD2 where Scalar == Float {
    /// Cross-platform length (magnitude) of a 2D vector
    public func length() -> Float {
        return sqrt(self.x * self.x + self.y * self.y)
    }

    /// Cross-platform length squared of a 2D vector
    public func lengthSquared() -> Float {
        return self.x * self.x + self.y * self.y
    }
}
