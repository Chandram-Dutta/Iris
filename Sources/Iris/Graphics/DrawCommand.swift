import Foundation

enum DrawCommand {
    case clear(Color)
    case fillRect(x: Float, y: Float, width: Float, height: Float, color: Color)
    case drawImage(image: Image, x: Float, y: Float)
    case drawText(text: String, x: Float, y: Float, font: Font, color: Color)
}

final class GraphicsContext: Graphics {
    private(set) var commands: [DrawCommand] = []
    
    func clear(_ color: Color) {
        commands.append(.clear(color))
    }
    
    func fillRect(x: Float, y: Float, width: Float, height: Float, color: Color) {
        commands.append(.fillRect(x: x, y: y, width: width, height: height, color: color))
    }
    
    func drawImage(_ image: Image, x: Float, y: Float) {
        commands.append(.drawImage(image: image, x: x, y: y))
    }
    
    func drawText(_ text: String, x: Float, y: Float, font: Font, color: Color) {
        commands.append(.drawText(text: text, x: x, y: y, font: font, color: color))
    }
    
    func reset() {
        commands.removeAll(keepingCapacity: true)
    }
}

