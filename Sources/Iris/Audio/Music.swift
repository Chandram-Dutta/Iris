import Foundation

/// A handle to a loaded music track.
///
/// There is a single music channel: playing a track replaces whatever was
/// playing before. The channel is controlled with the static
/// `pause()`, `resume()`, `stop()`, and `setVolume(_:)` methods.
///
/// Tracks are fully decoded into memory for gapless looping, so prefer
/// short loops over long recordings.
public struct Music: Equatable, Hashable, Sendable {
    let id: UInt32

    init(id: UInt32) {
        self.id = id
    }

    /// Loads a music track from the specified path.
    /// Supports WAV, MP3, and M4A. Tracks are cached by path.
    /// - Parameter path: The file path to the audio file.
    /// - Returns: A `Music` handle if successful, `nil` otherwise.
    public static func load(_ path: String) -> Music? {
        return MusicCache.shared.load(path: path)
    }

    /// Starts this track, replacing any currently playing music.
    /// - Parameters:
    ///   - volume: Playback volume, clamped to 0...1.
    ///   - loop: Whether the track repeats seamlessly. Defaults to `true`.
    public func play(volume: Float = 1.0, loop: Bool = true) {
        #if os(macOS)
            AudioBackend.shared.playMusic(id: id, volume: Audio.clampVolume(volume), loop: loop)
        #endif
    }

    /// Pauses the music channel. No-op if nothing is playing.
    public static func pause() {
        #if os(macOS)
            AudioBackend.shared.pauseMusic()
        #endif
    }

    /// Resumes the music channel after a pause. No-op if nothing was paused.
    public static func resume() {
        #if os(macOS)
            AudioBackend.shared.resumeMusic()
        #endif
    }

    /// Stops the music channel. No-op if nothing is playing.
    public static func stop() {
        #if os(macOS)
            AudioBackend.shared.stopMusic()
        #endif
    }

    /// Sets the music channel volume.
    /// - Parameter volume: Playback volume, clamped to 0...1.
    public static func setVolume(_ volume: Float) {
        #if os(macOS)
            AudioBackend.shared.setMusicVolume(Audio.clampVolume(volume))
        #endif
    }
}

final class MusicCache: @unchecked Sendable {
    static let shared = MusicCache()

    private var pathToId: [String: UInt32] = [:]
    private var nextId: UInt32 = 1
    private let lock = NSLock()

    private init() {}

    func load(path: String) -> Music? {
        lock.lock()
        defer { lock.unlock() }

        if let existingId = pathToId[path] {
            return Music(id: existingId)
        }

        let id = nextId
        guard loadBuffer(path: path, id: id) else {
            print("[MusicCache] Failed to load music: \(path)")
            return nil
        }

        nextId += 1
        pathToId[path] = id

        return Music(id: id)
    }

    private func loadBuffer(path: String, id: UInt32) -> Bool {
        #if os(macOS)
            guard let buffer = AudioFileLoader.loadBuffer(path: path) else {
                return false
            }
            AudioBackend.shared.register(musicBuffer: buffer, for: id)
            return true
        #else
            return false
        #endif
    }
}
