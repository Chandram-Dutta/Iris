import Iris

struct Brick {
    let x: Float
    let y: Float
    let width: Float
    let height: Float
    var isActive: Bool = true
    let color: Color

    var rect: (x: Float, y: Float, w: Float, h: Float) {
        return (x, y, width, height)
    }
}
