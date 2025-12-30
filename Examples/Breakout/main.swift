import Iris

let game = BreakoutGame()
let engine = Engine()

let config = WindowConfig(
    width: 800,
    height: 600,
    title: "Breakout - Iris Engine",
    resizable: false
)

engine.run(game: game, config: config)
