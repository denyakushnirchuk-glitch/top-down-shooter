-- src/entities/player.lua
-- The player entity.
--
-- ── Movement model ────────────────────────────────────────────────────────────
--   W          → thrust forward along facing direction (toward mouse)
--   A / D      → strafe left/right relative to facing; scaled by driftFactor
--   S          → intentionally absent
--   Inertia via acceleration + exponential friction (~0.5 s ramp up/down)
--
-- ── Shooting model ────────────────────────────────────────────────────────────
--   Left mouse button held → fires at fireRate shots/second
--   Bullets spawn at the muzzle tip, not the player centre
--   onFire callback is set by the game state to BulletPool:fire
--   Player itself never knows the pool exists

local Player = {}
Player.__index = Player

-- ─── Constructor ─────────────────────────────────────────────────────────────

function Player:new(x, y)
    local p = setmetatable({}, Player)

    -- World-space position (centre of the sprite)
    p.x = x or 0
    p.y = y or 0

    -- Current velocity (world space, pixels per second)
    p.vx = 0
    p.vy = 0

    -- ── Movement tuning ───────────────────────────────────────────────────
    p.maxSpeed    = 300     -- top speed px/s
    p.accel       = 600     -- acceleration force (maxSpeed / 0.5 s)
    p.friction    = 6.0     -- exponential drag; v *= exp(-friction*dt)
    p.driftFactor = 0.45    -- lateral thrust authority (0=tank, 1=free strafe)

    -- Facing angle in radians (0 = right)
    p.angle = 0

    -- ── Weapon ────────────────────────────────────────────────────────────
    p.fireRate     = 10          -- shots per second
    p.fireInterval = 1 / 10     -- seconds between shots
    p.fireCooldown = 0           -- counts down; fires when <= 0

    -- Muzzle sits at the tip of the forward indicator bar (20 px + a little gap)
    p.muzzleOffset = 24

    -- Injected by game state after pool is created. Signature: fn(x, y, angle)
    p.onFire = nil

    -- ── Hitbox ────────────────────────────────────────────────────────────
    p.w     = 32
    p.h     = 32
    p.drawW = 32
    p.drawH = 32

    return p
end

-- ─── Update ──────────────────────────────────────────────────────────────────

function Player:update(dt)
    self:_handleRotation()
    self:_handleMovement(dt)
    self:_handleShooting(dt)
end

-- ─── Rotation ────────────────────────────────────────────────────────────────

function Player:_handleRotation()
    local mx, my = Input:mousePosition()
    local wx, wy = Camera:toWorld(mx, my)
    self.angle = math.atan2(wy - self.y, wx - self.x)
end

-- ─── Movement ────────────────────────────────────────────────────────────────

function Player:_handleMovement(dt)
    local fwdX =  math.cos(self.angle)
    local fwdY =  math.sin(self.angle)
    local latX = -math.sin(self.angle)
    local latY =  math.cos(self.angle)

    local thrustX, thrustY = 0, 0

    if Input:isDown("w") or Input:isDown("up") then
        thrustX = thrustX + fwdX
        thrustY = thrustY + fwdY
    end
    if Input:isDown("a") or Input:isDown("left") then
        thrustX = thrustX - latX * self.driftFactor
        thrustY = thrustY - latY * self.driftFactor
    end
    if Input:isDown("d") or Input:isDown("right") then
        thrustX = thrustX + latX * self.driftFactor
        thrustY = thrustY + latY * self.driftFactor
    end

    -- Normalise so W+A diagonal doesn't exceed magnitude 1
    local thrustLen = math.sqrt(thrustX * thrustX + thrustY * thrustY)
    if thrustLen > 1 then
        thrustX = thrustX / thrustLen
        thrustY = thrustY / thrustLen
    end

    -- Accelerate
    self.vx = self.vx + thrustX * self.accel * dt
    self.vy = self.vy + thrustY * self.accel * dt

    -- Exponential friction
    local decay = math.exp(-self.friction * dt)
    self.vx = self.vx * decay
    self.vy = self.vy * decay

    -- Speed cap
    local speed = math.sqrt(self.vx * self.vx + self.vy * self.vy)
    if speed > self.maxSpeed then
        local s = self.maxSpeed / speed
        self.vx = self.vx * s
        self.vy = self.vy * s
    end

    -- Integrate
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
end

-- ─── Shooting ────────────────────────────────────────────────────────────────

function Player:_handleShooting(dt)
    -- Tick down cooldown every frame regardless of input
    if self.fireCooldown > 0 then
        self.fireCooldown = self.fireCooldown - dt
    end

    -- Left mouse button held + cooldown expired + callback registered
    if Input:mouseDown(1) and self.fireCooldown <= 0 and self.onFire then
        -- Muzzle world position: step muzzleOffset px ahead of centre
        -- along the current facing direction
        local mx = self.x + math.cos(self.angle) * self.muzzleOffset
        local my = self.y + math.sin(self.angle) * self.muzzleOffset

        self.onFire(mx, my, self.angle)
        self.fireCooldown = self.fireInterval
    end
end

-- ─── Draw ────────────────────────────────────────────────────────────────────

function Player:draw()
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.angle)

    -- Body
    love.graphics.setColor(0.2, 0.6, 1, 1)
    love.graphics.rectangle("fill", -self.drawW/2, -self.drawH/2, self.drawW, self.drawH)

    -- Forward / barrel indicator
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, -4, 20, 8)

    love.graphics.pop()
end

-- ─── Debug ───────────────────────────────────────────────────────────────────

function Player:drawDebug()
    local speed = math.sqrt(self.vx * self.vx + self.vy * self.vy)
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.print(string.format(
        "pos    (%.0f, %.0f)\nvel    (%.0f, %.0f)\nspeed  %.0f / %.0f px/s\nangle  %.2f rad",
        self.x, self.y, self.vx, self.vy,
        speed, self.maxSpeed, self.angle
    ), 10, 10)
end

return Player