
local keyboard = require 'keyboard'
package.loaded.libsgfx = nil
local gfx = require 'libsgfx'
package.loaded.libsui = nil
local sui = require 'libsui'

local d = gfx.Driver()
local c = gfx.Context(d)
d:activeDisplayType('screen')
local wm = sui.init(c)

if wm then
    local window1 = sui.Components.Window('test!', 1, 1, 20, 10, true, false)
    wm:add(window1)
    window1:add(sui.Components.Button('asd', 1, 1, 1000, 1000))

    wm:eventHandler(function(c,e)
        if c:text() == 'asd' then
            wm:add(sui.Components.Window(tostring(math.random(1,100)), 10, 10, 15, 10))
        end
    end)

    -- event loop
    local e
    repeat
        e = wm:process(nil)
    until e[1] == 'key_up' and e[4] == keyboard.keys.q
end
