-- src/systems/input.lua
-- Wraps Love2D's input functions into a single snapshot taken at the
-- start of each frame. This means every system reads the same input
-- state within one update(), avoiding subtle order-of-update bugs.
--
-- Usage:
--   Input:isDown("w")          → true while W is held
--   Input:mousePosition()      → { x, y } in SCREEN space
--   Input:mouseDown(1)         → true while left mouse button held

local Input = {}
Input.__index = Input

function Input:update()
    -- Mouse position is read fresh each frame
    self._mx, self._my = love.mouse.getPosition()
end

-- ─── Keyboard ────────────────────────────────────────────────────────────────

-- Polling: good for movement (held keys)
function Input:isDown(key)
    return love.keyboard.isDown(key)
end

-- ─── Mouse ───────────────────────────────────────────────────────────────────

-- Returns raw screen-space coordinates.
-- Convert to world space via Camera:toWorld(x, y) when needed.
function Input:mousePosition()
    return self._mx, self._my
end

function Input:mouseDown(button)
    return love.mouse.isDown(button)
end

return Input
