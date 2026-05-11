-- src/states/menu.lua
-- Main menu state.  Boots into this state on game start.

local PulsarBG = require("src.systems.pulsarbackground")

local Menu = {}
Menu.__index = Menu

-- ─── Helpers ──────────────────────────────────────────────────────────────────

-- Draw text with a soft multi-pass glow behind it.
local function glowPrint(text, x, y, w, r, g, b, spread)
    spread = spread or 7
    for i = 4, 1, -1 do
        local s = spread * (i / 4.0)
        local a = 0.07 / i
        love.graphics.setColor(r, g, b, a)
        love.graphics.printf(text, x - s, y,     w, "center")
        love.graphics.printf(text, x + s, y,     w, "center")
        love.graphics.printf(text, x,     y - s, w, "center")
        love.graphics.printf(text, x,     y + s, w, "center")
    end
    love.graphics.setColor(r, g, b, 1)
    love.graphics.printf(text, x, y, w, "center")
end

-- ─── State lifecycle ──────────────────────────────────────────────────────────

function Menu:enter()
    self.bg   = PulsarBG.new()
    self.time = 0

    self.fontTitle = love.graphics.newFont(72)
    self.fontSub   = love.graphics.newFont(28)
    self.fontSmall = love.graphics.newFont(16)
    self.fontTiny  = love.graphics.newFont(12)

    self.blink        = 0
    self.blinkVisible = true

    love.mouse.setVisible(true)
end

function Menu:exit() end

-- ─── Update ───────────────────────────────────────────────────────────────────

function Menu:update(dt)
    self.bg:update(dt)
    self.time = self.time + dt

    self.blink = self.blink + dt
    if self.blink >= 0.55 then
        self.blink        = 0
        self.blinkVisible = not self.blinkVisible
    end
end

-- ─── Draw ─────────────────────────────────────────────────────────────────────

function Menu:draw()
    local W, H = love.graphics.getDimensions()

    -- Pulsar background
    self.bg:draw()

    -- Very subtle darkening band behind the text block for readability
    love.graphics.setColor(0, 0, 0, 0.28)
    love.graphics.rectangle("fill", 0, H * 0.22, W, H * 0.60)

    -- ── Title ──────────────────────────────────────────────────────────────
    love.graphics.setFont(self.fontTitle)
    local pulse = 0.88 + 0.12 * math.sin(self.time * 1.9)
    glowPrint("TOP-DOWN SHOOTER",
              0, H * 0.26, W,
              0.18 * pulse, 0.55 * pulse, 1.0, 16)

    -- ── Decorative separator ───────────────────────────────────────────────
    local lw = 420
    local lx = (W - lw) * 0.5
    local ly = H * 0.44
    love.graphics.setLineWidth(1)
    love.graphics.setColor(0.1, 0.5, 1.0, 0.65)
    love.graphics.line(lx, ly, lx + lw, ly)
    love.graphics.setColor(0.0, 0.25, 0.75, 0.30)
    love.graphics.line(lx - 18, ly + 5, lx + lw + 18, ly + 5)

    -- ── "Press Enter" prompt ───────────────────────────────────────────────
    love.graphics.setFont(self.fontSub)
    if self.blinkVisible then
        glowPrint("PRESS  ENTER  TO  START",
                  0, H * 0.50, W,
                  0.55, 0.82, 1.0, 9)
    end

    -- ── Controls hint ──────────────────────────────────────────────────────
    love.graphics.setFont(self.fontSmall)
    love.graphics.setColor(0.38, 0.54, 0.82, 0.90)
    love.graphics.printf(
        "WASD · Move     |     Mouse · Aim     |     LMB · Fire",
        0, H * 0.68, W, "center")

    -- ── Footer credit ──────────────────────────────────────────────────────
    love.graphics.setFont(self.fontTiny)
    love.graphics.setColor(0.22, 0.32, 0.58, 0.70)
    love.graphics.printf("Made with LÖVE", 0, H - 26, W, "center")

    -- Reset graphics state
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

-- ─── Input ────────────────────────────────────────────────────────────────────

function Menu:keypressed(key)
    if key == "return" or key == "space" or key == "kpenter" then
        States:switch(require("src.states.game"))
    elseif key == "escape" then
        love.event.quit()
    end
end

function Menu:keyreleased(key) end

function Menu:mousepressed(x, y, button)
    if button == 1 then
        States:switch(require("src.states.game"))
    end
end

function Menu:mousereleased(x, y, button) end

return Menu
