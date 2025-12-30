import Foundation
#if os(macOS)
import CoreGraphics
import CoreText
import AppKit

struct GlyphMetrics {
    let u0: Float
    let v0: Float
    let u1: Float
    let v1: Float
    let width: Float
    let height: Float
    let bearingX: Float
    let bearingY: Float
    let advance: Float
}

struct GlyphAtlasData {
    let width: Int
    let height: Int
    let pixels: [UInt8]
    var bytesPerRow: Int { width * 4 }
}

final class GlyphAtlas {
    private let font: Font
    private let nsFont: NSFont
    private let scale: CGFloat
    
    private var glyphs: [Character: GlyphMetrics] = [:]
    private var atlasPixels: [UInt8] = []
    private var atlasWidth: Int = 1024
    private var atlasHeight: Int = 1024
    
    private var cursorX: Int = 0
    private var cursorY: Int = 0
    private var rowHeight: Int = 0
    
    private(set) var isDirty = true
    private(set) var version: UInt32 = 0
    
    init(font: Font, scale: CGFloat = 2.0) {
        self.font = font
        self.scale = scale
        self.nsFont = NSFont(name: "Menlo", size: CGFloat(font.size) * scale) ?? NSFont.systemFont(ofSize: CGFloat(font.size) * scale)
        atlasPixels = [UInt8](repeating: 0, count: atlasWidth * atlasHeight * 4)
    }
    
    func ensureGlyphs(for text: String) {
        for char in text {
            if glyphs[char] == nil {
                rasterizeGlyph(char)
            }
        }
    }
    
    func getMetrics(for char: Character) -> GlyphMetrics? {
        return glyphs[char]
    }
    
    func getAtlasData() -> GlyphAtlasData {
        isDirty = false
        return GlyphAtlasData(width: atlasWidth, height: atlasHeight, pixels: atlasPixels)
    }
    
    private func rasterizeGlyph(_ char: Character) {
        let string = String(char)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: nsFont,
            .foregroundColor: NSColor.white
        ]
        let attrString = NSAttributedString(string: string, attributes: attributes)
        
        let size = attrString.size()
        let advance = size.width
        
        let padding = 4
        let glyphWidth = Int(ceil(size.width)) + padding * 2
        let glyphHeight = Int(ceil(size.height)) + padding * 2
        
        if glyphWidth <= padding * 2 || glyphHeight <= padding * 2 {
            let metrics = GlyphMetrics(
                u0: 0, v0: 0, u1: 0, v1: 0,
                width: 0, height: 0,
                bearingX: 0, bearingY: 0,
                advance: Float(advance / scale)
            )
            glyphs[char] = metrics
            return
        }
        
        if cursorX + glyphWidth > atlasWidth {
            cursorX = 0
            cursorY += rowHeight + 1
            rowHeight = 0
        }
        
        if cursorY + glyphHeight > atlasHeight {
            growAtlas()
        }
        
        let glyphPixels = renderGlyphToPixels(attrString: attrString, width: glyphWidth, height: glyphHeight, padding: padding)
        
        copyToAtlas(pixels: glyphPixels, x: cursorX, y: cursorY, width: glyphWidth, height: glyphHeight)
        
        let u0 = Float(cursorX) / Float(atlasWidth)
        let u1 = Float(cursorX + glyphWidth) / Float(atlasWidth)
        let v0 = Float(cursorY) / Float(atlasHeight)
        let v1 = Float(cursorY + glyphHeight) / Float(atlasHeight)
        
        let metrics = GlyphMetrics(
            u0: u0, v0: v0, u1: u1, v1: v1,
            width: Float(glyphWidth) / Float(scale),
            height: Float(glyphHeight) / Float(scale),
            bearingX: Float(-padding) / Float(scale),
            bearingY: Float(glyphHeight - padding) / Float(scale),
            advance: Float(advance / scale)
        )
        
        glyphs[char] = metrics
        
        cursorX += glyphWidth + 1
        rowHeight = max(rowHeight, glyphHeight)
        
        isDirty = true
        version += 1
    }
    
    private func renderGlyphToPixels(attrString: NSAttributedString, width: Int, height: Int, padding: Int) -> [UInt8] {
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return pixels
        }
        
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        
        let nsContext = NSGraphicsContext(cgContext: context, flipped: true)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsContext
        
        attrString.draw(at: NSPoint(x: CGFloat(padding), y: CGFloat(padding)))
        
        NSGraphicsContext.restoreGraphicsState()
        
        return pixels
    }
    
    private func copyToAtlas(pixels: [UInt8], x: Int, y: Int, width: Int, height: Int) {
        for row in 0..<height {
            let srcOffset = row * width * 4
            let dstOffset = ((y + row) * atlasWidth + x) * 4
            for col in 0..<width {
                atlasPixels[dstOffset + col * 4 + 0] = pixels[srcOffset + col * 4 + 0]
                atlasPixels[dstOffset + col * 4 + 1] = pixels[srcOffset + col * 4 + 1]
                atlasPixels[dstOffset + col * 4 + 2] = pixels[srcOffset + col * 4 + 2]
                atlasPixels[dstOffset + col * 4 + 3] = pixels[srcOffset + col * 4 + 3]
            }
        }
    }
    
    private func growAtlas() {
        let newWidth = atlasWidth * 2
        let newHeight = atlasHeight * 2
        var newPixels = [UInt8](repeating: 0, count: newWidth * newHeight * 4)
        
        for row in 0..<atlasHeight {
            let srcOffset = row * atlasWidth * 4
            let dstOffset = row * newWidth * 4
            for i in 0..<(atlasWidth * 4) {
                newPixels[dstOffset + i] = atlasPixels[srcOffset + i]
            }
        }
        
        atlasWidth = newWidth
        atlasHeight = newHeight
        atlasPixels = newPixels
        
        for (char, metrics) in glyphs {
            let newU0 = metrics.u0 / 2
            let newU1 = metrics.u1 / 2
            let newV0 = metrics.v0 / 2
            let newV1 = metrics.v1 / 2
            
            glyphs[char] = GlyphMetrics(
                u0: newU0, v0: newV0, u1: newU1, v1: newV1,
                width: metrics.width, height: metrics.height,
                bearingX: metrics.bearingX, bearingY: metrics.bearingY,
                advance: metrics.advance
            )
        }
        
        isDirty = true
        version += 1
    }
}

@MainActor
final class GlyphAtlasManager {
    static let shared = GlyphAtlasManager()
    
    private var atlases: [UInt32: GlyphAtlas] = [:]
    
    private init() {}
    
    func getAtlas(for font: Font) -> GlyphAtlas {
        if let existing = atlases[font.id] {
            return existing
        }
        
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let atlas = GlyphAtlas(font: font, scale: scale)
        atlases[font.id] = atlas
        return atlas
    }
}
#endif
