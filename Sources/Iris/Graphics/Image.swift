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
