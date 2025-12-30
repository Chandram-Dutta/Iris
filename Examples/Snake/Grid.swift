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
        // Draw subtle grid lines
        let gridColor = Color(r: 0.1, g: 0.15, b: 0.2)

        // Vertical lines
        for i in 0...cols {
            let x = offsetX + Float(i) * cellSize
            g.fillRect(x: x, y: offsetY, width: 1, height: Float(rows) * cellSize, color: gridColor)
        }

        // Horizontal lines
        for i in 0...rows {
            let y = offsetY + Float(i) * cellSize
            g.fillRect(x: offsetX, y: y, width: Float(cols) * cellSize, height: 1, color: gridColor)
        }
    }
}
