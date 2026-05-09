-- src/states/game.lua
-- Main gameplay state.

local Player    = require("src.entities.player")
local BulletPool= require("src.systems.bulletpool")
local Battery   = require("src.entities.battery")
local Drone     = require("src.entities.drone")
local Collision = require("src.systems.collision")
local HUD       = require("src.ui.hud")

local Game = {}
Game.__index = Game

-- ─── Constants ───────────────────────────────────────────────────────────────

-- Drones spawn on a circle this far from the player so they're
-- always off-screen when they appear (screen is ~640 px half-diagonal).
local SPAWN_RADIUS = 750

-- ─── State lifecycle ─────────────────────────────────────────────────────────

function Game:enter()
    self.player   = Player:new(0, 0)
    self.bullets  = BulletPool:new()
    self.hud      = HUD:new()
    self.batteries = {}
    self.drones    = {}
    self.particles = {}   -- death burst shards, outlive their drone

    self.player.onFire = function(x, y, angle)
        self.bullets:fire(x, y, angle)
    end

    -- Battery spawner
    self._batteryTimer    = 5
    self._batteryInterval = {10, 15}
    self._batteryMax      = 4
    self._batterySpawnPool = {
        { 150,  80 }, {-180,  60 }, { 300, -120 },
        {-260, 200 }, { 100, -250}, {-80,   300 },
        { 420,  50 }, {-350, -180}, { 200,  350 },
        {-400,  120}, { 320,  280}, {-150, -320 },
    }

    -- Drone spawner — aggressive from the start, escalates over time
    self._droneTimer    = 2        -- first drone after 2 s
    self._droneInterval = {1.8, 3.2}  -- 2–3 s between spawns (much faster)
    self._droneMax      = 16          -- higher cap so waves feel dense
    self._killCount     = 0           -- total drones destroyed this run

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
    self.hud:update(dt, self.player)

    self:_updateBatterySpawner(dt)
    self:_updateDroneSpawner(dt)
    self:_updateDrones(dt)
    self:_updateParticles(dt)

    -- Batteries: update + pickup check
    for i = #self.batteries, 1, -1 do
        local bat = self.batteries[i]
        bat:update(dt)
        if bat.active then
            local dx = self.player.x - bat.x
            local dy = self.player.y - bat.y
            if math.sqrt(dx*dx + dy*dy) < bat.radius then
                bat:collect()
            end
        end
        if not bat.active then table.remove(self.batteries, i) end
    end

    -- Collision: bullets vs drones, drones vs player
    Collision.check(self.bullets, self.drones, self.player)

    -- Sweep dead drones; migrate their particles to the game particle list
    for i = #self.drones, 1, -1 do
        local d = self.drones[i]
        if not d.active then
            self._killCount = self._killCount + 1
            for _, p in ipairs(d.particles) do
                self.particles[#self.particles + 1] = p
            end
            table.remove(self.drones, i)
        end
    end

    Camera:follow(self.player, dt)
end

-- ─── Draw ────────────────────────────────────────────────────────────────────

function Game:draw()
    Camera:attach()

        self:_drawGrid()

        for _, bat in ipairs(self.batteries) do bat:draw() end
        for _, d   in ipairs(self.drones)    do d:draw()   end

        -- Particles drawn in world space with additive blend
        for _, p in ipairs(self.particles) do
            Drone.drawParticle(p)
        end
        love.graphics.setBlendMode("alpha")

        if self.bullets._shader then
            self.bullets:draw()
        else
            self.bullets:drawFallback()
        end

        self.player:draw()

    Camera:detach()

    self.hud:draw(self.player, self._killCount)

    if self.showDebug then
        self.player:drawDebug()
        self:_drawCameraDebug()
        self:_drawBulletDebug()
    end

    self:_drawCrosshair()
end

-- ─── Input ───────────────────────────────────────────────────────────────────

function Game:keypressed(key)
    if key == "f1" then self.showDebug = not self.showDebug end
end

-- ─── Spawners ────────────────────────────────────────────────────────────────

function Game:_updateDroneSpawner(dt)
    self._droneTimer = self._droneTimer - dt
    if self._droneTimer <= 0 then
        local lo, hi = self._droneInterval[1], self._droneInterval[2]
        self._droneTimer = lo + math.random() * (hi - lo)

        if #self.drones < self._droneMax then
            -- Spawn on a circle around the player at SPAWN_RADIUS distance,
            -- at a random angle so drones arrive from all directions over time
            local angle = math.random() * math.pi * 2
            local sx = self.player.x + math.cos(angle) * SPAWN_RADIUS
            local sy = self.player.y + math.sin(angle) * SPAWN_RADIUS
            self.drones[#self.drones + 1] = Drone:new(sx, sy)
        end
    end
end

function Game:_updateDrones(dt)
    for _, d in ipairs(self.drones) do
        d:update(dt, self.player)
    end
end

function Game:_updateParticles(dt)
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        Drone.updateParticle(p, dt)
        if p.life <= 0 then
            table.remove(self.particles, i)
        end
    end
end

function Game:_updateBatterySpawner(dt)
    self._batteryTimer = self._batteryTimer - dt
    if self._batteryTimer <= 0 then
        local lo, hi = self._batteryInterval[1], self._batteryInterval[2]
        self._batteryTimer = lo + math.random() * (hi - lo)

        if #self.batteries < self._batteryMax then
            local pool   = self._batterySpawnPool
            local start  = math.random(#pool)
            local chosen = nil

            for offset = 0, #pool - 1 do
                local idx = (start + offset - 1) % #pool + 1
                local pt  = pool[idx]
                local occupied = false
                for _, bat in ipairs(self.batteries) do
                    local dx = bat.x - pt[1]
                    local dy = bat.y - pt[2]
                    if math.sqrt(dx*dx + dy*dy) < 60 then
                        occupied = true; break
                    end
                end
                if not occupied then chosen = pt; break end
            end

            if chosen then
                local bat = Battery:new(chosen[1], chosen[2])
                bat.onCollect = function(amount)
                    self.player:addEnergy(amount)
                end
                self.batteries[#self.batteries + 1] = bat
            end
        end
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
    local GAP = 5; local ARM = 10
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.line(mx-GAP-ARM, my, mx-GAP, my)
    love.graphics.line(mx+GAP,     my, mx+GAP+ARM, my)
    love.graphics.line(mx, my-GAP-ARM, mx, my-GAP)
    love.graphics.line(mx, my+GAP,     mx, my+GAP+ARM)
    love.graphics.circle("fill", mx, my, 2)
end

function Game:_drawCameraDebug()
    -- Sits below the 6 player debug lines (6 * 18 = 108 px) + gap
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
    love.graphics.print(string.format("cam  (%.0f, %.0f)", Camera.x, Camera.y), 10, 130)
end

function Game:_drawBulletDebug()
    local count = 0
    for i = 1, #self.bullets.pool do
        if self.bullets.pool[i].active then count = count + 1 end
    end
    local s = self.bullets._shader and "shader:ON" or "shader:FALLBACK"
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
    local lines = {
        string.format("bullets    %d / 128   %s", count, s),
        string.format("batteries  %d / 4   next: %.0f s", #self.batteries, math.max(0, self._batteryTimer)),
        string.format("drones     %d   particles: %d", #self.drones, #self.particles),
        string.format("kills      %d", self._killCount),
    }
    for i, line in ipairs(lines) do
        love.graphics.print(line, 10, 148 + (i - 1) * 18)
    end
end

return Game