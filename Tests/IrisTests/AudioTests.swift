import Foundation
import Testing

@testable import Iris

@Suite("Audio")
struct AudioTests {

    @Test func soundHandleEquality() {
        #expect(Sound(id: 1) == Sound(id: 1))
        #expect(Sound(id: 1) != Sound(id: 2))
    }

    @Test func soundHandleHashing() {
        let set: Set<Sound> = [Sound(id: 1), Sound(id: 1), Sound(id: 2)]
        #expect(set.count == 2)
    }

    @Test func musicHandleEquality() {
        #expect(Music(id: 1) == Music(id: 1))
        #expect(Music(id: 1) != Music(id: 2))
    }

    @Test func volumeClamping() {
        #expect(Audio.clampVolume(-0.5) == 0)
        #expect(Audio.clampVolume(1.7) == 1)
        #expect(Audio.clampVolume(0.5) == 0.5)
    }

    @Test func missingFileReturnsNil() {
        #expect(Sound.load("definitely_not_here_9999.wav") == nil)
        #expect(Music.load("definitely_not_here_9999.wav") == nil)
    }

    #if os(macOS)
        @Test func loadsGeneratedWAVAndCachesHandle() throws {
            let path = FileManager.default.temporaryDirectory
                .appendingPathComponent("iris-audio-test.wav").path
            try makeWAV().write(to: URL(fileURLWithPath: path))
            defer { try? FileManager.default.removeItem(atPath: path) }

            let first = Sound.load(path)
            #expect(first != nil)

            let second = Sound.load(path)
            #expect(second == first)
        }

        /// Builds a minimal 16-bit mono PCM WAV in memory.
        private func makeWAV(samples: Int = 1000, sampleRate: UInt32 = 22050) -> Data {
            var data = Data()
            func append(_ value: UInt32) {
                withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
            }
            func append(_ value: UInt16) {
                withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
            }

            let dataSize = UInt32(samples * 2)
            data.append(contentsOf: Array("RIFF".utf8))
            append(36 + dataSize)
            data.append(contentsOf: Array("WAVE".utf8))
            data.append(contentsOf: Array("fmt ".utf8))
            append(UInt32(16))
            append(UInt16(1))  // PCM
            append(UInt16(1))  // mono
            append(sampleRate)
            append(sampleRate * 2)  // byte rate
            append(UInt16(2))  // block align
            append(UInt16(16))  // bits per sample
            data.append(contentsOf: Array("data".utf8))
            append(dataSize)
            for i in 0..<samples {
                let value = Int16(8000 * sin(Double(i) * 0.1))
                withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
            }
            return data
        }
    #endif
}
