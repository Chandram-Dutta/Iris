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

        // Draw food with radial gradient glow effect
        let gradient = Gradient.radial(
            centerX: pos.x + cellSize / 2,
            centerY: pos.y + cellSize / 2,
            radius: size / 2,
            innerColor: Color(
                r: min(1.0, type.color.r * 1.5),
                g: min(1.0, type.color.g * 1.5),
                b: min(1.0, type.color.b * 1.5)
            ),
            outerColor: type.color
        )

        g.fillRectGradient(
            x: pos.x + offset,
            y: pos.y + offset,
            width: size,
            height: size,
            gradient: gradient
        )

        // Add pulsing stroke effect for bonus food
        if type == .bonus {
            let strokeRadius = (size / 2) * 1.2
            g.strokeCircle(
                x: pos.x + cellSize / 2,
                y: pos.y + cellSize / 2,
                radius: strokeRadius,
                width: 2.0,
                color: Color(r: type.color.r, g: type.color.g, b: type.color.b, a: pulse * 0.8)
            )
        }

        // Highlight using gradient
        let highlightSize = size * 0.4
        let highlightOffset = offset + size * 0.15
        let highlightGradient = Gradient.radial(
            centerX: pos.x + highlightOffset + highlightSize / 2,
            centerY: pos.y + highlightOffset + highlightSize / 2,
            radius: highlightSize / 2,
            innerColor: Color(r: 1.0, g: 1.0, b: 1.0, a: 0.8),
            outerColor: Color(r: 1.0, g: 1.0, b: 1.0, a: 0.2)
        )
        g.fillRectGradient(
            x: pos.x + highlightOffset,
            y: pos.y + highlightOffset,
            width: highlightSize,
            height: highlightSize,
            gradient: highlightGradient
        )
    }
}
