import Foundation
import Iris

enum FoodType {
    case normal
    case bonus

    var points: Int {
        switch self {
        case .normal: return 10
        case .bonus: return 50
        }
    }

    var color: Color {
        switch self {
        case .normal: return Color(r: 1.0, g: 0.2, b: 0.2)  // Red
        case .bonus: return Color(r: 1.0, g: 0.84, b: 0.0)  // Gold
        }
    }
}

struct Food {
    var gridX: Int
    var gridY: Int
    var type: FoodType
    var pulseTime: Double = 0

    init(gridX: Int, gridY: Int, type: FoodType = .normal) {
        self.gridX = gridX
        self.gridY = gridY
        self.type = type
    }

    mutating func update(deltaTime: Double) {
        pulseTime += deltaTime * 3.0  // Pulse speed
    }

    func draw(_ g: Graphics, grid: Grid) {
        let pos = grid.gridToPixel(gridX: gridX, gridY: gridY)
        let cellSize = grid.cellSize

        // Pulsing effect
        let pulse = Float(sin(pulseTime) * 0.15 + 0.85)  // 0.7 to 1.0
        let size = cellSize * pulse
        let offset = (cellSize - size) / 2

        // Draw food with glow effect
        let glowSize = size * 1.3
        let glowOffset = (cellSize - glowSize) / 2
        let glowColor = Color(
            r: type.color.r,
            g: type.color.g,
            b: type.color.b,
            a: 0.3 * pulse
        )

        // Outer glow
        g.fillRect(
            x: pos.x + glowOffset,
            y: pos.y + glowOffset,
            width: glowSize,
            height: glowSize,
            color: glowColor
        )

        // Main food
        g.fillRect(
            x: pos.x + offset,
            y: pos.y + offset,
            width: size,
            height: size,
            color: type.color
        )

        // Highlight
        let highlightSize = size * 0.4
        let highlightOffset = offset + size * 0.15
        let highlightColor = Color(r: 1.0, g: 1.0, b: 1.0, a: 0.6)
        g.fillRect(
            x: pos.x + highlightOffset,
            y: pos.y + highlightOffset,
            width: highlightSize,
            height: highlightSize,
            color: highlightColor
        )
    }
}
