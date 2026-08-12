import Foundation

/// A handle to a loaded sound effect.
///
/// Sound effects are fire-and-forget: each `play()` starts an independent
/// voice, so the same sound can overlap itself (e.g. rapid gunfire).
public struct Sound: Equatable, Hashable, Sendable {
    let id: UInt32

    init(id: UInt32) {
        self.id = id
    }

    /// Loads a sound effect from the specified path.
    /// Supports WAV, MP3, and M4A. Sounds are cached by path.
    /// - Parameter path: The file path to the audio file.
    /// - Returns: A `Sound` handle if successful, `nil` otherwise.
    public static func load(_ path: String) -> Sound? {
        return AudioCache.shared.load(path: path)
    }

    /// Plays this sound. Overlapping plays of the same sound are allowed.
    /// - Parameter volume: Playback volume, clamped to 0...1.
    public func play(volume: Float = 1.0) {
        #if os(macOS)
            AudioBackend.shared.playSound(id: id, volume: Audio.clampVolume(volume))
        #endif
    }
}

enum Audio {
    static func clampVolume(_ volume: Float) -> Float {
        return max(0, min(1, volume))
    }

    static func stopAll() {
        #if os(macOS)
            AudioBackend.shared.stopAll()
        #endif
    }
}

final class AudioCache: @unchecked Sendable {
    static let shared = AudioCache()

    private var pathToId: [String: UInt32] = [:]
    private var nextId: UInt32 = 1
    private let lock = NSLock()

    private init() {}

    func load(path: String) -> Sound? {
        lock.lock()
        defer { lock.unlock() }

        if let existingId = pathToId[path] {
            return Sound(id: existingId)
        }

        let id = nextId
        guard loadBuffer(path: path, id: id) else {
            print("[AudioCache] Failed to load sound: \(path)")
            return nil
        }

        nextId += 1
        pathToId[path] = id

        return Sound(id: id)
    }

    private func loadBuffer(path: String, id: UInt32) -> Bool {
        #if os(macOS)
            guard let buffer = AudioFileLoader.loadBuffer(path: path) else {
                return false
            }
            AudioBackend.shared.register(sfxBuffer: buffer, for: id)
            return true
        #else
            return false
        #endif
    }
}
