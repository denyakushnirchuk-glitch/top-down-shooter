-- src/ui/hud.lua
-- HUD: centre-bottom layout.
--
--   ┌──────────────────────────────────────────────┐
--   │               KILLS: 42                      │  ← kill counter above bars
--   │  HULL ████████████░░░░  ENERGY ███████░░░░░  │  ← two bars side by side
--   └──────────────────────────────────────────────┘
--
-- All positions are computed relative to screen centre-bottom so they stay
-- correct if the window size ever changes.

local HUD = {}
HUD.__index = HUD

-- ─── Layout ──────────────────────────────────────────────────────────────────

local SW = love.graphics.getWidth()
local SH = love.graphics.getHeight()

local BAR_W      = 220    -- width of each bar
local BAR_H      = 14
local BAR_RADIUS = 3
local BAR_GAP    = 20     -- horizontal gap between the two bars
local BOTTOM_PAD = 18     -- distance from screen bottom to bar bottom edge

-- Derived positions (computed once; bars are centred around screen midpoint)
local TOTAL_W    = BAR_W * 2 + BAR_GAP
local LEFT_X     = (SW - TOTAL_W) / 2          -- left bar X
local RIGHT_X    = LEFT_X + BAR_W + BAR_GAP    -- right bar X
local BAR_Y      = SH - BOTTOM_PAD - BAR_H     -- both bars share same Y
local LABEL_Y    = BAR_Y - 15                  -- label row above bars
local KILL_Y     = LABEL_Y - 20               -- kill counter above labels

-- ─── Colours ─────────────────────────────────────────────────────────────────

local COL_BG         = {0.06, 0.06, 0.10, 0.88}

-- HP (hull) — red → orange at low HP
local HP_HIGH        = {0.85, 0.20, 0.12, 1.0}
local HP_LOW         = {1.00, 0.55, 0.05, 1.0}
local HP_BORDER      = {0.55, 0.12, 0.08, 0.9}
local HP_LOW_THRESH  = 0.40

-- Energy — cyan → orange-red when low
local EN_HIGH        = {0.10, 0.75, 1.00, 1.0}
local EN_LOW         = {0.80, 0.25, 0.10, 1.0}
local EN_BORDER      = {0.15, 0.45, 0.75, 0.8}
local EN_LOW_THRESH  = 0.25

local COL_LABEL      = {0.75, 0.85, 1.00, 0.80}
local COL_KILL       = {1.00, 0.90, 0.40, 1.00}

-- ─── Constructor ─────────────────────────────────────────────────────────────

function HUD:new()
    local h = setmetatable({}, HUD)
    h._dispEnergy = 1.0   -- lerped display fractions
    h._dispHp     = 1.0
    return h
end

-- ─── Update ──────────────────────────────────────────────────────────────────

function HUD:update(dt, player)
    local eT = player.energy / player.maxEnergy
    local eS = eT < self._dispEnergy and 14 or 4
    self._dispEnergy = self._dispEnergy + (eT - self._dispEnergy) * eS * dt

    local hT = player.hp / player.maxHp
    local hS = hT < self._dispHp and 12 or 6
    self._dispHp = self._dispHp + (hT - self._dispHp) * hS * dt
end

-- ─── Draw ────────────────────────────────────────────────────────────────────

function HUD:draw(player, kills)
    self:_drawKillCounter(kills or 0)
    self:_drawHpBar(player)
    self:_drawEnergyBar(player)
end

-- ─── Kill counter ────────────────────────────────────────────────────────────

function HUD:_drawKillCounter(kills)
    local text = string.format("KILLS: %d", kills)
    local tw   = love.graphics.getFont():getWidth(text)
    love.graphics.setColor(COL_KILL)
    love.graphics.print(text, SW / 2 - tw / 2, KILL_Y)
end

-- ─── Shared bar helper ───────────────────────────────────────────────────────

local function drawBar(x, frac, colHigh, colLow, lowThresh, borderCol, glowAdd)
    -- Background
    love.graphics.setColor(COL_BG)
    love.graphics.rectangle("fill", x, BAR_Y, BAR_W, BAR_H, BAR_RADIUS)

    local fillW = math.max(0, frac * BAR_W)
    if fillW > 0 then
        local t = math.max(0, (frac - lowThresh) / (1.0 - lowThresh))
        local r = colLow[1] + (colHigh[1] - colLow[1]) * t
        local g = colLow[2] + (colHigh[2] - colLow[2]) * t
        local b = colLow[3] + (colHigh[3] - colLow[3]) * t

        -- Fill
        love.graphics.setColor(r, g, b, 1)
        love.graphics.rectangle("fill", x, BAR_Y, fillW, BAR_H, BAR_RADIUS)

        -- Highlight stripe
        love.graphics.setColor(r + 0.2, g + 0.2, b + 0.2, 0.3)
        love.graphics.rectangle("fill", x + 2, BAR_Y + 2, math.max(0, fillW - 4), 3, 1)

        -- Additive glow when above low threshold
        if glowAdd and frac > lowThresh then
            love.graphics.setBlendMode("add")
            love.graphics.setColor(r * 0.25, g * 0.25, b * 0.25, 0.6)
            love.graphics.rectangle("fill", x, BAR_Y, fillW, BAR_H, BAR_RADIUS)
            love.graphics.setBlendMode("alpha")
        end
    end

    -- Border
    love.graphics.setColor(borderCol)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", x, BAR_Y, BAR_W, BAR_H, BAR_RADIUS)
    love.graphics.setLineWidth(1)
end

-- ─── HP bar ──────────────────────────────────────────────────────────────────

function HUD:_drawHpBar(player)
    local frac = math.max(0, math.min(1, self._dispHp))
    drawBar(LEFT_X, frac, HP_HIGH, HP_LOW, HP_LOW_THRESH, HP_BORDER, false)

    love.graphics.setColor(1, 0.45, 0.35, 0.85)
    love.graphics.print("HULL", LEFT_X, LABEL_Y)

    -- Critical flicker
    if player.hp <= 1 and player.hp > 0 then
        local t = love.timer.getTime()
        if (t % 0.5) < 0.30 then
            love.graphics.setColor(1, 0.15, 0.05, 1)
            love.graphics.print("CRITICAL", LEFT_X + BAR_W - 58, LABEL_Y)
        end
    end
end

-- ─── Energy bar ──────────────────────────────────────────────────────────────

function HUD:_drawEnergyBar(player)
    local frac    = math.max(0, math.min(1, self._dispEnergy))
    local isEmpty = player.energy < player.energyPerShot
    drawBar(RIGHT_X, frac, EN_HIGH, EN_LOW, EN_LOW_THRESH, EN_BORDER, true)

    love.graphics.setColor(COL_LABEL)
    love.graphics.print("ENERGY", RIGHT_X, LABEL_Y)

    -- Empty flicker
    if isEmpty then
        local t = love.timer.getTime()
        if (t % 0.6) < 0.40 then
            love.graphics.setColor(0.95, 0.25, 0.08, 1)
            love.graphics.print("EMPTY", RIGHT_X + BAR_W - 44, LABEL_Y)
        end
    end
end

return HUD