-- src/systems/statemanager.lua
-- A minimal state machine.
-- Each "state" is a Lua table with some or all of these methods:
--   :enter()   called once when the state becomes active
--   :exit()    called once before the state is replaced
--   :update(dt)
--   :draw()
--   :keypressed / :keyreleased / :mousepressed / :mousereleased

local StateManager = {}
StateManager.__index = StateManager

-- Internal: the currently active state table
StateManager._current = nil

-- Switch immediately to a new state (no stack — suitable for our scope)
function StateManager:switch(newState)
    -- Let the outgoing state clean up after itself
    if self._current and self._current.exit then
        self._current:exit()
    end

    self._current = newState

    -- Give the incoming state a chance to initialise
    if self._current and self._current.enter then
        self._current:enter()
    end
end

-- ─── Forward all Love2D callbacks to the active state ────────────────────────

function StateManager:update(dt)
    if self._current and self._current.update then
        self._current:update(dt)
    end
end

function StateManager:draw()
    if self._current and self._current.draw then
        self._current:draw()
    end
end

function StateManager:keypressed(key, scancode, isrepeat)
    if self._current and self._current.keypressed then
        self._current:keypressed(key, scancode, isrepeat)
    end
end

function StateManager:keyreleased(key, scancode)
    if self._current and self._current.keyreleased then
        self._current:keyreleased(key, scancode)
    end
end

function StateManager:mousepressed(x, y, button, istouch)
    if self._current and self._current.mousepressed then
        self._current:mousepressed(x, y, button, istouch)
    end
end

function StateManager:mousereleased(x, y, button, istouch)
    if self._current and self._current.mousereleased then
        self._current:mousereleased(x, y, button, istouch)
    end
end

return StateManager
