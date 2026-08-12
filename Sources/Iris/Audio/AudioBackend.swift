#if os(macOS)
    import AVFoundation
    import Foundation

    /// The macOS audio backend built on AVAudioEngine.
    /// A fixed pool of player nodes provides low-latency, overlapping sound
    /// effect playback; a dedicated node handles the single music channel.
    final class AudioBackend: @unchecked Sendable {
        static let shared = AudioBackend()

        private static let sfxVoiceCount = 16

        private let engine = AVAudioEngine()
        private var sfxNodes: [AVAudioPlayerNode] = []
        private let musicNode = AVAudioPlayerNode()
        private var nextVoice = 0

        let canonicalFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!

        private var sfxBuffers: [UInt32: AVAudioPCMBuffer] = [:]
        private var musicBuffers: [UInt32: AVAudioPCMBuffer] = [:]

        private var startFailed = false
        private var musicActive = false
        private var musicPaused = false
        private var currentMusic: (id: UInt32, volume: Float, loop: Bool)?

        private let lock = NSLock()

        private init() {
            for _ in 0..<Self.sfxVoiceCount {
                let node = AVAudioPlayerNode()
                engine.attach(node)
                engine.connect(node, to: engine.mainMixerNode, format: canonicalFormat)
                sfxNodes.append(node)
            }
            engine.attach(musicNode)
            engine.connect(musicNode, to: engine.mainMixerNode, format: canonicalFormat)
            engine.prepare()

            // The engine stops itself when the output device changes
            // (e.g. headphones plugged in); restart so audio keeps working.
            NotificationCenter.default.addObserver(
                forName: .AVAudioEngineConfigurationChange,
                object: engine,
                queue: nil
            ) { [weak self] _ in
                self?.handleConfigurationChange()
            }
        }

        func register(sfxBuffer: AVAudioPCMBuffer, for id: UInt32) {
            lock.lock()
            defer { lock.unlock() }
            sfxBuffers[id] = sfxBuffer
        }

        func register(musicBuffer: AVAudioPCMBuffer, for id: UInt32) {
            lock.lock()
            defer { lock.unlock() }
            musicBuffers[id] = musicBuffer
        }

        func playSound(id: UInt32, volume: Float) {
            lock.lock()
            defer { lock.unlock() }

            guard let buffer = sfxBuffers[id], ensureRunning() else { return }

            // Round-robin voice stealing: if all voices are busy,
            // the oldest one is cut off.
            let node = sfxNodes[nextVoice]
            nextVoice = (nextVoice + 1) % sfxNodes.count

            node.stop()
            node.volume = volume
            node.scheduleBuffer(buffer, at: nil, options: [])
            node.play()
        }

        func playMusic(id: UInt32, volume: Float, loop: Bool) {
            lock.lock()
            defer { lock.unlock() }

            guard let buffer = musicBuffers[id], ensureRunning() else { return }

            musicNode.stop()
            musicNode.volume = volume
            musicNode.scheduleBuffer(buffer, at: nil, options: loop ? [.loops] : [])
            musicNode.play()

            musicActive = true
            musicPaused = false
            currentMusic = (id, volume, loop)
        }

        func pauseMusic() {
            lock.lock()
            defer { lock.unlock() }
            guard musicActive, !musicPaused else { return }
            musicNode.pause()
            musicPaused = true
        }

        func resumeMusic() {
            lock.lock()
            defer { lock.unlock() }
            guard musicActive, musicPaused, ensureRunning() else { return }
            musicNode.play()
            musicPaused = false
        }

        func stopMusic() {
            lock.lock()
            defer { lock.unlock() }
            guard musicActive else { return }
            musicNode.stop()
            musicActive = false
            musicPaused = false
            currentMusic = nil
        }

        func setMusicVolume(_ volume: Float) {
            lock.lock()
            defer { lock.unlock() }
            musicNode.volume = volume
            if let music = currentMusic {
                currentMusic = (music.id, volume, music.loop)
            }
        }

        func stopAll() {
            lock.lock()
            defer { lock.unlock() }
            for node in sfxNodes {
                node.stop()
            }
            musicNode.stop()
            musicActive = false
            musicPaused = false
            currentMusic = nil
        }

        private func ensureRunning() -> Bool {
            if engine.isRunning { return true }
            do {
                try engine.start()
                startFailed = false
                return true
            } catch {
                if !startFailed {
                    print("[AudioBackend] Failed to start audio engine: \(error)")
                    startFailed = true
                }
                return false
            }
        }

        private func handleConfigurationChange() {
            lock.lock()
            defer { lock.unlock() }

            guard ensureRunning() else { return }

            // Player node schedules are lost on a configuration change;
            // restart the music track if one was playing.
            if musicActive, !musicPaused, let music = currentMusic,
                let buffer = musicBuffers[music.id]
            {
                musicNode.stop()
                musicNode.volume = music.volume
                musicNode.scheduleBuffer(buffer, at: nil, options: music.loop ? [.loops] : [])
                musicNode.play()
            }
        }
    }

    /// Decodes audio files (.wav, .mp3, .m4a, ...) into PCM buffers
    /// matching the backend's canonical format.
    enum AudioFileLoader {
        static func loadBuffer(path: String) -> AVAudioPCMBuffer? {
            guard let url = resolvePath(path),
                let file = try? AVAudioFile(forReading: url)
            else {
                return nil
            }

            let format = file.processingFormat
            let frameCount = AVAudioFrameCount(file.length)
            guard frameCount > 0,
                let inBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
            else {
                return nil
            }

            do {
                try file.read(into: inBuffer)
            } catch {
                return nil
            }

            let canonical = AudioBackend.shared.canonicalFormat
            if format == canonical {
                return inBuffer
            }
            return convert(inBuffer, to: canonical)
        }

        private static func convert(
            _ buffer: AVAudioPCMBuffer, to format: AVAudioFormat
        ) -> AVAudioPCMBuffer? {
            guard let converter = AVAudioConverter(from: buffer.format, to: format) else {
                return nil
            }

            let ratio = format.sampleRate / buffer.format.sampleRate
            let capacity = AVAudioFrameCount((Double(buffer.frameLength) * ratio).rounded(.up)) + 64
            guard let outBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity)
            else {
                return nil
            }

            var consumed = false
            var error: NSError?
            let status = converter.convert(to: outBuffer, error: &error) { _, outStatus in
                if consumed {
                    outStatus.pointee = .endOfStream
                    return nil
                }
                consumed = true
                outStatus.pointee = .haveData
                return buffer
            }

            guard status != .error else { return nil }
            return outBuffer
        }

        private static func resolvePath(_ path: String) -> URL? {
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
    }
#endif
