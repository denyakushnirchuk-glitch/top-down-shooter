-- src/systems/bulletpool.lua
-- Laser-cannon projectile system.
--
-- ── Rendering approach ────────────────────────────────────────────────────────
-- Each bullet is drawn as a small canvas stamped to screen each frame.
-- The shader runs WHILE DRAWING TO SCREEN (not during pre-render).
-- A single canvas is used as a proxy geometry surface; the shader reads its
-- UV coordinates to compute the glow shape.
--
-- Blend mode "add" makes overlapping bolts bloom brighter — correct for lasers.

local BulletPool = {}
BulletPool.__index = BulletPool

-- ─── Constants ───────────────────────────────────────────────────────────────

local POOL_SIZE  = 128
local BOLT_SPEED = 900
local BOLT_LIFE  = 1.8
local BOLT_W     = 32
local BOLT_H     = 8
local BOLT_R     = 3

-- ─── Constructor ─────────────────────────────────────────────────────────────

function BulletPool:new()
    local bp = setmetatable({}, BulletPool)

    -- Pre-allocate all slots — no table creation during gameplay
    bp.pool = {}
    for i = 1, POOL_SIZE do
        bp.pool[i] = {
            active = false,
            x = 0, y = 0,
            vx = 0, vy = 0,
            angle = 0,
            life  = 0,
            radius = BOLT_R,
        }
    end
    bp._nextSlot = 1

    -- Small canvas sized exactly to the bolt + glow bleed room.
    -- The shader reads UV coords across this canvas to shape the glow.
    local pad = 8
    bp._cw = BOLT_W + pad * 2
    bp._ch = BOLT_H + pad * 2
    bp._canvas = love.graphics.newCanvas(bp._cw, bp._ch)

    -- Origin = centre of canvas, so love.graphics.draw rotates around the bolt centre
    bp._ox = bp._cw / 2
    bp._oy = bp._ch / 2

    -- Load shader — the shader runs each frame when we draw the canvas to screen
    local ok, result = pcall(love.graphics.newShader, "src/systems/bullet_shader.glsl")
    if ok then
        bp._shader = result
        -- Send constant uniforms once here; size is the only one needed at load time
        bp._shader:send("size",      {bp._cw, bp._ch})
        bp._shader:send("coreColor", {0.85, 1.0, 1.0, 1.0})
        bp._shader:send("glowColor", {0.0,  0.75, 1.0, 0.9})
        bp._shader:send("glowPower", 2.2)
        print("[BulletPool] Shader loaded OK")
    else
        bp._shader = nil
        print("[BulletPool] Shader FAILED: " .. tostring(result))
        print("[BulletPool] Falling back to plain rectangle rendering")
    end

    -- Fill the canvas with solid white — the shader uses this as its input
    -- texture and applies the glow shape via UV math, ignoring the actual
    -- pixel colour of the source (it's just geometry to the shader).
    love.graphics.setCanvas(bp._canvas)
    love.graphics.clear(1, 1, 1, 1)
    love.graphics.setCanvas()

    return bp
end

-- ─── Fire ────────────────────────────────────────────────────────────────────

function BulletPool:fire(x, y, angle)
    local slot = self:_claimSlot()
    if not slot then return nil end

    slot.active = true
    slot.x      = x
    slot.y      = y
    slot.vx     = math.cos(angle) * BOLT_SPEED
    slot.vy     = math.sin(angle) * BOLT_SPEED
    slot.angle  = angle
    slot.life   = BOLT_LIFE

    return slot
end

-- ─── Update ──────────────────────────────────────────────────────────────────

function BulletPool:update(dt)
    for i = 1, POOL_SIZE do
        local b = self.pool[i]
        if b.active then
            b.x    = b.x + b.vx * dt
            b.y    = b.y + b.vy * dt
            b.life = b.life - dt
            if b.life <= 0 then b.active = false end
        end
    end
end

-- ─── Draw ────────────────────────────────────────────────────────────────────

function BulletPool:draw()
    -- "add" blend: each bolt's colour is ADDED to whatever is behind it.
    -- Two overlapping bolts become twice as bright — correct laser behaviour.
    love.graphics.setBlendMode("add")

    if self._shader then
        love.graphics.setShader(self._shader)
    end

    for i = 1, POOL_SIZE do
        local b = self.pool[i]
        if b.active then
            -- Fade out during the last 0.3 s of life
            local alpha = math.min(1.0, b.life / 0.3)
            love.graphics.setColor(1, 1, 1, alpha)

            -- Draw the canvas at the bolt's world position.
            -- The shader runs per-pixel of this canvas as it lands on screen.
            love.graphics.draw(
                self._canvas,
                b.x, b.y,
                b.angle,
                1, 1,
                self._ox,
                self._oy
            )
        end
    end

    -- Always clean up — leaving shader/blend active breaks everything else
    love.graphics.setShader()
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1, 1)
end

-- ─── Fallback draw (no shader) ────────────────────────────────────────────────

-- If the shader failed to load this is called instead, giving a plain
-- bright rectangle so the game is still testable.
function BulletPool:drawFallback()
    love.graphics.setBlendMode("add")
    for i = 1, POOL_SIZE do
        local b = self.pool[i]
        if b.active then
            local alpha = math.min(1.0, b.life / 0.3)
            love.graphics.push()
            love.graphics.translate(b.x, b.y)
            love.graphics.rotate(b.angle)
            love.graphics.setColor(0.0, 0.85, 1.0, alpha)
            love.graphics.rectangle("fill", -BOLT_W/2, -BOLT_H/2, BOLT_W, BOLT_H)
            -- Brighter core strip
            love.graphics.setColor(0.8, 1.0, 1.0, alpha)
            love.graphics.rectangle("fill", -BOLT_W/2, -1, BOLT_W, 2)
            love.graphics.pop()
        end
    end
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1, 1)
end

-- ─── Pool internals ──────────────────────────────────────────────────────────

function BulletPool:_claimSlot()
    local start = self._nextSlot
    for offset = 0, POOL_SIZE - 1 do
        local i = (start + offset - 1) % POOL_SIZE + 1
        if not self.pool[i].active then
            self._nextSlot = (i % POOL_SIZE) + 1
            return self.pool[i]
        end
    end
    return nil
end

function BulletPool:getActive()
    local out = {}
    for i = 1, POOL_SIZE do
        if self.pool[i].active then out[#out + 1] = self.pool[i] end
    end
    return out
end

function BulletPool:destroy(slot)
    slot.active = false
end

return BulletPool