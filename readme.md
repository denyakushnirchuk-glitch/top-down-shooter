# Top-Down-Shooter

A top-down arcade shooter set in a system orbiting a pulsar star. Pilot a ship through hostile space, manage your energy supply, and survive increasingly relentless waves of enemy drones.

> 🚧 **Currently in pre-alpha.** Core systems are in place and the game is playable, but content, art, and features are still being built out.

---

## Gameplay

You control a ship with momentum-based movement — thrust toward your cursor, strafe with A/D, and let inertia carry you. Your laser cannon runs on energy. Energy depletes when you fire and regenerates slowly when you stop. Run dry and your ship slows to a crawl.

Energy cells spawn across the map on a timer. Getting hit by a drone refunds one shot — staying close to enemies is risky but keeps you in the fight.

The goal is simple: survive as long as possible and push your kill count higher.

---

## Current Features

- Inertia-based movement with facing-relative drift
- Laser cannon with GLSL glow shader and object pooling
- Energy system with passive regen, speed penalty at low energy, and battery pickups
- Homing drone enemies with HP, hit flash, and death burst particles
- Off-screen indicators — arrows point to any drone or battery outside your view
- HUD with hull integrity bar, energy bar, and kill counter
- All visuals drawn with Love2D primitives — no external sprites

---

## Roadmap

- [ ] Main menu and game-over screen
- [ ] Wave / difficulty scaling system
- [ ] Sound effects and music
- [ ] Multiple enemy types
- [ ] Boss encounters
- [ ] Level progression around the pulsar system
- [ ] Final ship and enemy art
- [ ] Score saving

---

## Controls

| Input | Action |
|---|---|
| `W` | Thrust forward (toward cursor) |
| `A` / `D` | Strafe left / right |
| Left mouse button | Fire |
| `F1` | Debug overlay |
| `Escape` | Quit |

---

## Running the game

### Play a release (no setup needed)
Head to [**Releases**](../../releases) and download the build for your platform.

### Run from source
You need [Love2D 11.5](https://love2d.org) installed.

```bash
git clone https://github.com/your-username/top-down-shooter.git
cd top-down-shooter
love .
```

---

## Project structure

```
top-down-shooter/
├── main.lua                  # Entry point and Love2D callbacks
├── conf.lua                  # Window and module configuration
├── src/
│   ├── entities/
│   │   ├── player.lua        # Movement, shooting, health, energy
│   │   ├── drone.lua         # Homing enemy, hit/death, particles
│   │   └── battery.lua       # Energy pickup
│   ├── systems/
│   │   ├── bulletpool.lua    # Fixed-size object pool for projectiles
│   │   ├── bullet_shader.glsl# GLSL glow shader for laser bolts
│   │   ├── camera.lua        # 2D camera with lerp follow
│   │   ├── collision.lua     # Centralised hit detection
│   │   ├── indicators.lua    # Off-screen entity arrows
│   │   ├── input.lua         # Per-frame input snapshot
│   │   └── statemanager.lua  # Simple game state machine
│   ├── states/
│   │   └── game.lua          # Main gameplay scene
│   └── ui/
│       └── hud.lua           # Hull, energy bars, kill counter
└── assets/                   # Sprites, audio, fonts (populated later)
```

---

## Built with

- [Love2D 11.5](https://love2d.org) — Lua game framework
- Lua 5.1
- GLSL (OpenGL ES 2) — bullet glow shader

---

## License

[MIT](LICENSE)