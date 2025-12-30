import Foundation

enum DrawCommand {
    case clear(Color)
    case fillRect(x: Float, y: Float, width: Float, height: Float, color: Color)
}

public final class GraphicsContext: Graphics {
    private(set) var commands: [DrawCommand] = []
    
    public func clear(_ color: Color) {
        commands.append(.clear(color))
    }
    
    public func fillRect(x: Float, y: Float, width: Float, height: Float, color: Color) {
        commands.append(.fillRect(x: x, y: y, width: width, height: height, color: color))
    }
    
    func reset() {
        commands.removeAll(keepingCapacity: true)
    }
}

