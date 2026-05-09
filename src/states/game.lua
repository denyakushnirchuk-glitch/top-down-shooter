-- src/states/game.lua
-- Main gameplay state. Owns all gameplay objects and orchestrates
-- the update → camera → draw pipeline each frame.

local Player     = require("src.entities.player")
local BulletPool = require("src.systems.bulletpool")

local Game = {}
Game.__index = Game

-- ─── State lifecycle ─────────────────────────────────────────────────────────

function Game:enter()
    self.player  = Player:new(0, 0)
    self.bullets = BulletPool:new()

    -- Wire the player's fire callback directly to the pool.
    -- The player calls onFire(x, y, angle); the pool spawns the bolt.
    -- Using a closure keeps the player decoupled from the pool's internals.
    self.player.onFire = function(x, y, angle)
        self.bullets:fire(x, y, angle)
    end

    Camera:snap(self.player.x, self.player.y)

    love.mouse.setVisible(false)
    self.showDebug = true
end

function Game:exit()
    love.mouse.setVisible(true)
end

-- ─── Update ──────────────────────────────────────────────────────────────────

function Game:update(dt)
    self.player:update(dt)
    self.bullets:update(dt)
    Camera:follow(self.player, dt)
end

-- ─── Draw ────────────────────────────────────────────────────────────────────

function Game:draw()
    -- ── World space ───────────────────────────────────────────────────────
    Camera:attach()

        self:_drawGrid()
        -- Use shader draw if available, plain fallback if shader failed to compile
        if self.bullets._shader then
            self.bullets:draw()
        else
            self.bullets:drawFallback()
        end
        self.player:draw()

    Camera:detach()

    -- ── Screen space (HUD) ────────────────────────────────────────────────
    if self.showDebug then
        self.player:drawDebug()
        self:_drawCameraDebug()
        self:_drawBulletDebug()
    end

    self:_drawCrosshair()
end

-- ─── Input callbacks ─────────────────────────────────────────────────────────

function Game:keypressed(key)
    if key == "f1" then
        self.showDebug = not self.showDebug
    end
end

-- ─── Helpers ─────────────────────────────────────────────────────────────────

function Game:_drawGrid()
    local CELL   = 64
    local EXTENT = 2000

    love.graphics.setColor(0.15, 0.15, 0.15, 1)
    for gx = -EXTENT, EXTENT, CELL do
        love.graphics.line(gx, -EXTENT, gx, EXTENT)
    end
    for gy = -EXTENT, EXTENT, CELL do
        love.graphics.line(-EXTENT, gy, EXTENT, gy)
    end

    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    love.graphics.line(-EXTENT, 0, EXTENT, 0)
    love.graphics.line(0, -EXTENT, 0, EXTENT)
end

function Game:_drawCrosshair()
    local mx, my = Input:mousePosition()
    local GAP = 5
    local ARM = 10
    local DOT = 2

    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.line(mx - GAP - ARM, my, mx - GAP, my)
    love.graphics.line(mx + GAP,       my, mx + GAP + ARM, my)
    love.graphics.line(mx, my - GAP - ARM, mx, my - GAP)
    love.graphics.line(mx, my + GAP,       mx, my + GAP + ARM)
    love.graphics.circle("fill", mx, my, DOT)
end

function Game:_drawCameraDebug()
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print(string.format("cam  (%.0f, %.0f)", Camera.x, Camera.y), 10, 80)
end

function Game:_drawBulletDebug()
    local count = 0
    for i = 1, #self.bullets.pool do
        if self.bullets.pool[i].active then count = count + 1 end
    end
    local shaderStatus = self.bullets._shader and "shader:ON" or "shader:FALLBACK"
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print(string.format("bullets  %d / %d   %s",
        count, #self.bullets.pool, shaderStatus), 10, 100)
end

return Game