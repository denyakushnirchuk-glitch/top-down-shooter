-- conf.lua
-- Love2D reads this file BEFORE main.lua.
-- Use it to configure the window, modules, and identity.

function love.conf(t)
    t.identity    = "top_down_shooter"
    t.version     = "11.5"
    t.console     = false

    -- Window
    t.window.title        = "Top-Down Shooter"
    t.window.width        = 1280
    t.window.height       = 720
    t.window.resizable    = false
    t.window.vsync        = 1
    t.window.msaa         = 4

    -- Disable modules we don't need (keeps startup fast and memory clean)
    t.modules.joystick  = false
    t.modules.video     = false
    t.modules.touch     = false
end
