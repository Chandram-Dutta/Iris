import Foundation

/// Efficient bitmask representation for pixel-perfect collision detection.
/// Stores opacity data as packed bits for memory efficiency.
public struct PixelMask: Sendable {
    /// Width of the mask in pixels
    public let width: Int

    /// Height of the mask in pixels
    public let height: Int

    /// Packed bitmask data (1 bit per pixel, stored in UInt64 words)
    private let bits: [UInt64]

    /// Number of bits per word
    private static let bitsPerWord = 64

    /// Creates a pixel mask with the specified dimensions and bit data.
    internal init(width: Int, height: Int, bits: [UInt64]) {
        self.width = width
        self.height = height
        self.bits = bits
    }

    /// Creates an empty pixel mask with the specified dimensions.
    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
        let totalBits = width * height
        let wordCount = (totalBits + Self.bitsPerWord - 1) / Self.bitsPerWord
        self.bits = [UInt64](repeating: 0, count: wordCount)
    }

    /// Checks if the pixel at (x, y) is solid (opaque).
    /// - Parameters:
    ///   - x: X coordinate (0-based)
    ///   - y: Y coordinate (0-based)
    /// - Returns: True if the pixel is solid
    public func isSolid(x: Int, y: Int) -> Bool {
        guard x >= 0 && x < width && y >= 0 && y < height else {
            return false
        }

        let bitIndex = y * width + x
        let wordIndex = bitIndex / Self.bitsPerWord
        let bitOffset = bitIndex % Self.bitsPerWord

        guard wordIndex < bits.count else {
            return false
        }

        return (bits[wordIndex] & (1 << bitOffset)) != 0
    }

    /// Creates a pixel mask from raw RGBA pixel data.
    /// - Parameters:
    ///   - pixels: RGBA pixel data (4 bytes per pixel)
    ///   - width: Width in pixels
    ///   - height: Height in pixels
    ///   - alphaThreshold: Minimum alpha value to consider solid (0-255)
    /// - Returns: A PixelMask where pixels above the threshold are solid
    public static func fromPixels(
        _ pixels: [UInt8],
        width: Int,
        height: Int,
        alphaThreshold: UInt8 = 128
    ) -> PixelMask {
        let totalBits = width * height
        let wordCount = (totalBits + bitsPerWord - 1) / bitsPerWord
        var bits = [UInt64](repeating: 0, count: wordCount)

        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (y * width + x) * 4

                // Check alpha channel (4th byte in RGBA)
                guard pixelIndex + 3 < pixels.count else { continue }
                let alpha = pixels[pixelIndex + 3]

                if alpha >= alphaThreshold {
                    let bitIndex = y * width + x
                    let wordIndex = bitIndex / bitsPerWord
                    let bitOffset = bitIndex % bitsPerWord
                    bits[wordIndex] |= (1 << bitOffset)
                }
            }
        }

        return PixelMask(width: width, height: height, bits: bits)
    }

    /// Counts the number of solid pixels in the mask.
    public var solidPixelCount: Int {
        var count = 0
        for word in bits {
            count += word.nonzeroBitCount
        }
        // Adjust for any padding bits in the last word
        let totalBits = width * height
        let paddingBits = bits.count * Self.bitsPerWord - totalBits
        if paddingBits > 0 && !bits.isEmpty {
            // The last word might have extra counted bits
            let lastWord = bits[bits.count - 1]
            let validBitsInLast = totalBits % Self.bitsPerWord
            if validBitsInLast > 0 {
                let mask = (UInt64(1) << validBitsInLast) - 1
                let actualLastCount = (lastWord & mask).nonzeroBitCount
                let overcounted = lastWord.nonzeroBitCount - actualLastCount
                count -= overcounted
            }
        }
        return count
    }

    /// Returns a list of all solid pixel coordinates (useful for convex hull generation).
    public func solidPixelCoordinates() -> [SIMD2<Float>] {
        var coords: [SIMD2<Float>] = []
        coords.reserveCapacity(min(solidPixelCount, 10000))  // Limit for performance

        for y in 0..<height {
            for x in 0..<width {
                if isSolid(x: x, y: y) {
                    coords.append(SIMD2<Float>(Float(x), Float(y)))

                    // Limit coordinates for large images
                    if coords.count >= 10000 {
                        return coords
                    }
                }
            }
        }

        return coords
    }

    /// Samples edge pixels for convex hull generation (more efficient than all pixels).
    public func edgePixelCoordinates() -> [SIMD2<Float>] {
        var coords: [SIMD2<Float>] = []

        for y in 0..<height {
            for x in 0..<width {
                if isSolid(x: x, y: y) && isEdge(x: x, y: y) {
                    coords.append(SIMD2<Float>(Float(x), Float(y)))
                }
            }
        }

        return coords
    }

    /// Checks if a solid pixel is on the edge (has at least one non-solid neighbor).
    private func isEdge(x: Int, y: Int) -> Bool {
        // Check 4-connectivity neighbors
        let neighbors = [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]

        for (nx, ny) in neighbors {
            if !isSolid(x: nx, y: ny) {
                return true
            }
        }

        return false
    }
}

extension PixelMask {
    /// Checks for collision between two pixel masks at given positions.
    /// Uses AABB pre-filtering for efficiency.
    /// - Parameters:
    ///   - other: The other pixel mask
    ///   - selfPosition: Position of this mask
    ///   - otherPosition: Position of the other mask
    /// - Returns: True if any solid pixels overlap
    public func collides(
        with other: PixelMask,
        selfPosition: SIMD2<Float>,
        otherPosition: SIMD2<Float>
    ) -> Bool {
        // Calculate overlap region
        let selfMinX = Int(selfPosition.x)
        let selfMinY = Int(selfPosition.y)
        let selfMaxX = selfMinX + width
        let selfMaxY = selfMinY + height

        let otherMinX = Int(otherPosition.x)
        let otherMinY = Int(otherPosition.y)
        let otherMaxX = otherMinX + other.width
        let otherMaxY = otherMinY + other.height

        // Calculate intersection region
        let intersectMinX = max(selfMinX, otherMinX)
        let intersectMinY = max(selfMinY, otherMinY)
        let intersectMaxX = min(selfMaxX, otherMaxX)
        let intersectMaxY = min(selfMaxY, otherMaxY)

        // No overlap
        if intersectMinX >= intersectMaxX || intersectMinY >= intersectMaxY {
            return false
        }

        // Check each pixel in the overlap region
        for y in intersectMinY..<intersectMaxY {
            for x in intersectMinX..<intersectMaxX {
                let selfLocalX = x - selfMinX
                let selfLocalY = y - selfMinY
                let otherLocalX = x - otherMinX
                let otherLocalY = y - otherMinY

                if isSolid(x: selfLocalX, y: selfLocalY)
                    && other.isSolid(x: otherLocalX, y: otherLocalY)
                {
                    return true
                }
            }
        }

        return false
    }
}
