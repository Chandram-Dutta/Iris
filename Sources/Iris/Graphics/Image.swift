import Foundation

#if os(macOS)
    import CoreGraphics
    import ImageIO
#endif

/// A handle to a loaded image asset.
public struct Image: Equatable, Hashable, Sendable {
    let id: UInt32

    init(id: UInt32) {
        self.id = id
    }

    /// Loads an image from the specified path.
    /// Supports PNG and other common formats. Images are cached by path.
    /// - Parameter path: The file path to the image.
    /// - Returns: An `Image` handle if successful, `nil` otherwise.
    public static func load(_ path: String) -> Image? {
        return ImageCache.shared.load(path: path)
    }

    /// Returns the dimensions of this image.
    public var size: (width: Int, height: Int)? {
        guard let data = ImageCache.shared.getData(for: self) else {
            return nil
        }
        return (data.width, data.height)
    }

    /// Generates a convex hull hitbox from the image's transparency.
    /// The convex hull tightly wraps around the non-transparent pixels.
    /// - Parameters:
    ///   - alphaThreshold: Minimum alpha value (0-255) to consider a pixel solid
    ///   - simplified: If true, reduces vertices for better performance
    /// - Returns: A Hitbox with polygon shape, or nil if image data unavailable
    public func generateHitbox(alphaThreshold: UInt8 = 128, simplified: Bool = true) -> Hitbox? {
        guard let mask = generatePixelMask(alphaThreshold: alphaThreshold) else {
            return nil
        }

        let hullVertices = ConvexHullGenerator.fromPixelMask(mask, simplified: simplified)

        guard hullVertices.count >= 3 else {
            // Fallback to AABB
            return Hitbox(
                x: 0, y: 0,
                shape: .aabb(width: Float(mask.width), height: Float(mask.height))
            )
        }

        return Hitbox(x: 0, y: 0, shape: .polygon(vertices: hullVertices))
    }

    /// Generates a pixel-perfect collision mask from the image's transparency.
    /// - Parameter alphaThreshold: Minimum alpha value (0-255) to consider a pixel solid
    /// - Returns: A PixelMask for pixel-perfect collision, or nil if image data unavailable
    public func generatePixelMask(alphaThreshold: UInt8 = 128) -> PixelMask? {
        guard let data = ImageCache.shared.getData(for: self) else {
            return nil
        }

        return PixelMask.fromPixels(
            data.pixels,
            width: data.width,
            height: data.height,
            alphaThreshold: alphaThreshold
        )
    }
}

struct ImageData: Sendable {
    let width: Int
    let height: Int
    let pixels: [UInt8]

    var bytesPerRow: Int { width * 4 }
}

final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()

    private var images: [UInt32: ImageData] = [:]
    private var pathToId: [String: UInt32] = [:]
    private var nextId: UInt32 = 1
    private let lock = NSLock()

    private init() {}

    func load(path: String) -> Image? {
        lock.lock()
        defer { lock.unlock() }

        if let existingId = pathToId[path] {
            return Image(id: existingId)
        }

        guard let data = loadPNG(path: path) else {
            return nil
        }

        let id = nextId
        nextId += 1

        images[id] = data
        pathToId[path] = id

        return Image(id: id)
    }

    func getData(for image: Image) -> ImageData? {
        lock.lock()
        defer { lock.unlock() }
        return images[image.id]
    }

    private func loadPNG(path: String) -> ImageData? {
        #if os(macOS)
            return loadPNGCoreGraphics(path: path)
        #else
            return nil
        #endif
    }

    #if os(macOS)
        private func loadPNGCoreGraphics(path: String) -> ImageData? {
            guard let url = resolveImagePath(path),
                let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
            else {
                print("[ImageCache] Failed to load image: \(path)")
                return nil
            }

            let width = cgImage.width
            let height = cgImage.height

            var pixels = [UInt8](repeating: 0, count: width * height * 4)

            guard
                let context = CGContext(
                    data: &pixels,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: width * 4,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                )
            else {
                print("[ImageCache] Failed to create graphics context")
                return nil
            }

            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

            return ImageData(width: width, height: height, pixels: pixels)
        }

        private func resolveImagePath(_ path: String) -> URL? {
            let fileManager = FileManager.default

            if fileManager.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }

            let currentDir = fileManager.currentDirectoryPath
            let fullPath = (currentDir as NSString).appendingPathComponent(path)
            if fileManager.fileExists(atPath: fullPath) {
                return URL(fileURLWithPath: fullPath)
            }

            if let bundlePath = Bundle.main.path(
                forResource: (path as NSString).deletingPathExtension,
                ofType: (path as NSString).pathExtension)
            {
                return URL(fileURLWithPath: bundlePath)
            }

            return nil
        }
    #endif
}
