-- src/systems/pulsarbackground.lua
-- Reusable wrapper around pulsar_shader.glsl.
-- Used by the menu, game-over, and game states.

local PulsarBG = {}
PulsarBG.__index = PulsarBG

function PulsarBG.new()
    local self  = setmetatable({}, PulsarBG)
    self.time   = 0
    self.w, self.h = love.graphics.getDimensions()

    local ok, result = pcall(love.graphics.newShader, "src/systems/pulsar_shader.glsl")
    if ok then
        self.shader = result
    else
        self.shader = nil
        print("[PulsarBG] Shader load failed: " .. tostring(result))
    end
    return self
end

function PulsarBG:update(dt)
    self.time = self.time + dt
end

-- Draw the fullscreen background.
--   ox, oy: world-space camera position for parallax (pass nothing / 0,0 for menus)
function PulsarBG:draw(ox, oy)
    ox = ox or 0
    oy = oy or 0

    if not self.shader then
        -- Fallback: solid deep-space colour
        love.graphics.setColor(0, 0.005, 0.018, 1)
        love.graphics.rectangle("fill", 0, 0, self.w, self.h)
        love.graphics.setColor(1, 1, 1, 1)
        return
    end

    love.graphics.setShader(self.shader)
    self.shader:send("time",        self.time)
    self.shader:send("resolution",  { self.w, self.h })
    self.shader:send("worldOffset", { ox / self.w, oy / self.h })
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, self.w, self.h)
    love.graphics.setShader()
end

return PulsarBG
