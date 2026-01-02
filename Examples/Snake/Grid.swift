import Foundation
import Iris

struct Grid {
    let cellSize: Float
    let rows: Int
    let cols: Int
    let offsetX: Float
    let offsetY: Float

    init(cellSize: Float, rows: Int, cols: Int, offsetX: Float = 0, offsetY: Float = 0) {
        self.cellSize = cellSize
        self.rows = rows
        self.cols = cols
        self.offsetX = offsetX
        self.offsetY = offsetY
    }

    func snapToGrid(x: Float, y: Float) -> (x: Float, y: Float) {
        let gridX = floor((x - offsetX) / cellSize) * cellSize + offsetX
        let gridY = floor((y - offsetY) / cellSize) * cellSize + offsetY
        return (gridX, gridY)
    }

    func gridToPixel(gridX: Int, gridY: Int) -> (x: Float, y: Float) {
        return (Float(gridX) * cellSize + offsetX, Float(gridY) * cellSize + offsetY)
    }

    func pixelToGrid(x: Float, y: Float) -> (gridX: Int, gridY: Int) {
        let gridX = Int((x - offsetX) / cellSize)
        let gridY = Int((y - offsetY) / cellSize)
        return (gridX, gridY)
    }

    func isInBounds(gridX: Int, gridY: Int) -> Bool {
        return gridX >= 0 && gridX < cols && gridY >= 0 && gridY < rows
    }

    func draw(_ g: Graphics) {
        // Draw grid outline with stroke
        let gridColor = Color(r: 0.15, g: 0.2, b: 0.25, a: 0.6)

        // Draw each cell outline
        for row in 0..<rows {
            for col in 0..<cols {
                let x = offsetX + Float(col) * cellSize
                let y = offsetY + Float(row) * cellSize
                g.strokeRect(
                    x: x, y: y,
                    width: cellSize,
                    height: cellSize,
                    strokeWidth: 0.5,
                    color: gridColor
                )
            }
        }
    }
}
