-- main.lua
-- Entry point. This file stays thin on purpose — its only job is to
-- load the global tools, then hand control to the state machine.

-- ─── Global Utilities ────────────────────────────────────────────────────────

-- require() uses dots as path separators, not slashes.
-- Everything under src/ is accessible as "src.folder.file"
Camera  = require("src.systems.camera")
Input   = require("src.systems.input")
States  = require("src.systems.statemanager")

-- ─── Love2D Callbacks ────────────────────────────────────────────────────────

function love.load()
    -- Nearest-neighbour filtering keeps pixel art crisp when scaled
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Seed the random number generator
    math.randomseed(os.time())

    -- Boot into the gameplay state straight away.
    -- Later you'll swap this for a "menu" state.
    States:switch(require("src.states.game"))
end

function love.update(dt)
    -- Cap dt so a lag spike doesn't teleport entities across the map
    dt = math.min(dt, 0.05)

    Input:update()          -- snapshot keyboard/mouse this frame
    States:update(dt)       -- forward dt into the active state
end

function love.draw()
    States:draw()
end

-- ─── Input pass-through callbacks ────────────────────────────────────────────
-- Love2D fires these once per event; we forward them to the active state
-- so states can react to single-press actions (not just held keys).

function love.keypressed(key, scancode, isrepeat)
    if key == "escape" then love.event.quit() end
    States:keypressed(key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
    States:keyreleased(key, scancode)
end

function love.mousepressed(x, y, button, istouch)
    States:mousepressed(x, y, button, istouch)
end

function love.mousereleased(x, y, button, istouch)
    States:mousereleased(x, y, button, istouch)
end
