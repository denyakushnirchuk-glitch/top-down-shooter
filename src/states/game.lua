-- src/states/game.lua
-- The main gameplay state.
-- Its job is to own all gameplay objects and orchestrate the three phases
-- of every frame: update → camera → draw.
--
-- Think of this as the "scene" in a game engine. When we add enemies,
-- bullets, and a tilemap, they all get created and updated here.

local Player = require("src.entities.player")

local Game = {}
Game.__index = Game

-- ─── State lifecycle ─────────────────────────────────────────────────────────

function Game:enter()
    -- Spawn the player at the centre of the world
    self.player = Player:new(0, 0)

    -- Snap the camera so it doesn't slide in from (0,0) on the first frame
    Camera:snap(self.player.x, self.player.y)

    -- Hide the OS cursor — we draw our own crosshair instead
    love.mouse.setVisible(false)

    -- Debug overlay toggle (press F1 to flip)
    self.showDebug = true
end

function Game:exit()
    -- Restore the OS cursor when leaving this state
    love.mouse.setVisible(true)
end

-- ─── Update ──────────────────────────────────────────────────────────────────

function Game:update(dt)
    self.player:update(dt)
    Camera:follow(self.player, dt)
end

-- ─── Draw ────────────────────────────────────────────────────────────────────

function Game:draw()
    -- ── World-space rendering ──────────────────────────────────────────────
    Camera:attach()

        -- Background grid so we can see the camera moving
        self:_drawGrid()

        -- Player lives in world space
        self.player:draw()

    Camera:detach()

    -- ── Screen-space rendering (HUD) ───────────────────────────────────────
    if self.showDebug then
        self.player:drawDebug()
        self:_drawCameraDebug()
    end

    -- Crosshair is always drawn last so it sits on top of everything
    self:_drawCrosshair()
end

-- ─── Input callbacks ─────────────────────────────────────────────────────────

function Game:keypressed(key)
    if key == "f1" then
        self.showDebug = not self.showDebug
    end
end

-- ─── Helpers ─────────────────────────────────────────────────────────────────

-- Draws a reference grid in world space so camera movement is visible.
-- Each cell is 64×64 px; lines within ±2000 px of the origin.
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

    -- Bright cross at the world origin so we always know where (0,0) is
    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    love.graphics.line(-EXTENT, 0, EXTENT, 0)
    love.graphics.line(0, -EXTENT, 0, EXTENT)
end

function Game:_drawCameraDebug()
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print(string.format(
        "cam  (%.0f, %.0f)",
        Camera.x, Camera.y
    ), 10, 80)
end

-- Draws a crosshair in screen space at the current mouse position.
-- Called last so it renders on top of everything else.
-- All coordinates here are screen pixels, not world units.
function Game:_drawCrosshair()
    local mx, my = Input:mousePosition()

    local GAP    = 5    -- empty space around the centre dot
    local ARM    = 10   -- length of each crosshair arm
    local DOT    = 2    -- radius of the centre dot

    -- Outer lines: white with slight transparency
    love.graphics.setColor(1, 1, 1, 0.9)
    -- Horizontal arms
    love.graphics.line(mx - GAP - ARM, my, mx - GAP, my)
    love.graphics.line(mx + GAP,       my, mx + GAP + ARM, my)
    -- Vertical arms
    love.graphics.line(mx, my - GAP - ARM, mx, my - GAP)
    love.graphics.line(mx, my + GAP,       mx, my + GAP + ARM)

    -- Centre dot
    love.graphics.circle("fill", mx, my, DOT)
end

return Game