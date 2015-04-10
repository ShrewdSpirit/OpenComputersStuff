
package.loaded.libsgfx = nil
local gfx = require('libsgfx')

local d = gfx.Driver()
d:setActiveDisplayType('monitor')
t = d:displayType()

c = gfx.Context(d)
c:pushColor(gfx.Colors[t].Lime, gfx.Colors[t].White)
c:clear()
c:pushColor(gfx.Colors[t].White, gfx.Colors[t].Red)
c:drawBox(1, 1, 10, 10)
c:drawText('HEY IT works!',30,30)
c:popColor(2)
