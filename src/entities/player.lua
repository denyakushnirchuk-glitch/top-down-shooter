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

    -- ── Energy ────────────────────────────────────────────────────────────
    -- Each shot costs energyPerShot. Energy slowly regenerates when not firing.
    -- Regen pauses for regenDelay seconds after the last shot (like a cooldown
    -- before recharging), so the player can't spam and immediately recover.
    p.energy        = 100
    p.maxEnergy     = 100
    p.energyPerShot = 4
    p.regenRate     = 3.5       -- units/second (~4x faster than before)
    p.regenDelay    = 1.2
    p._regenTimer   = 0

    -- ── Low-energy speed penalty ──────────────────────────────────────────
    -- Kicks in below 25% energy (was 10%) so it's clearly felt during play.
    -- At 0 energy speed drops to 40% of max (was 35%).
    p.lowEnergyThreshold = 0.25  -- penalty starts below 25%
    p.lowSpeedMult       = 0.40  -- floor: 300 * 0.40 = 120 px/s at empty

    -- ── Hitbox ────────────────────────────────────────────────────────────
    p.w     = 32
    p.h     = 32
    p.drawW = 32
    p.drawH = 32

    -- ── Health ────────────────────────────────────────────────────────────
    -- takeDamage() is called by the collision system.
    -- iframes prevent the same drone contact from dealing damage every frame.
    p.hp        = 5
    p.maxHp     = 5
    p.alive     = true

    p._iframeTimer    = 0     -- counts down; damage blocked while > 0
    p._iframeDuration = 1.2   -- seconds of invincibility after each hit
    p._hitFlash       = 0     -- brief white flash when hit (visual only)

    return p
end

-- ─── Update ──────────────────────────────────────────────────────────────────

function Player:update(dt)
    self:_handleRotation()
    self:_handleMovement(dt)
    self:_handleShooting(dt)

    if self._iframeTimer  > 0 then self._iframeTimer  = self._iframeTimer  - dt end
    if self._hitFlash     > 0 then self._hitFlash     = self._hitFlash     - dt end
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

    -- Speed cap — reduced when energy is critically low
    -- Compute effective max speed: full speed above threshold, linearly
    -- scaled down toward lowSpeedMult * maxSpeed at zero energy.
    local energyFrac    = self.energy / self.maxEnergy
    local speedMult     = 1.0
    if energyFrac < self.lowEnergyThreshold then
        -- How far into the penalty zone are we? (1.0 = at threshold, 0.0 = empty)
        local t    = energyFrac / self.lowEnergyThreshold
        speedMult  = self.lowSpeedMult + (1.0 - self.lowSpeedMult) * t
    end
    local effectiveMax = self.maxSpeed * speedMult

    local speed = math.sqrt(self.vx * self.vx + self.vy * self.vy)
    if speed > effectiveMax then
        local s = effectiveMax / speed
        self.vx = self.vx * s
        self.vy = self.vy * s
    end

    -- Integrate
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
end

-- ─── Shooting ────────────────────────────────────────────────────────────────

function Player:_handleShooting(dt)
    -- Tick fire cooldown
    if self.fireCooldown > 0 then
        self.fireCooldown = self.fireCooldown - dt
    end

    -- Tick regen delay
    if self._regenTimer > 0 then
        self._regenTimer = self._regenTimer - dt
    end

    -- Fire: button held + cooldown ready + callback exists + enough energy
    if Input:mouseDown(1) and self.fireCooldown <= 0
       and self.onFire and self.energy >= self.energyPerShot then

        local mx = self.x + math.cos(self.angle) * self.muzzleOffset
        local my = self.y + math.sin(self.angle) * self.muzzleOffset

        self.onFire(mx, my, self.angle)
        self.fireCooldown = self.fireInterval

        -- Deduct energy and reset the regen delay window
        self.energy      = self.energy - self.energyPerShot
        self._regenTimer = self.regenDelay
    end

    -- Regen: only runs when the delay window has fully elapsed
    if self._regenTimer <= 0 and self.energy < self.maxEnergy then
        self.energy = math.min(self.maxEnergy, self.energy + self.regenRate * dt)
    end
end

-- Called by battery pickup system.
function Player:addEnergy(amount)
    self.energy = math.min(self.maxEnergy, self.energy + amount)
end

-- Called by collision system. Respects invincibility frames.
function Player:takeDamage(amount)
    if self._iframeTimer > 0 then return end
    if not self.alive then return end

    self.hp = self.hp - (amount or 1)
    self._iframeTimer = self._iframeDuration
    self._hitFlash    = 0.12

    -- Being hit by a drone rewards exactly 1 shot's worth of energy.
    -- Risk/reward: staying close to drones refills your gun but costs HP.
    self:addEnergy(self.energyPerShot)

    if self.hp <= 0 then
        self.hp    = 0
        self.alive = false
    end
end

-- ─── Draw ────────────────────────────────────────────────────────────────────

function Player:draw()
    -- During iframes, flicker the sprite every 0.1 s so the player
    -- gets clear visual feedback that they're temporarily invincible.
    local inIframes = self._iframeTimer > 0
    if inIframes and (math.floor(self._iframeTimer / 0.1) % 2 == 0) then
        return   -- skip draw on alternating frames = flicker
    end

    local flashing = self._hitFlash > 0

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.angle)

    -- Body
    if flashing then
        love.graphics.setColor(1, 1, 1, 1)
    else
        love.graphics.setColor(0.2, 0.6, 1, 1)
    end
    love.graphics.rectangle("fill", -self.drawW/2, -self.drawH/2, self.drawW, self.drawH)

    -- Forward / barrel indicator
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, -4, 20, 8)

    love.graphics.pop()
end

-- ─── Debug ───────────────────────────────────────────────────────────────────

function Player:drawDebug()
    local speed     = math.sqrt(self.vx * self.vx + self.vy * self.vy)
    local energyFrac = self.energy / self.maxEnergy
    local speedMult  = 1.0
    if energyFrac < self.lowEnergyThreshold then
        local t = energyFrac / self.lowEnergyThreshold
        speedMult = self.lowSpeedMult + (1.0 - self.lowSpeedMult) * t
    end

    -- Draw each line separately with explicit Y so font size changes
    -- never cause overlap. Default Love2D font is ~13 px tall; 18 px step.
    local lines = {
        string.format("pos    (%.0f, %.0f)", self.x, self.y),
        string.format("vel    (%.0f, %.0f)", self.vx, self.vy),
        string.format("speed  %.0f / %.0f px/s  (mult %.2f)", speed, self.maxSpeed, speedMult),
        string.format("angle  %.2f rad", self.angle),
        string.format("energy %.0f / %.0f  (%.0f%%)", self.energy, self.maxEnergy, energyFrac * 100),
        string.format("hp     %d / %d  iframes: %.2f s", self.hp, self.maxHp, math.max(0, self._iframeTimer)),
    }
    local lh = 18   -- line height px
    love.graphics.setColor(1, 1, 0, 1)
    for i, line in ipairs(lines) do
        love.graphics.print(line, 10, 10 + (i - 1) * lh)
    end
end

return Player