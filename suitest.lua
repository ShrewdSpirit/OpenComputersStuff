
local computer = require('computer')
local keyboard = require('keyboard')
local term = require('term')
local unicode = require('unicode')

local function showmem()
    local t, f = computer.totalMemory(), computer.freeMemory()
    local u = t - f
    print('tm/fm/um: '..tostring(t)..'/'..tostring(f)..'/'..tostring(u))
end

package.loaded.libsui = nil
local sui = require('libsui')
ui = sui.UI
gfx = sui.GFX
swm = ui.init()

if swm then
    term.clear()
    local w1 = ui.Components.Window(true, 'Window 1', 3, 3, 50, 30)
    swm:add(w1)

    w1:add(ui.Components.Label('test Label', 1, 1, 50, 1))
    local btnR = ui.Components.Button('test Button (reset progress)', 1, 3, 50, 2)
    w1:add(btnR)
    local tgl = ui.Components.Toggle('test toggle (horizontal progress)', 1, 5, 50, 1)
    w1:add(tgl)
    local p = ui.Components.Progress(1, 7, 50, 20, 'hor')
    w1:add(p)

    local w2 = ui.Components.Window(true, 'Window 2', 1, 1, 20, 10)
    swm:add(w2)

    local btnAddWin = ui.Components.Button('Add A Window', 1, 49, 10, 2)
    swm:add(btnAddWin)

    w1:bringToFront()

    local wctr = 0

    swm:eventHandler(function (c, e)
        if c:type() == 'Button' then
            if c:compare(btnR) then
                p:progress(0)
            elseif c:compare(btnAddWin) then
                swm:add(ui.Components.Window(true, 'Window '..tostring(wctr), wctr, 1, 20, 10))
                wctr = wctr + 1
            else
                c:style().background = math.random(1,100000)
            end
        end
        if c:type() == 'Progress' then
            if c:compare(p) then
                if e[1] == 'scroll' then
                    v = tonumber(e[5])
                    c:progress((v == 1 and c:progress() + 0.01 or c:progress() - 0.01))
                end
            end
        end
        if c:type() == 'Toggle' then
            if c:compare(tgl) then
                if c:active() then
                    p:direction('ver')
                    c:text('test toggle (vertical progress)')
                else
                    p:direction('hor')
                    c:text('test toggle (horizontal progress)')
                end
            end
        end
    end)

    local e = nil
    repeat --event loop
        e = swm:process()
    until e[1] == 'key_up' and e[4] == keyboard.keys.q
    showmem()
end
