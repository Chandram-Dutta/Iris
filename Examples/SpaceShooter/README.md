# Space Shooter 🚀

A classic arcade-style space shooter game built with the Iris engine.

## Controls

- **WASD** or **Arrow Keys**: Move your spaceship
- **Space**: Fire bullets
- **ESC**: Pause/Resume game

## Gameplay

- Shoot down enemy aliens as they descend from above
- Avoid colliding with enemies
- Earn 100 points per wave for each enemy destroyed
- Every 5th wave enemies spawn faster
- Earn a bonus life every 3 waves (max 5 lives)

## Features

- AI-generated pixel art sprites for:
  - Player spaceship
  - Enemy aliens
  - Bullets
  - Explosions
- Animated starfield background
- Wave-based difficulty progression
- Score tracking with high score
- Visual feedback (damage flash, screen shake tracked)
- Pause functionality

## Running

```bash
swift run SpaceShooter
```

## Resources

The game uses AI-generated pixel art images stored in the `Resources/` folder:
- `spaceship.png` - Player ship sprite
- `enemy.png` - Enemy alien sprite
- `bullet.png` - Laser bullet sprite
- `explosion.png` - Explosion effect sprite
