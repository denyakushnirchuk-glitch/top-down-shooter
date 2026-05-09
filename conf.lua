-- conf.lua
-- Love2D reads this file BEFORE main.lua.
-- Use it to configure the window, modules, and identity.

function love.conf(t)
    t.identity    = "top_down_shooter"  -- save folder name
    t.version     = "11.5"              -- target Love2D version
    t.console     = false               -- set true on Windows to see print() in terminal

    -- Window
    t.window.title        = "Top-Down Shooter"
    t.window.width        = 1280
    t.window.height       = 720
    t.window.resizable    = false
    t.window.vsync        = 1           -- 1 = enabled (caps to monitor refresh rate)
    t.window.msaa         = 4           -- anti-aliasing samples (0 = off)

    -- Disable modules we don't need (keeps startup fast and memory clean)
    t.modules.joystick  = false
    t.modules.video     = false
    t.modules.touch     = false
end
