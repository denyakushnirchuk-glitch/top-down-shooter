-- src/entities/player.lua
-- The player entity.
--
-- ── Movement model ────────────────────────────────────────────────────────────
--
--  INERTIA
--    Velocity is never set directly. Instead, an acceleration force is applied
--    each frame in the input direction, and a friction force bleeds it off when
--    no input is held. This gives the 0→speed ramp (~0.5 s) and the
--    speed→0 coast you asked for.
--
--    accel  = how fast velocity builds       (units/s²)
--    friction = how fast velocity decays     (multiplier per second, 0–1)
--
--  FACING-RELATIVE DRIFT
--    Raw input (WASD) is expressed in WORLD space (W = up the screen).
--    We decompose that world-space wish vector into two components:
--      • forward/back  — aligned with the facing angle
--      • lateral       — 90° to the facing angle (strafe)
--    The lateral component is scaled down by `driftFactor` (0–1).
--    At 0 the ship can only move where it faces (tank controls).
--    At 1 there is no penalty for strafing (old behaviour).
--    We use ~0.35 so strafing is possible but bleeds speed sideways.
--
--  Rotation model:
--    Mouse position converted from screen → world space via Camera.
--    math.atan2 gives the angle from player to cursor.

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

    -- ── Tuning knobs ──────────────────────────────────────────────────────
    p.maxSpeed    = 300     -- top speed in pixels/second (bumped from 220)
    p.accel       = 600     -- acceleration force  (maxSpeed / 0.5 s = 600)
    p.friction    = 6.0     -- exponential drag coefficient; higher = stops faster
                            -- velocity decays as:  v = v * exp(-friction * dt)
                            -- at 6.0, full speed → ~0 in ≈ 0.5 s after releasing keys

    -- How much lateral (strafe) thrust is respected vs. redirected.
    -- 0.0 = pure tank controls (must face direction of travel)
    -- 1.0 = no penalty (full strafe)
    -- 0.45 = strafing works but bleeds momentum sideways over time
    p.driftFactor = 0.45

    -- Facing angle in radians (0 = pointing right on screen)
    p.angle = 0

    -- Hitbox (axis-aligned, centred on x,y)
    p.w = 32
    p.h = 32

    -- Draw size for the placeholder shape
    p.drawW = 32
    p.drawH = 32

    return p
end

-- ─── Update ──────────────────────────────────────────────────────────────────

function Player:update(dt)
    self:_handleRotation()      -- facing angle must be fresh before movement
    self:_handleMovement(dt)
end

-- ─── Rotation ────────────────────────────────────────────────────────────────

function Player:_handleRotation()
    local mx, my = Input:mousePosition()
    local wx, wy = Camera:toWorld(mx, my)
    -- atan2(dy, dx) → angle of the vector (player → mouse), in radians
    self.angle = math.atan2(wy - self.y, wx - self.x)
end

-- ─── Movement ────────────────────────────────────────────────────────────────

function Player:_handleMovement(dt)

    -- Forward axis: the direction the player is currently facing.
    -- This is a unit vector derived from the mouse-aim angle.
    local fwdX =  math.cos(self.angle)   -- forward X
    local fwdY =  math.sin(self.angle)   -- forward Y
    -- Lateral axis: 90° clockwise from forward.
    -- A positive dot product here means "strafe right".
    local latX = -math.sin(self.angle)   -- right-strafe X  (−sin, cos rotates CCW)
    local latY =  math.cos(self.angle)   -- right-strafe Y

    -- ── 1. Build thrust vector from keys ──────────────────────────────────
    --    W  → full thrust along forward axis (toward mouse)
    --    A  → full thrust along −lateral axis (strafe left)
    --    D  → full thrust along +lateral axis (strafe right)
    --    S  → intentionally absent
    local thrustX, thrustY = 0, 0

    if Input:isDown("w") or Input:isDown("up") then
        -- Push directly in the facing direction
        thrustX = thrustX + fwdX
        thrustY = thrustY + fwdY
    end

    if Input:isDown("a") or Input:isDown("left") then
        -- Strafe left = push along the negative lateral axis
        -- driftFactor scales this so strafing has less authority than
        -- forward movement, creating the natural drift effect
        thrustX = thrustX - latX * self.driftFactor
        thrustY = thrustY - latY * self.driftFactor
    end

    if Input:isDown("d") or Input:isDown("right") then
        -- Strafe right = push along the positive lateral axis
        thrustX = thrustX + latX * self.driftFactor
        thrustY = thrustY + latY * self.driftFactor
    end

    -- Normalise so W+A together don't give more thrust than W alone.
    -- Without this, diagonal input has magnitude √2 ≈ 1.41.
    local thrustLen = math.sqrt(thrustX * thrustX + thrustY * thrustY)
    if thrustLen > 1 then
        thrustX = thrustX / thrustLen
        thrustY = thrustY / thrustLen
    end

    -- ── 2. Apply acceleration ──────────────────────────────────────────────
    --    F = m·a; we assume unit mass, so Δv = accel * direction * dt
    self.vx = self.vx + thrustX * self.accel * dt
    self.vy = self.vy + thrustY * self.accel * dt

    -- ── 3. Apply exponential friction ─────────────────────────────────────
    --    Exponential decay: v *= e^(-friction * dt)
    --    This is frame-rate independent and never overshoots zero (unlike
    --    linear subtraction which can flip sign on a slow frame).
    local decay = math.exp(-self.friction * dt)
    self.vx = self.vx * decay
    self.vy = self.vy * decay

    -- ── 4. Clamp to max speed ─────────────────────────────────────────────
    local speed = math.sqrt(self.vx * self.vx + self.vy * self.vy)
    if speed > self.maxSpeed then
        local scale = self.maxSpeed / speed
        self.vx = self.vx * scale
        self.vy = self.vy * scale
    end

    -- ── 5. Integrate position ─────────────────────────────────────────────
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
end

-- ─── Draw ────────────────────────────────────────────────────────────────────

function Player:draw()
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.angle)

    -- Body
    love.graphics.setColor(0.2, 0.6, 1, 1)
    love.graphics.rectangle("fill", -self.drawW/2, -self.drawH/2, self.drawW, self.drawH)

    -- Forward indicator (points in the +X / facing direction)
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
        self.x, self.y,
        self.vx, self.vy,
        speed, self.maxSpeed,
        self.angle
    ), 10, 10)
end

return Player