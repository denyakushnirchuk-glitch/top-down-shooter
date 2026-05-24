-- src/systems/camera.lua
-- A 2D camera that translates world-space coordinates into screen-space.
--
-- How it works:
--   love.graphics.translate(-cam.x, -cam.y) shifts the entire canvas so
--   that whatever world point the camera is centred on appears at (0,0),
--   and then a second translate moves that to the middle of the screen.
--
-- Usage:
--   Camera:attach()          call before drawing world-space objects
--   Camera:detach()          call after — restores the default transform
--   Camera:follow(entity)    call in update() to track a target
--   Camera:toWorld(sx, sy)   convert screen coords → world coords

local Camera = {}
Camera.__index = Camera

local SW = love.graphics and love.graphics.getWidth()  or 1280
local SH = love.graphics and love.graphics.getHeight() or 720

-- Camera position is the WORLD point shown at the centre of the screen.
Camera.x        = 0
Camera.y        = 0
Camera.scale    = 1
Camera.smoothing = 6

-- ─── Core transform ──────────────────────────────────────────────────────────

-- Call before drawing anything that lives in world space.
function Camera:attach()
    love.graphics.push()
    love.graphics.translate(SW / 2, SH / 2)
    love.graphics.scale(self.scale)
    love.graphics.translate(-self.x, -self.y)
end

-- Call after all world-space drawing. Anything drawn after detach()
-- is in screen space (HUD, debug overlays, etc.).
function Camera:detach()
    love.graphics.pop()
end

-- ─── Following ───────────────────────────────────────────────────────────────

-- Smoothly move the camera toward the target entity each frame.
-- target must have .x and .y fields.
function Camera:follow(target, dt)
    local speed = self.smoothing * dt
    -- Linear interpolation: current + (desired - current) * speed
    self.x = self.x + (target.x - self.x) * speed
    self.y = self.y + (target.y - self.y) * speed
end

-- Snap the camera instantly to a position (useful on state enter)
function Camera:snap(x, y)
    self.x = x
    self.y = y
end

-- ─── Coordinate conversion ───────────────────────────────────────────────────

-- Convert a screen-space point (e.g. mouse cursor) into world-space.
-- You MUST do this before comparing mouse position to entity positions.
function Camera:toWorld(sx, sy)
    local wx = (sx - SW / 2) / self.scale + self.x
    local wy = (sy - SH / 2) / self.scale + self.y
    return wx, wy
end

return Camera
