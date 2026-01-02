import Iris

enum Direction {
    case up, down, left, right

    var opposite: Direction {
        switch self {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        }
    }
}

struct SnakeSegment {
    var gridX: Int
    var gridY: Int
}

struct Snake {
    var segments: [SnakeSegment]
    var direction: Direction
    var nextDirection: Direction
    var moveTimer: Double = 0
    var moveInterval: Double = 0.15  // Seconds between moves

    init(startX: Int, startY: Int) {
        segments = [
            SnakeSegment(gridX: startX, gridY: startY),
            SnakeSegment(gridX: startX - 1, gridY: startY),
            SnakeSegment(gridX: startX - 2, gridY: startY),
        ]
        direction = .right
        nextDirection = .right
    }

    var head: SnakeSegment {
        return segments[0]
    }

    mutating func setDirection(_ newDirection: Direction) {
        // Prevent reversing into self
        if newDirection != direction.opposite {
            nextDirection = newDirection
        }
    }

    mutating func update(deltaTime: Double) {
        moveTimer += deltaTime
    }

    mutating func shouldMove() -> Bool {
        if moveTimer >= moveInterval {
            moveTimer -= moveInterval
            return true
        }
        return false
    }

    mutating func move() {
        direction = nextDirection

        var newHead = head
        switch direction {
        case .up:
            newHead.gridY -= 1
        case .down:
            newHead.gridY += 1
        case .left:
            newHead.gridX -= 1
        case .right:
            newHead.gridX += 1
        }

        segments.insert(newHead, at: 0)
        segments.removeLast()
    }

    mutating func grow() {
        // Add a segment at the tail
        if let tail = segments.last {
            segments.append(tail)
        }
    }

    func checkSelfCollision() -> Bool {
        let head = segments[0]
        for i in 1..<segments.count {
            if segments[i].gridX == head.gridX && segments[i].gridY == head.gridY {
                return true
            }
        }
        return false
    }

    func draw(_ g: Graphics, grid: Grid) {
        let segmentCount = segments.count

        for (index, segment) in segments.enumerated() {
            let pos = grid.gridToPixel(gridX: segment.gridX, gridY: segment.gridY)
            let cellSize = grid.cellSize

            // Gradient from head (bright green) to tail (darker green)
            let ratio = Float(index) / Float(max(segmentCount - 1, 1))
            let padding: Float = 1.0

            if index == 0 {
                // Head - use radial gradient for depth
                let gradient = Gradient.radial(
                    centerX: pos.x + cellSize / 2,
                    centerY: pos.y + cellSize / 2,
                    radius: cellSize / 2,
                    innerColor: Color(r: 0.4, g: 1.0, b: 0.8),
                    outerColor: Color(r: 0.2, g: 1.0, b: 0.6)
                )
                g.fillRectGradient(
                    x: pos.x + padding,
                    y: pos.y + padding,
                    width: cellSize - padding * 2,
                    height: cellSize - padding * 2,
                    gradient: gradient
                )
            } else {
                // Body - use linear gradient for 3D effect
                let r = 0.1 + (1.0 - ratio) * 0.3
                let gVal = 0.5 + (1.0 - ratio) * 0.5
                let b = 0.2 + (1.0 - ratio) * 0.4

                let gradient = Gradient.linear(
                    startX: pos.x, startY: pos.y,
                    endX: pos.x, endY: pos.y + cellSize,
                    startColor: Color(r: r, g: gVal, b: b),
                    endColor: Color(r: r * 0.7, g: gVal * 0.7, b: b * 0.7)
                )
                g.fillRectGradient(
                    x: pos.x + padding,
                    y: pos.y + padding,
                    width: cellSize - padding * 2,
                    height: cellSize - padding * 2,
                    gradient: gradient
                )
            }

            // Add stroke outline for definition
            g.strokeRect(
                x: pos.x + padding,
                y: pos.y + padding,
                width: cellSize - padding * 2,
                height: cellSize - padding * 2,
                strokeWidth: 1.5,
                color: Color(r: 0.3, g: 0.8, b: 0.5, a: 0.8)
            )
        }
    }
}
