
local keyboard = require('keyboard')
local event = require('event')
package.loaded.libsgfx = nil
local gfx = require('libsgfx')

local d = gfx.Driver()
d:activeDisplayType('screen') -- set currently active display type (monitor or screen)
c = gfx.Context(d)

local e
local cd = 1 --current display

repeat
    e = table.pack(event.pull(0))
    local stat = d:refresh(e) -- refresh the displays (if anything added or removed)

    local nd = #d:displays() -- num displays

    cd = cd + 1
    if cd > nd then cd = 1 end
    d:activeDisplay(cd) -- set active display (display id)
    local t = d:activeDisplayType() -- get active display type

    rw, rh = d:resolution() -- get the resolution
    local msg = tostring(stat) .. ': ' .. tostring(os.clock()) .. ' - ' .. t .. '#' .. tostring(cd) .. '@' .. tostring(rw) .. ':' .. tostring(rh)

    c:pushColor(0xf0f, 0x00ff00) -- push a color (it will be applied to active display)
    c:clear() -- clear the screen
    c:drawText(msg) -- draw a text @ 1, 1
    c:pushColor(0xfff, nil)
    c:drawBorder(1, 2, 20, 20)
    c:popColor() -- pop the color we've pushed so it resotres any color that was set before
until e[1] == 'key_up' and e[4] == keyboard.keys.q

c:clear() -- clear the shit
