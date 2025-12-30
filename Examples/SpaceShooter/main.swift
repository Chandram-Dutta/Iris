import Iris

let game = SpaceShooterGame()
let engine = Engine()

let config = WindowConfig(
    width: 800,
    height: 600,
    title: "Space Shooter - Iris Engine",
    resizable: false
)

engine.run(game: game, config: config)
