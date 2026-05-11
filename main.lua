-- main.lua
-- Entry point. This file stays thin on purpose — its only job is to
-- load the global tools, then hand control to the state machine.

-- ─── Global Utilities ────────────────────────────────────────────────────────

Camera  = require("src.systems.camera")
Input   = require("src.systems.input")
States  = require("src.systems.statemanager")

-- Shared result bag; game.lua writes kills here before switching to gameover.
LastGameResult = { kills = 0 }

-- ─── Love2D Callbacks ────────────────────────────────────────────────────────

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    math.randomseed(os.time())
    States:switch(require("src.states.menu"))
end

function love.update(dt)
    dt = math.min(dt, 0.05)
    Input:update()
    States:update(dt)
end

function love.draw()
    States:draw()
end

-- ─── Input pass-through ───────────────────────────────────────────────────────
-- ESC is handled per-state: menu/gameover quit; game returns to menu.

function love.keypressed(key, scancode, isrepeat)
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
