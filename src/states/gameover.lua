-- src/states/gameover.lua
-- Shown when the player's hull reaches 0.
-- Reads LastGameResult.kills (set by game.lua before switching here).

local PulsarBG = require("src.systems.pulsarbackground")

local GameOver = {}
GameOver.__index = GameOver

-- ─── Helpers ──────────────────────────────────────────────────────────────────

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

function GameOver:enter()
    self.bg    = PulsarBG.new()
    self.time  = 0
    self.kills = (LastGameResult and LastGameResult.kills) or 0

    self.fontTitle = love.graphics.newFont(90)
    self.fontScore = love.graphics.newFont(38)
    self.fontSub   = love.graphics.newFont(22)
    self.fontTiny  = love.graphics.newFont(12)

    self.blink        = 0
    self.blinkVisible = true
    self.fadeAlpha    = 1.0      -- fades from black on enter

    love.mouse.setVisible(true)
end

function GameOver:exit() end

-- ─── Update ───────────────────────────────────────────────────────────────────

function GameOver:update(dt)
    self.bg:update(dt)
    self.time = self.time + dt

    -- Fade in from black
    if self.fadeAlpha > 0 then
        self.fadeAlpha = math.max(0, self.fadeAlpha - dt * 1.6)
    end

    self.blink = self.blink + dt
    if self.blink >= 0.58 then
        self.blink        = 0
        self.blinkVisible = not self.blinkVisible
    end
end

-- ─── Draw ─────────────────────────────────────────────────────────────────────

function GameOver:draw()
    local W, H = love.graphics.getDimensions()

    self.bg:draw()

    -- Dark overlay — heavier than the menu to give a sombre feel
    love.graphics.setColor(0, 0, 0.01, 0.58)
    love.graphics.rectangle("fill", 0, 0, W, H)

    -- ── "GAME OVER" title ──────────────────────────────────────────────────
    love.graphics.setFont(self.fontTitle)
    local pulse = 0.82 + 0.18 * math.sin(self.time * 2.1)
    glowPrint("GAME  OVER",
              0, H * 0.19, W,
              1.0 * pulse, 0.14 * pulse, 0.06 * pulse, 20)

    -- ── Decorative separator ───────────────────────────────────────────────
    local lw = 460
    local lx = (W - lw) * 0.5
    local ly = H * 0.41
    love.graphics.setLineWidth(1)
    love.graphics.setColor(0.75, 0.18, 0.08, 0.72)
    love.graphics.line(lx, ly, lx + lw, ly)
    love.graphics.setColor(0.5, 0.1, 0.05, 0.35)
    love.graphics.line(lx - 22, ly + 5, lx + lw + 22, ly + 5)

    -- ── Kill score ─────────────────────────────────────────────────────────
    love.graphics.setFont(self.fontScore)
    glowPrint(string.format("KILLS : %d", self.kills),
              0, H * 0.45, W,
              0.60, 0.82, 1.0, 11)

    -- ── Options prompt ─────────────────────────────────────────────────────
    if self.blinkVisible then
        love.graphics.setFont(self.fontSub)
        love.graphics.setColor(0.50, 0.78, 1.0, 0.92)
        love.graphics.printf(
            "[R] Restart     [M] Menu     [ESC] Quit",
            0, H * 0.62, W, "center")
    end

    -- ── Fade-in black overlay ──────────────────────────────────────────────
    if self.fadeAlpha > 0 then
        love.graphics.setColor(0, 0, 0, self.fadeAlpha)
        love.graphics.rectangle("fill", 0, 0, W, H)
    end

    -- Reset
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

-- ─── Input ────────────────────────────────────────────────────────────────────

function GameOver:keypressed(key)
    if key == "r" then
        States:switch(require("src.states.game"))
    elseif key == "m" then
        States:switch(require("src.states.menu"))
    elseif key == "escape" then
        love.event.quit()
    end
end

function GameOver:keyreleased(key) end
function GameOver:mousepressed(x, y, button) end
function GameOver:mousereleased(x, y, button) end

return GameOver
