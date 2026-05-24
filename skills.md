# Game Systems Reference

This document covers the major gameplay systems in the top-down shooter. Built with **LÖVE 2D** (Lua).

---

## 1. WASD Movement

**File:** `src/entities/player.lua` — `Player:_handleMovement(dt)`

The player faces the mouse cursor at all times. W thrusts forward along that facing direction; A/D strafe relative to it. S is intentionally absent.

### Key functions

| Function | What it does |
|---|---|
| `Player:new(x, y)` | Constructor — initialises velocity, tuning constants, HP, energy |
| `Player:update(dt)` | Main loop — calls rotation, movement, and shooting handlers each frame |
| `Player:_handleRotation()` | Sets `self.angle` to point toward the mouse cursor (screen → world coords via Camera) |
| `Player:_handleMovement(dt)` | Reads WASD, builds a thrust vector, applies acceleration + friction + speed cap |

### Physics model

```lua
-- 1. Build thrust vector from WASD (normalized)
thrustX = forward.x + strafe.x * driftFactor
thrustY = forward.y + strafe.y * driftFactor

-- 2. Accelerate
vx = vx + thrustX * accel * dt
vy = vy + thrustY * accel * dt

-- 3. Exponential friction (natural deceleration ~0.5 s)
vx = vx * math.exp(-friction * dt)
vy = vy * math.exp(-friction * dt)

-- 4. Speed cap
if speed > effectiveMax then
    vx, vy = vx/speed * effectiveMax, vy/speed * effectiveMax
end

-- 5. Integrate
self.x = self.x + vx * dt
self.y = self.y + vy * dt
```

### Tuning constants

| Constant | Value | Effect |
|---|---|---|
| `maxSpeed` | 300 px/s | Top velocity |
| `accel` | 600 px/s² | How quickly the ship reaches max speed |
| `friction` | 6.0 | Exponential drag — higher = stops faster |
| `driftFactor` | 0.45 | Strafe authority (0 = tank turn, 1 = free strafe) |

### Low-energy speed penalty

Below 25% energy the ship begins losing speed. At 0 energy it's capped at 40% of `maxSpeed` (120 px/s). The penalty scales linearly between the threshold and empty.

---

## 2. Shooting & Bullet Pool

**Files:** `src/entities/player.lua` — `Player:_handleShooting(dt)`  
`src/systems/bulletpool.lua` — `BulletPool`  
`src/systems/bullet_shader.glsl`

Hold left-click to fire. Bullets are pre-allocated in a fixed pool of 128 slots so there are no per-shot allocations during gameplay.

### Player → pool wiring

The game state injects a callback into the player at startup:

```lua
-- game.lua (setup)
self.player.onFire = function(x, y, angle)
    self.bulletPool:fire(x, y, angle)
end
```

The player never touches the pool directly — it just calls `self.onFire(mx, my, self.angle)` when firing conditions are met.

### Firing conditions (checked every frame)

```lua
if Input:mouseDown(1)           -- left mouse held
   and self.fireCooldown <= 0   -- cooldown elapsed
   and self.energy >= 4         -- has enough energy
then
    self.onFire(mx, my, self.angle)
    self.fireCooldown = 0.1     -- 10 shots/sec
    self.energy = self.energy - 4
    self._regenTimer = 1.2      -- delay regen
end
```

### BulletPool key functions

| Function | What it does |
|---|---|
| `BulletPool:new()` | Pre-allocates 128 bullet tables; loads the GLSL shader |
| `BulletPool:fire(x, y, angle)` | Claims the next free slot; sets position, velocity, lifetime |
| `BulletPool:update(dt)` | Advances position, ticks lifetime; marks expired bullets inactive |
| `BulletPool:draw()` | Renders all active bullets with the glow shader + additive blending |
| `BulletPool:_claimSlot()` | Round-robin search for the next inactive slot |
| `BulletPool:getActive()` | Returns the list of live bullets (used by collision) |
| `BulletPool:destroy(slot)` | Marks one slot as inactive |

### Bullet stats

| Property | Value |
|---|---|
| Pool size | 128 |
| Fire rate | 10 shots / second |
| Bullet speed | 900 px/s |
| Lifetime | 1.8 seconds |
| Muzzle offset | 24 px from ship center |
| Collision radius | 3 px |

### Glow shader (`bullet_shader.glsl`)

Each bullet is drawn onto a small canvas (48×24 px) then composited with the shader:

- **Core**: Bright tight band along the bolt's long axis
- **Glow**: Soft radial falloff (power 2.2) from the bolt center
- **Blend mode**: Additive — overlapping bolts bloom brighter
- **Fade-out**: Alpha drops over the last 0.3 s of bullet life

---

## 3. Enemy Spawning

**File:** `src/states/game.lua` — `Game:_updateDroneSpawner(dt)`  
**Enemy logic:** `src/entities/drone.lua`

Drones spawn off-screen at a fixed radius from the player on a random timer. There is a hard cap of 16 active drones.

### Spawner algorithm

```lua
self._droneTimer = self._droneTimer - dt

if self._droneTimer <= 0 then
    -- Pick next random interval in [1.8, 3.2] seconds
    local lo, hi = 1.8, 3.2
    self._droneTimer = lo + math.random() * (hi - lo)

    if #self.drones < 16 then
        local angle = math.random() * math.pi * 2     -- random direction
        local sx = self.player.x + math.cos(angle) * 750
        local sy = self.player.y + math.sin(angle) * 750
        self.drones[#self.drones + 1] = Drone:new(sx, sy)
    end
end
```

Drones always spawn 750 px away from the player, so they enter from outside the visible area.

### Spawner configuration

| Property | Value |
|---|---|
| Spawn radius | 750 px from player |
| Spawn interval | Random 1.8–3.2 seconds |
| Max active drones | 16 |
| Initial delay | 2 seconds |

### Drone AI key functions

| Function | What it does |
|---|---|
| `Drone:new(x, y)` | Sets position, velocity, HP (3), state flags |
| `Drone:update(dt, target)` | Steers toward target via `atan2`; accelerates, applies friction, clamps speed |
| `Drone:hit(damage)` | Reduces HP; triggers white flash; calls `_die()` if HP ≤ 0 |
| `Drone:_die()` | Marks drone inactive; calls `_spawnParticles()` |
| `Drone:_spawnParticles()` | Emits 10 shards in random directions with random speed and lifetime |
| `Drone:draw()` | Renders triangle silhouette + glow ring + HP pips; white when flashing |

### Drone stats

| Property | Value |
|---|---|
| HP | 3 |
| Cruise speed | 110 px/s |
| Acceleration | 220 px/s² |
| Friction coefficient | 3.5 (heavier than player) |
| Collision radius | 18 px |
| Contact damage | 1 HP to player |
| Hit flash duration | 0.08 seconds |
| Death particles | 10 shards, 60–180 px/s, 0.4–0.8 s lifetime |

### Homing behaviour (each frame)

1. Compute bearing to player with `math.atan2`
2. Apply acceleration force along that bearing
3. Apply exponential friction (`coeff 3.5`)
4. Clamp velocity magnitude to 110 px/s

---

## 4. Health & Energy System

**File:** `src/entities/player.lua`  
**HUD:** `src/ui/hud.lua`  
**Pickups:** `src/entities/battery.lua`

HP and energy are tracked separately on the player. Both are displayed as animated bars in the HUD.

### Health (HP)

| Property | Value |
|---|---|
| Max HP | 5 |
| Damage per drone contact | 1 |
| Invincibility frames (iframes) | 1.2 seconds |
| Hit flash duration | 0.12 seconds |

```lua
function Player:takeDamage(amount)
    if self._iframes > 0 then return end   -- still invincible
    self.hp = self.hp - amount
    self._iframes = 1.2                    -- start iframes
    self._flashTimer = 0.12               -- white flash
    self:addEnergy(4)                      -- energy refund on hit (risk/reward)
    if self.hp <= 0 then
        -- game state switches to GameOver
    end
end
```

During iframes the ship sprite flickers every 0.1 s to signal immunity. Taking a hit also refunds 4 energy (one shot's worth) — this is intentional risk/reward design.

### Energy

| Property | Value |
|---|---|
| Max energy | 100 |
| Starting energy | 100 |
| Cost per shot | 4 |
| Regen rate | 3.5 units / second |
| Regen delay | 1.2 seconds after last shot |
| Low-energy threshold | 25% (25 units) |
| Min speed at 0 energy | 40% of max speed |

```lua
-- Regen only starts after the delay window expires
if self._regenTimer <= 0 and self.energy < self.maxEnergy then
    self.energy = math.min(self.maxEnergy, self.energy + 3.5 * dt)
end
```

The 1.2 s delay means firing a burst and immediately backing off does not restore energy right away — the player must rely on pickups or accept the speed penalty.

### Battery pickups (`src/entities/battery.lua`)

| Property | Value |
|---|---|
| Energy restored | 40 units |
| Pickup range | 28 px |
| Spawn interval | Random 10–15 seconds |
| Max active | 4 |
| Visual | Pulsing hexagon with lightning bolt |

The game state maintains a pool of 12 preset world-space spawn locations. The spawner picks one that isn't already within 60 px of another battery to avoid stacking.

### HUD bars (`src/ui/hud.lua`)

Both bars animate — they don't snap instantly to the real value:

| Bar | Colour | Low-state alert |
|---|---|---|
| Hull | Red → Orange | Flickers "CRITICAL" at 1 HP |
| Energy | Cyan → Orange-red | Flickers "EMPTY" when < 4 units |

Display values lerp toward the actual values each frame: faster when draining (~100 ms), slightly slower when refilling (~170 ms).

---

## 5. Collision System

**File:** `src/systems/collision.lua` — `Collision.check(bullets, drones, player)`

All hit detection runs in one place, called once per frame from the game state after all entities have updated. Nothing couples directly to anything else.

### Checks performed

| Check | Method | Result |
|---|---|---|
| Bullets vs Drones | Circle–circle (distance < sum of radii) | Bullet destroyed; `drone:hit(1)` |
| Drones vs Player | Circle–circle | `player:takeDamage(1)` |

### Radii used

| Entity | Radius |
|---|---|
| Bullet | 3 px |
| Drone | 18 px |
| Player | ~16 px (`player.w * 0.5`) |

---

## Quick-reference: tuning numbers

| System | Constant | Value |
|---|---|---|
| Movement | Max speed | 300 px/s |
| Movement | Acceleration | 600 px/s² |
| Movement | Friction | 6.0 |
| Movement | Strafe factor | 0.45 |
| Shooting | Fire rate | 10 shots/sec |
| Shooting | Bullet speed | 900 px/s |
| Shooting | Bullet lifetime | 1.8 s |
| Shooting | Pool size | 128 |
| Energy | Max | 100 |
| Energy | Cost/shot | 4 |
| Energy | Regen rate | 3.5/s |
| Energy | Regen delay | 1.2 s |
| Drones | Spawn interval | 1.8–3.2 s |
| Drones | Spawn radius | 750 px |
| Drones | HP | 3 |
| Drones | Speed | 110 px/s |
| Batteries | Spawn interval | 10–15 s |
| Batteries | Energy value | 40 |
