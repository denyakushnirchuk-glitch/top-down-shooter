-- src/entities/drone.lua
-- The "Drone" enemy type.
--
-- ── Behaviour ─────────────────────────────────────────────────────────────────
--   Spawns at a position outside the player's view (supplied by the spawner).
--   Each frame steers directly toward the player using atan2, then accelerates
--   along that bearing. No fancy pathfinding — raw homing is enough at this
--   stage and already feels threatening because the player can't just run.
--
-- ── Health & hits ─────────────────────────────────────────────────────────────
--   hp / maxHp tracked here.
--   hit(damage) flashes the drone white, subtracts HP, triggers death if <= 0.
--   Dead drones spawn a small burst of particle shards stored on self.particles.
--   game.lua updates + draws those shards after removing the drone itself.
--
-- ── Collision ─────────────────────────────────────────────────────────────────
--   self.radius — circle used by the collision system for both bullet hits
--   and player contact damage.

local Drone = {}
Drone.__index = Drone

-- ─── Tuning ──────────────────────────────────────────────────────────────────

local SPEED        = 110      -- px/s cruise speed toward player
local ACCEL        = 220      -- px/s² acceleration
local FRICTION     = 3.5      -- exponential drag (lower than player = heavier feel)
local RADIUS       = 18       -- collision circle radius
local MAX_HP       = 3        -- shots to kill
local CONTACT_DMG  = 1        -- damage dealt to player on overlap
local FLASH_TIME   = 0.08     -- seconds the drone stays white after a hit

-- Death burst: N shards fly outward from the death position
local SHARD_COUNT  = 10
local SHARD_SPEED  = { 60, 180 }   -- min/max shard speed px/s
local SHARD_LIFE   = { 0.4, 0.8 }  -- min/max shard lifetime seconds

-- ─── Constructor ─────────────────────────────────────────────────────────────

function Drone:new(x, y)
    local d = setmetatable({}, Drone)

    d.x      = x or 0
    d.y      = y or 0
    d.vx     = 0
    d.vy     = 0
    d.angle  = 0          -- facing (visual only — drone always faces its target)

    d.hp     = MAX_HP
    d.maxHp  = MAX_HP
    d.radius = RADIUS

    d.active = true

    -- Flash state: when > 0 the drone renders white
    d._flashTimer = 0

    -- Particles spawned on death — kept here so game.lua can update them
    -- after the drone itself is removed from the active list
    d.particles = {}

    return d
end

-- ─── Update ──────────────────────────────────────────────────────────────────

-- target: any table with .x and .y (the player)
function Drone:update(dt, target)
    if not self.active then return end

    -- Flash timer
    if self._flashTimer > 0 then
        self._flashTimer = self._flashTimer - dt
    end

    -- Steer toward target
    local dx = target.x - self.x
    local dy = target.y - self.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist > 1 then
        -- Unit vector toward player
        local nx = dx / dist
        local ny = dy / dist

        -- Accelerate in that direction
        self.vx = self.vx + nx * ACCEL * dt
        self.vy = self.vy + ny * ACCEL * dt

        -- Face the direction of travel
        self.angle = math.atan2(self.vy, self.vx)
    end

    -- Exponential friction (same formula as player)
    local decay = math.exp(-FRICTION * dt)
    self.vx = self.vx * decay
    self.vy = self.vy * decay

    -- Speed cap
    local speed = math.sqrt(self.vx * self.vx + self.vy * self.vy)
    if speed > SPEED then
        local s = SPEED / speed
        self.vx = self.vx * s
        self.vy = self.vy * s
    end

    -- Integrate position
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
end

-- ─── Hit & Death ─────────────────────────────────────────────────────────────

-- Returns true if the drone dies from this hit.
function Drone:hit(damage)
    if not self.active then return false end

    self.hp = self.hp - (damage or 1)
    self._flashTimer = FLASH_TIME

    if self.hp <= 0 then
        self:_die()
        return true
    end
    return false
end

function Drone:_die()
    self.active = false
    self:_spawnParticles()
end

function Drone:_spawnParticles()
    for _ = 1, SHARD_COUNT do
        local angle = math.random() * math.pi * 2
        local spd   = SHARD_SPEED[1] + math.random() * (SHARD_SPEED[2] - SHARD_SPEED[1])
        local life  = SHARD_LIFE[1]  + math.random() * (SHARD_LIFE[2]  - SHARD_LIFE[1])
        -- Slight size variation for visual interest
        local sz    = 2 + math.random() * 3

        self.particles[#self.particles + 1] = {
            x    = self.x,
            y    = self.y,
            vx   = math.cos(angle) * spd,
            vy   = math.sin(angle) * spd,
            life = life,
            maxLife = life,
            size = sz,
        }
    end
end

-- ─── Draw ────────────────────────────────────────────────────────────────────

function Drone:draw()
    if not self.active then return end

    local flashing = self._flashTimer > 0

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.angle)

    -- Outer glow ring (additive so it blooms on dark bg)
    love.graphics.setBlendMode("add")
    if flashing then
        love.graphics.setColor(1, 1, 1, 0.4)
    else
        love.graphics.setColor(0.8, 0.15, 0.05, 0.3)
    end
    love.graphics.circle("fill", 0, 0, RADIUS + 5)
    love.graphics.setBlendMode("alpha")

    -- Body: triangular silhouette pointing in travel direction
    -- Triangle vertices relative to centre: nose forward (+X), two rear corners
    local r = RADIUS
    local verts = {
         r,       0,        -- nose  (forward)
        -r * 0.7, r * 0.6,  -- rear-left
        -r * 0.4, 0,        -- rear-centre dent (makes it look less like a pizza slice)
        -r * 0.7,-r * 0.6,  -- rear-right
    }

    if flashing then
        love.graphics.setColor(1, 1, 1, 1)
    else
        love.graphics.setColor(0.85, 0.18, 0.08, 1)
    end
    love.graphics.polygon("fill", verts)

    -- Border
    love.graphics.setColor(1, 0.4, 0.2, 0.9)
    love.graphics.setLineWidth(1.5)
    love.graphics.polygon("line", verts)
    love.graphics.setLineWidth(1)

    -- HP pips: small dots below the sprite (1 dot per remaining HP)
    -- Drawn in local space so they rotate with the drone
    love.graphics.setBlendMode("alpha")
    for i = 1, self.maxHp do
        local px = -r + (i - 1) * 10 + 5
        if i <= self.hp then
            love.graphics.setColor(1, 0.4, 0.1, 1)
        else
            love.graphics.setColor(0.3, 0.1, 0.05, 0.8)
        end
        love.graphics.circle("fill", px - (self.maxHp - 1) * 5, r + 8, 3)
    end

    love.graphics.pop()
end

-- ─── Static: draw a single particle shard ────────────────────────────────────
-- Called by game.lua for each particle in drone.particles after the drone dies.

function Drone.drawParticle(p)
    local frac  = p.life / p.maxLife
    local alpha = frac * frac    -- quadratic fade for a sharper tail-off

    love.graphics.setBlendMode("add")
    love.graphics.setColor(1, 0.35 + frac * 0.3, 0.1, alpha)
    love.graphics.circle("fill", p.x, p.y, p.size * frac)
    love.graphics.setBlendMode("alpha")
end

-- ─── Static: update a single particle ────────────────────────────────────────

function Drone.updateParticle(p, dt)
    p.x    = p.x + p.vx * dt
    p.y    = p.y + p.vy * dt
    p.life = p.life - dt
    -- Drag so shards coast to a stop
    p.vx   = p.vx * 0.92
    p.vy   = p.vy * 0.92
end

return Drone