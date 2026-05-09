-- src/entities/battery.lua
-- A collectable energy pickup scattered around the map.
--
-- ── Visuals ───────────────────────────────────────────────────────────────────
-- Drawn entirely with Love2D primitives — no sprites needed.
-- A hexagonal body (suits a "power cell" look) with an inner glow pulse
-- driven by a simple sine wave on the alpha channel.
--
-- ── Lifecycle ─────────────────────────────────────────────────────────────────
-- Batteries are stored in a plain table in game.lua.
-- On player overlap, battery:collect() is called, which sets active=false
-- and calls the injected onCollect callback (player:addEnergy).
-- Dead batteries are swept from the table in game.lua each frame.

local Battery = {}
Battery.__index = Battery

-- Hexagon geometry — precompute the 6 vertex offsets once
local HEX_VERTS = {}
for i = 0, 5 do
    local a = math.pi / 180 * (60 * i - 30)   -- flat-top hex, starting top-right
    HEX_VERTS[i * 2 + 1] = math.cos(a)        -- X
    HEX_VERTS[i * 2 + 2] = math.sin(a)        -- Y
end

local RADIUS        = 14    -- hex outer radius px
local COLLECT_DIST  = 28    -- pickup trigger distance (player centre → battery centre)
local ENERGY_VALUE  = 40    -- energy restored on pickup

-- ─── Constructor ─────────────────────────────────────────────────────────────

function Battery:new(x, y)
    local b = setmetatable({}, Battery)

    b.x          = x or 0
    b.y          = y or 0
    b.active     = true
    b.radius     = COLLECT_DIST   -- exposed for collision check in game.lua
    b.energyVal  = ENERGY_VALUE

    -- Pulse animation: each battery gets a random phase offset so they don't
    -- all pulse in sync, which would look mechanical and cheap
    b._pulseTimer = math.random() * math.pi * 2

    -- Injected by game.lua. Called when player collects this battery.
    -- Signature: onCollect(energyAmount)
    b.onCollect = nil

    return b
end

-- ─── Update ──────────────────────────────────────────────────────────────────

function Battery:update(dt)
    if not self.active then return end
    -- Advance the pulse timer; 1.6 rad/s ≈ one full pulse every ~4 seconds
    self._pulseTimer = self._pulseTimer + dt * 1.6
end

-- ─── Collect ─────────────────────────────────────────────────────────────────

-- Called by game.lua when the player overlaps this battery.
function Battery:collect()
    if not self.active then return end
    self.active = false
    if self.onCollect then
        self.onCollect(self.energyVal)
    end
end

-- ─── Draw ────────────────────────────────────────────────────────────────────

-- Call inside Camera:attach() — battery lives in world space.
function Battery:draw()
    if not self.active then return end

    -- Pulse: sine wave on alpha, range 0.45–1.0
    local pulse = 0.45 + 0.55 * (0.5 + 0.5 * math.sin(self._pulseTimer))

    love.graphics.push()
    love.graphics.translate(self.x, self.y)

    -- ── Outer glow ring ───────────────────────────────────────────────────
    -- A slightly larger transparent circle behind the hex gives a soft halo
    love.graphics.setBlendMode("add")
    love.graphics.setColor(0.1, 0.6, 1.0, pulse * 0.35)
    love.graphics.circle("fill", 0, 0, RADIUS + 6)
    love.graphics.setBlendMode("alpha")

    -- ── Hex body ──────────────────────────────────────────────────────────
    -- Build the polygon vertex list scaled to RADIUS
    local verts = {}
    for i = 0, 5 do
        verts[i * 2 + 1] = HEX_VERTS[i * 2 + 1] * RADIUS
        verts[i * 2 + 2] = HEX_VERTS[i * 2 + 2] * RADIUS
    end

    -- Dark fill
    love.graphics.setColor(0.05, 0.12, 0.25, 0.92)
    love.graphics.polygon("fill", verts)

    -- Glowing border — pulses with the sine wave
    love.graphics.setColor(0.1, 0.65, 1.0, pulse)
    love.graphics.setLineWidth(2)
    love.graphics.polygon("line", verts)

    -- ── Inner core: a small bright circle ─────────────────────────────────
    love.graphics.setBlendMode("add")
    love.graphics.setColor(0.4, 0.85, 1.0, pulse * 0.9)
    love.graphics.circle("fill", 0, 0, RADIUS * 0.38)
    love.graphics.setBlendMode("alpha")

    -- ── Lightning bolt icon (two lines forming a ⚡ shape) ─────────────────
    -- Simple chevron that reads as "energy" without needing a sprite
    love.graphics.setColor(0.85, 1.0, 1.0, pulse)
    love.graphics.setLineWidth(2)
    love.graphics.line( 2, -6,  -2,  0)   -- top-right to centre
    love.graphics.line(-2,  0,   3,  1)   -- centre to mid-right
    love.graphics.line( 3,  1,  -1,  6)   -- mid-right to bottom-left

    love.graphics.setLineWidth(1)   -- reset line width
    love.graphics.pop()
end

return Battery