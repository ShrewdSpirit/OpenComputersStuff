
-- GFX Lib By ShrewdSpirit
-- A graphics library
-- MIT License
-- version 0.1

-- Features:
--      - Multiple screen support
--      - Functions for drawing some primitive types
--      - Color stack
--      - Full ComputerCraft monitor support

-- TODO:
--      - being able to automatically map colors. so monitors support screen colors

-- BUGS:
--      - you tell me!

------------------------------------------------------
-- Module imports
occomponent = require 'component'
unicode = require'unicode'
------------------------------------------------------
-- Namespaces
GFX = {}
GFX.Util = {}
------------------------------------------------------
-- Utility functions
-- Checks if char is a unicode code or an ascii char
-- if you pass a char to it ('D' or whatever), it returns the same thing you've passed
-- if you pass a number or a string number, it returns its unicode char
GFX.Util.checkUnicodeChar = (char) ->
    if type(char) == 'number'
        char = unicode.char(char)
    elseif type(char) == 'string'
        char = char\sub 1, 1
    char
------------------------------------------------------
-- Colors
GFX.MColors = { -- monitor supported colors
    Black: 0x8000
    Blue: 0x800
    Green: 0x2000
    Red: 0x4000
    Cyan: 0x200
    Purple: 0x400
    Lime: 0x20
    Pink: 0x40
    Yellow: 0x10
    White: 0x1
    Orange: 0x2
    Magenta: 0x4
    LightBlue: 0x8
    Gray: 0x80
    LightGray: 0x100
    Brown: 0x1000
}
GFX.SColors = { -- screen supported colors
    Black: 0x000000
    Blue: 0x3366CC
    Green: 0x57A64E
    Red: 0xCC4C4C
    Cyan: 0x4C99B2
    Purple: 0xB266E5
    Lime: 0x7FCC19
    Pink: 0xF2B2CC
    Yellow: 0xDEDE6C
    White: 0xF0F0F0
    Orange: 0xF2B233
    Magenta: 0xE57FD8
    LightBlue: 0x99B2F2
    Gray: 0x4C4C4C
    LightGray: 0x999999
    Brown: 0x7F664C
}
GFX.Colors = monitor: GFX.MColors, m: GFX.MColors, screen: GFX.SColors, s: GFX.SColors
------------------------------------------------------
-- Graphics driver used for detecting/working with gpus, screens and monitors
class GFX.Driver
    new: =>
        @props = {
            gpu: nil -- the gpu being used
            displays: {} -- display proxies
            activeDisplay: nil -- current display
        }
        @flush!
    --------------------------------------
    -- gets or sets current gpu being used by driver
    gpu: (gpuproxy) =>
        return @props.gpu unless gpuproxy
        return nil unless occomponent.type(gpuproxy.address) == 'gpu'
        @props.gpu = gpuproxy
    --------------------------------------
    -- sets or gets the active display
    activeDisplay: (displayID) =>
        return @props.activeDisplay unless displayID
        if displayID >= 1 and displayID <= #@displays!
            @props.activeDisplay = @display displayID
            @gpu!.bind(@display(displayID).address) if @displayType! == 'screen'
    --------------------------------------
    -- sets the active display type (a screen or a monitor)
    setActiveDisplayType: (type) =>
        return false unless type
        if type == 'monitor' or type == 'screen'
            for i,p in ipairs @displays!
                if p.type == type
                    @activeDisplay i
                    return true
        false
    --------------------------------------
    -- gets the display
    display: (displayID) => @props.displays[displayID]
    --------------------------------------
    -- returns a table of available displays (OpenComputers screens and ComputerCraft monitors)
    displays: => @props.displays
    --------------------------------------
    -- returns active display type
    displayType: => @activeDisplay!.type
    --------------------------------------
    -- sets or gets the resolution of active display
    resolution: (width, height) =>
        @checkComponentAvailability!
        unless width and height
            w, h = 0, 0
            w, h = @activeDisplay!.getSize! if @displayType! == 'monitor'
            w, h = @gpu!.getResolution! if @displayType! == 'screen'
            return w, h
        return @gpu!.setResolution width, height if @displayType! == 'screen'
        return false, "Monitors doesn't support changing resolution"
    --------------------------------------
    -- sets or gets the color of active display
    color: (bg, fg) =>
        @checkComponentAvailability!
        if bg and fg
            if @displayType! == 'monitor'
                @activeDisplay!.setBackgroundColor bg
                @activeDisplay!.setTextColor fg
            elseif @displayType! == 'screen'
                bg = @gpu!.setBackground bg, false
                fg = @gpu!.setForeground fg, false
                return bg, fg
        else
            return false, "You cannot obtain current color from a monitor" if @displayType! == 'monitor'
            return @gpu!.getBackground!, @gpu!.getForeground!
    --------------------------------------
    -- plots a character at given position
    plot: (x, y, char) =>
        @checkComponentAvailability!
        char = GFX.Util.checkUnicodeChar char
        if @displayType! == 'monitor'
            @activeDisplay!.setCursorPos x, y
            @activeDisplay!.write char
        elseif @displayType! == 'screen'
            @gpu!.set x, y, char, false
    --------------------------------------
    -- writes a string at given position
    set: (x, y, str, vertical) =>
        @checkComponentAvailability!
        if @displayType! == 'screen'
            @gpu!.set x, y, str, vertical
        elseif @displayType! == 'monitor'
            unless vertical
                @activeDisplay!.setCursorPos x, y
                @activeDisplay!.write str
            else
                for i=1, #str
                    @activeDisplay!.setCursorPos x, (i - 1) + y
                    @activeDisplay!.write str\sub(i, i)
    --------------------------------------
    -- fills a rectangle with given coordinates
    fill: (x, y, w, h, char) =>
        @checkComponentAvailability!
        char = GFX.Util.checkUnicodeChar char
        if @displayType! == 'screen'
            @gpu!.fill x, y, w, h, char
        elseif @displayType! == 'monitor'
            line = ''
            for i=1, w do line ..= char
            for i=y, y + h
                @activeDisplay!.setCursorPos x, i
                @activeDisplay!.write line
    --------------------------------------
    -- flushes the displays informations
    -- this should be called when a gpu,screen or monitor has been removed, added or resized
    -- stat is the event (run dmesg and try adding or removing screens,monitors)
    -- if stat is nil, driver will be reinitialized
    flush: (stat) =>
        assert occomponent.isAvailable('gpu'), 'No GPU was found.'
        assert occomponent.isAvailable('screen') or occomponent.isAvailable('monitor'), 'No screen or monitor was found.'
        if stat
            if stat[1] == 'component_removed'
                if stat[3] == 'monitor' or stat[3] == 'screen'
                    -- remove the component from displays
                    found = false
                    for i, display in ipairs @displays!
                        if @proxy(i).address == occomponent.proxy(stat[2]).address
                            found = i
                            break
                    if found then table.remove @displays!, found
            elseif stat[1] == 'component_added'
                if stat[3] == 'monitor' or stat[3] == 'screen'
                    table.insert @displays!, stat[2]
        else
            @gpu occomponent.getPrimary('gpu') -- get primary gpu
            -- get list of screens and monitors if available
            for address,type in occomponent.list()
                table.insert @displays!, occomponent.proxy(address) if type == 'monitor' or type == 'screen'
            @activeDisplay 1
    --------------------------------------
    -- checks if theres a gpu and an active display
    checkComponentAvailability: =>
        assert @gpu!, 'No GPU has been bound. Flush the driver.'
        assert @activeDisplay!, 'No active display was found.'
    --------------------------------------
------------------------------------------------------
-- Graphics context used for drawing stuff on screen
class GFX.Context
    new: (driver) =>
        @props = {
            driver: nil
            colorStack: {}
        }
        @driver driver
        displayType = @driver!\displayType!
        @firstColor GFX.Colors[displayType].Red, GFX.Colors[displayType].White
    --------------------------------------
    -- sets or gets current driver being used
    driver: (driver) =>
        return @props.driver unless driver
        @props.driver = driver
    --------------------------------------
    -- gets or sets the first color in color stack. this color cannot be popped out of stack
    firstColor: (bg, fg) =>
        return @props.colorStack[1].bg, @props.colorStack[1].fg unless bg and fg
        @props.colorStack[1] = bg: bg, fg: fg
        @driver!\color bg, fg
    --------------------------------------
    -- pushes a color into color stack
    pushColor: (bg, fg) =>
        bg = @props.colorStack[#@props.colorStack].bg unless bg
        fg = @props.colorStack[#@props.colorStack].fg unless fg
        table.insert @props.colorStack, bg: bg,fg: fg
        @driver!\color bg, fg
    --------------------------------------
    -- Pops 'times' colors from stack and returns them as a table:
    -- { {bg: color, fg: color}, { ... }, ... }
    -- If 'times' is bigger than size of color stack or is zero,
    --      the color stack will be cleared and all colors will be returned as a table
    popColor: (times=1) =>
        poppedColors = {}
        cslen=->#@props.colorStack -- returns the length of the color stack
        times = cslen! - 1 if times >= cslen! or times == 0 -- calculate maximum times that colors can be poped from stack
        for i=1, times
            if #@props.colorStack > 1 -- dunno whats this for!
                last = @props.colorStack[cslen!]
                oldbg, oldfg = last.bg, last.fg
                table.remove @props.colorStack, cslen! -- remove the shit
                last = @props.colorStack[cslen!] -- get the last remaining color
                newbg, newfg = last.bg, last.fg
                @driver!\color newbg, newfg
                table.insert poppedColors, {oldbg, oldfg, newbg, newfg} -- this will be returned
            else table.insert poppedColors, {@props.colorStack[1].bg, @props.colorStack[1].fg} -- dunno why this is here :-? find a reason for me
        poppedColors
    --------------------------------------
    -- plots a character/pixel at given position
    plot: (x, y, char=' ') =>
        @driver!\plot x, y, char
    --------------------------------------
    -- draws a line
    drawLine: (x0, y0, x1, y1, fillChar=' ') =>
        dx = math.abs x1 - x0
        sx = x0 < x1 and 1 or -1
        dy = math.abs y1 - y0
        sy = y0 < y1 and 1 or -1
        err = (dx > dy and dx or -dy) / 2
        e2 = 0
        while true
            @plot x0, y0, fillChar
            break if x0 == x1 and y0 == y1
            e2 = err
            if e2 > -dx
                err -= dy
                x0 += sx
            if e2 < dy
                err += dx
                y0 += sy
    --------------------------------------
    -- draws a horizontal or vertical line (faster than drawLine)
    drawStaticLine: (x, y, len, vertical=false, fillChar=' ') =>
        fillChar = GFX.Util.checkUnicodeChar fillChar
        str = ''
        for i=1, len do str ..= fillChar
        @driver!\set x, y, str, isVertical
    --------------------------------------
    -- Draws a text with given position and size. wrap wraps the text to new line if height > 1
    -- clip will trim the parts of text that are out of given height and width
    -- if fill then it will draw a box with given coordinates
    -- if hasFilledColor then it will pop a color from color stack
    --      this is useful when you want a different color for the box and another color for the text
    --      first pushed color will be used for text and second color will be applied to box
    drawText: (text, x, y, w=0, h=0, valign='center', halign='center', wrap=false, clip=false, fill=false, hasFilledColor=false, fillChar=' ') =>
        if fill
            @drawBox x, y, w, h, fillChar
            @popColor! if hasFilledColor
        lines = {} -- each line will be put as a index in this table
        if wrap
            token = (s) -> -- tokenize
                tokens = {}
                table.insert tokens, word for word in s\gmatch '%S+'
                tokens
            spaceleft = w
            line = {}
            for _, word in ipairs token(text)
                if word\len! + 1 > spaceleft
                    table.insert lines, table.concat(line, ' ')
                    line = {}
                    table.insert line, word
                    spaceleft = w - word\len! + 1
                else
                    table.insert line, word
                    spaceleft -= word\len! + 1
            table.insert lines, table.concat(line, ' ')
        -- split lines (reaching \n will put next line as a new index in lines table)
        else
            tmptext = ''
            for i = 1, text\len!
                c = text\sub i, i
                if c == '\n'
                    table.insert lines, tmptext
                    tmptext = ''
                else tmptext ..= c
            table.insert lines, tmptext
        if clip
            tmplines = {}
            for lineN, lineT in ipairs lines
                if lineN - 1 < h
                    tmptext = ''
                    for i = 1, lineT\len!
                        if i - 1 < w then tmptext ..= lineT\sub i, i
                        else break
                    table.insert tmplines, tmptext
                else break
            lines = tmplines
        if valign != 'top'
            linesL = #lines
            if linesL < h
                padding = valign == 'center' and (h - linesL) / 2 or h - linesL
                table.insert lines, i, '' for i = 1, padding
        halign_draw_text = false -- horizontal align is a bit different. it draws each line separatedly to make it nicer! if you wanna see what happens when using a single draw, just edit these lines a bit!
        if halign != 'left'
            halign_draw_text = true
            for lineN, lineT in ipairs lines
                lineL = lineT\len!
                padding = 0
                if lineL < w
                    padding = halign == 'center' and (w - lineL) / 2 or w - lineL
                @driver!\set x + padding, y + (lineN - 1), lineT, false
        unless halign_draw_text then for i, line in ipairs lines
            @driver!\set x, y + (i - 1), line, false
    --------------------------------------
    -- draws a box
    drawBox: (x, y, w, h, fillChar=' ') =>
        @driver!\fill x, y, w, h, fillChar
    --------------------------------------
    -- draws a border!
    -- borderSurrounding should be a table of these values:
    -- {topleft char,topcenter char,topright char,centerright char,bottomright char,bottomcenter char,bottomleft char,centerleft char}
    drawBorder: (x, y, w, h, borderSurrounding, invertUpDownBorders=false, ignoreTopBottomBorders=false) =>unless borderSurrounding or type(borderSurrounding) == 'table'
        borderSurrounding = {88,88,88,88,88,88,88,88} -- default thing
        if #borderSurrounding < 8 then for i = #borderSurrounding, 8 do table.insert borderSurrounding, 88 -- fill in the remaining space!
        tl,tc,tr = borderSurrounding[1], borderSurrounding[2], borderSurrounding[3]
        cl,cr = borderSurrounding[8], borderSurrounding[4]
        bl,bc,br = borderSurrounding[7], borderSurrounding[6], borderSurrounding[5]
        if invertTopBottomBorders
            l,c,r = tl,tc,tr
            tl,tc,tr = bl,bc,br
            bl,bc,br = l,c,r
        unless ignoreTopBottomBorders
            @plot x, y, tl
            @drawStaticLine x + 1, y, w - 2, false, tc
            @plot x + w - 1, y, tr
        lbx, lby, lbl = x, y + 1, h - 2
        rbx, rby, rbl = x + w - 1, y + 1, h - 2
        if ignoreTopBottomBorders
            lby, lbl = y, h
            rby, rbl = y, h
        @drawStaticLine lbx, lby, lbl, true, cl
        @drawStaticLine rbx, rby, rbl, true, cr
        unless ignoreTopBottomBorders
            @plot x, y + h - 1, bl
            @drawStaticLine x + 1, y + h - 1, w - 2, false, bc
            @plot x + w - 1, y + h - 1, br
    --------------------------------------
    -- clear
    clear: =>
        w, h = @driver!\resolution!
        @drawBox 1, 1, w, h
    --------------------------------------
------------------------------------------------------
-- Module returns
GFX
------------------------------------------------------
