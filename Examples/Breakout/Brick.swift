import Iris

struct Brick {
    let x: Float
    let y: Float
    let width: Float
    let height: Float
    var isActive: Bool = true
    let color: Color

    /// AABB hitbox for brick collision
    var hitbox: Hitbox

    init(x: Float, y: Float, width: Float, height: Float, color: Color) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.color = color
        self.hitbox = Hitbox(x: x, y: y, shape: .aabb(width: width, height: height))
    }

    var rect: (x: Float, y: Float, w: Float, h: Float) {
        return (x, y, width, height)
    }
}
