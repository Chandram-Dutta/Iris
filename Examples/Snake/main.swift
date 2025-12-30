import Iris

let game = SnakeGame()
let engine = Engine()

let config = WindowConfig(
    width: 800,
    height: 600,
    title: "Snake - Iris Engine",
    resizable: false
)

engine.run(game: game, config: config)
