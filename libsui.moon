
-- ShrewdUI By ShrewdSpirit
-- A GUI (Graphical User Interface) library for OpenOS
-- MIT License
-- Version 0.1


-- TODO:
--      draggable windows
--      add,remove,sendToBack,bringToFront use firstFocusableChild so there's always a focused component in wm or any other container

-- BUGS:
--      closing a window which is not focused, will freeze the wm. I think its because focusedC will be set to nil (nothing is focused and never will be focused!)
--      wm will bring the windows with odd zorders to front (while adding new ones) so odd zindex will be brought to front

-- NOTE:
--      Everything is fucked up. Rewrite needed. WindowManager shouldn't exist ...


------------------------------------------------------
-- Namespaces
UI = {} -- UI namespace
UI.Components = {} -- Components (window, button, etc)
Util = {} -- Utility namespace
GFX = {} -- Graphics namespace (draw shapes, text, etc)
------------------------------------------------------
-- OpenOS modules
occomp = require'component'
ocevent = require'event'
ocfs = require'filesystem'
ocserialization = require'serialization'
unicode = require'unicode'
------------------------------------------------------
-- Custom modules
package.loaded.json = nil
json = require'json'
package.loaded.libsgfx = nil
gfx = require'libsgfx'
------------------------------------------------------
-- GVars!
local ocgpu
compcounter = 0 --component counter. used for assigning IDs to components
------------------------------------------------------
-- Utility functions
-- copies a table (recursive or not) and returns the copied table
Util.tblcpy = (tab, recursive) ->
    shallowcopy = (orig) ->
        orig_type = type orig
        local copy
        if orig_type == 'table'
            copy = {}
            for orig_key, orig_value in pairs orig
                copy[orig_key] = orig_value
        else -- number, string, boolean, etc
            copy = orig
        copy
    deepcopy = (orig) ->
        orig_type = type orig
        local copy
        if orig_type == 'table'
            copy = {}
            for orig_key, orig_value in next, orig, nil
                copy[deepcopy orig_key] = deepcopy orig_value
            setmetatable(copy, deepcopy(getmetatable(orig)))
        else -- number, string, boolean, etc
            copy = orig
        copy
    if recursive then return deepcopy(tab)
    else return shallowcopy(tab)
------------------------------------------------------
-- Checks if given positions are inside given coordinates
-- putting iy instead of Y causes iy be nil :/ ftw
Util.intersect = (x, y, w, h, ix, Y) =>
    return true if ix >= x and ix < x + w and Y >= y and Y < y + h
    false
------------------------------------------------------
-- Style class
class UI.Style
    new: (style) =>
        @style = {}
        @loadStyle style
    loadStyle: (style) =>
        -- default style thing. I should put it somewhere else!
        default_style = [[{
                "WindowManager": {
                    "background": "$n:0x000033"
                },
                "Window": {
                    "background": "$n:0x0000ff",
                    "hasborder": true,
                    "borderchars": "$t:9485,9473,9489,9474,9497,9473,9493,9474",
                    "bordercolor": "$n:0xffffff",
                    "titleborderchars": "$t:9485,9473,9489,9474,9509,9473,9501,9474",
                    "textbgcolor": "$n:0x0000ff",
                    "textfgcolor": "$n:0xdddddd",
                    "textpadding": 2,
                    "titlecolor": "$n:0x0000ff",
                    "titleheight": 3,
                    "titlevalign": "$s:center",
                    "titlehalign": "$s:left",
                    "hasnfc": true,
                    "nfbgc": "$n:0x555555",
                    "nffg": "$n:0xaaaaaa",
                    "titleclickbg": "$n:0xff0000",
                    "titleclickfg": "$n:0xffffff",
                    "closeicon": "$n:10005"
                },
                "Box": {
                    "background": false,
                    "hasborder": true,
                    "borderchars": "$t:9556,9552,9559,9553,9565,9552,9562,9553"
                },
                "Label": {
                    "background": "$n:0xffffff",
                    "textcolor": "$n:0x000000"
                },
                "Button": {
                    "background": "$n:0x00ff00",
                    "textcolor": "$n:0x000000",
                    "clicksleep": 0.1,
                    "clickedbackground": "$n:0xff0000",
                    "clickedtextcolor": "$n:0xffffff",
                    "textvalign": "$s:center",
                    "texthalign": "$s:center",
                    "textpadding": 1,
                    "hasborder": true,
                    "borderchars": "$t:9556,9552,9559,9553,9565,9552,9562,9553"
                },
                "Toggle": {
                    "background": "$n:0x00ff00",
                    "textcolor": "$n:0x000000",
                    "clicksleep": 0.1,
                    "clickedbackground": "$n:0xff0000",
                    "clickedtextcolor": "$n:0xffffff",
                    "activebackground": "$n:0xff00ff",
                    "activetextcolor": "$n:0x000000",
                    "textvalign": "$s:center",
                    "texthalign": "$s:center",
                    "textpadding": 1,
                    "hasborder": true,
                    "borderchars": "$t:9556,9552,9559,9553,9565,9552,9562,9553"
                },
                "Progress": {
                    "background": "$n:0x00ff00",
                    "textcolor": "$n:0x000000",
                    "prgbackground": "$n:0x00ff00",
                    "prgtextcolor": "$n:0x0000ff",
                    "emptychar": "$c: ",
                    "prgchar": "$n:9552"
                }
            }]]
        jsonstr = '' -- this is the whole string that's gonna be passed to json decoder and also it will be returned
        if style == 'default'
            jsonstr = default_style 
        else -- If style is a file, it will read from the file else it should be a string
            -- and that string will be parsed as style
            if ocfs.exists style
                f = io.open style, 'r'
                if f
                    jsonstr = f:read '*all' -- haven't tested this. dunno if it works on oc
                    f:close!
                    return false unless jsonstr
            elseif type(style) == 'string'
                jsonstr = style
        if #jsonstr > 0
            @style = json\decode jsonstr -- decode the shit
            -- Parse the json table
            for c,t in pairs(@style) do if type(t) == 'table' then for p,v in pairs(t)
                if type(v) == 'string' and v\len() > 3 and v\sub(1, 1) == '$' and v\sub(3, 3) == ':' -- hmm? it checks for value being a string and starts with $X:val
                    cmd = v\sub(2, 2) -- cmd is that X in "$X:val"!
                    tmpstr = '' -- the value
                    for i = 4, v\len()
                        if cmd == 'c' --its a character value
                            tmpstr = v\sub(i, i)
                            @style[c][p] = tmpstr
                            break
                        elseif cmd == 's' or cmd == 'n' or cmd == 't' -- its not a character value
                            tmpstr ..= v\sub(i, i)
                    @style[c][p] = tmpstr if cmd == 's' --its a string value
                    @style[c][p] = tonumber(tmpstr) if cmd == 'n' --its a number value
                    if cmd == 't' --its table (indexed table not key,value table!)
                        tmptbl = ocserialization.unserialize("{#{tmpstr}}") -- thank you Sangar for this magically useful function!
                        for i,v in ipairs tmptbl do if tonumber(v) then tmptbl[i] = tonumber(v) -- iterate it ...
                        @style[c][p] = tmptbl
        jsonstr
    -- Gets or sets the property in loaded style
    prop: (prop, val) =>
        return @style[prop] unless val
        @style[prop] = val
    -- Gets or sets the given component's property in loaded style
    componentStyleProp: (component, prop, val) =>
        return @style[component][prop] unless val
        @style[component][prop] = val
    -- Gets or sets the component style. copies whole component style so changes wont affect the style itself
    componentStyle: (component, style) =>
        return Util.tblcpy @style[component] unless style
        @style[component] = Util.tblcpy style
------------------------------------------------------
-- Component base class. all other components should inherit from this class, even the custom components, else you'll fall in trouble
class UI.Component
    new: (type, x, y, w, h, text='') =>
        @props = {
            parent: nil, weight: 1
            text: text, type: type --type: string. the name of class
            x: x, y: y, w: w, h: h -- these are used for rendering the component
            cx: x, cy: y, cw: w, ch: h --constant coordinates used for getting the first position of component set by user or whoever else!
            zorder: 0, zindex: 0 --zorder: index in parent's children, zindex: component's children index
            style: {}, focused: false, focusable: false
            visible: true, id: compcounter
            forceReceiveEvent: false,
        }
        @children = {}
        compcounter += 1 -- increase the component counter!
        @style UI.DefaultStyle -- set the default style
    prop: (prop, val) =>
        return @props[prop] unless val
        @props[prop] = val
    --private properties. used for inherited stuff
    pprop: (prop, c, val) =>
        return @props[prop][c] unless val
        @props[prop][c] = val
    parent: (parent) =>
        return @props.parent unless parent
        @props.parent = parent
    size: (w, h) =>
        return @props.cw, @props.ch unless w and h
        @props.w = w if w
        @props.h = h if h
        @props.cw, @props.ch = @props.w, @props.h
    pos: (x, y) =>
        return @props.cx, @props.cy unless x and y
        @props.x = x if x
        @props.y = y if y
        @props.cx, @props.cy = @props.x, @props.y
    weight: (weight) =>
        return @props.weight unless weight
        @props.weight = weight
    text: (text) =>
        if text then @props.text = text
        else @props.text
    style: (style) =>
        return @props.style unless style
        @props.style = style\componentStyle(@type!)
    type: (type) =>
        return @props.type unless type
        @props.type = type
    focused: (state) =>
        return @props.focused if state == nil
        if @props.parent then for i,c in ipairs @props.parent.children
            c.props.focused = false
        @props.focused = state
    visible: (state) =>
        return @props.visible if state == nil
        @props.visible = state
    compare: (component) =>
        return true if @props.id == component.props.id
        false
    intersect: (x, y) =>
        return true if x >= @props.x and x < @props.x + @props.w and y >= @props.y and y < @props.y + @props.h
        false
    add: (component) =>
        table.insert @children, component
        component\parent self
        component.props.zorder = @props.zindex
        @props.zindex += 1
        -- set prev focused item to false
        for i,c in ipairs @children
            c\focused false if c.props.focusable and c\focused!
        component\focused true if component.props.focusable
    remove: (component) =>
        @sortChildren!
        for i,c in ipairs @children
            if component\compare c
                table.remove @children, component.props.zorder + 1 -- remove the component at that index!
                component.props.zorder = 0
                @props.zindex -= 1
                component\focused false if component\focused!
                @sortChildren! -- sort'em all again
                @focuseFirstFocusableChild(@props.zindex) if @props.zindex > 0
                break
    bringToFront: =>
        @parent!\sortChildren!
        parentChilds = @parent!.children
        bringOne = @props.zorder
        oldOne = @props.zorder
        bringElement = self
        for _,w in ipairs parentChilds
            if bringOne < w.props.zorder and not @compare(w)
                bringOne = w.props.zorder
                bringElement = w
        @props.zorder = bringOne
        bringElement.props.zorder = oldOne
        @parent!\focuseFirstFocusableChild bringOne
        @parent!\sortChildren!
    sendToBack: =>
        @parent!\sortChildren!
        parentChilds = @parent!.children
        bringOne = @props.zorder
        willMove = {}
        for _,w in ipairs parentChilds
            if bringOne >= w.props.zorder and not @compare(w)
                table.insert willMove, w
        for _,w in ipairs willMove
            w.props.zorder += 1
        focuseFirstFocusableChild willMove[1].props.zorder
        @props.zorder = 0
        @parent!\sortChildren!
    -- focuses on first focusable children
    focuseFirstFocusableChild: (startingZIndex) =>
        -- starts from last component and finds first focusable component. returns nil if nothing was found
        startingZIndex = #@children unless startingZIndex
        for i=startingZIndex, 1, -1
            if @children[i].props.focusable and not @children[i]\focused! then return @children[i]
        return nil
    sortChildren: =>
        sort = (a, b) -> a.props.zorder < b.props.zorder
        table.sort @children, sort
    processChildren: =>
        @sortChildren!
        for i, component in ipairs(@children)
            component\draw! if component\visible!
    -- callbacks
    reposition: =>
    draw: =>
    onEvent: (e) =>
        UI.WindowManager\eventHandler e, self
------------------------------------------------------
-- Components
class UI.Components.WindowManager extends UI.Component
    new: (maxResX, maxResY, resX, resY) =>
        super 'WindowManager', 1, 1, resX, resY
        @props.WindowManager = maxResX: maxResX, maxResY: maxResY, eventHandler: nil
        @size resX, resY
    -- this function sets or calls the event handler set
    -- if you pass a function to it, it will set the event handler
    -- an event table will be passed to this function from other components to trigger the handler callback
    eventHandler: (stuff, c) =>
        if type(stuff) == 'function' then @props.WindowManager.eventHandler = stuff
        elseif type(stuff) == 'table' then if type(@props.WindowManager.eventHandler) == 'function' then @props.WindowManager.eventHandler(c, stuff)
    size: (w, h) =>
        return @props.w, @props.h unless w and h
        w = 1 if w < 1
        w = @props.WindowManager.maxResX if w > @props.WindowManager.maxResX
        h = 1 if h < 1
        h = @props.WindowManager.maxResY if h > @props.WindowManager.maxResY
        @props.w = w if w
        @props.h = h if h
        ocgpu.setResolution @props.w, @props.h
    maxSize: => @props.WindowManager.maxResX, @props.WindowManager.maxResY
    process: =>
        @sortChildren!
        tevt = table.pack ocevent.pull(0.1)
        -- get focused component
        local focusedC
        for i,c in ipairs @children do if c\focused!
            focusedC = c
            break
        -- trigger event on focused component if it was a touch or scroll event
        if tevt[1] == 'key_down' or tevt[1] == 'scroll' or tevt[1] == 'key_up' or tevt[1] == 'touch' or tevt[1] == 'drag' or tevt[1] == 'drop' -- touch event should be taken care of
            if focusedC
                if tevt[1] != 'touch' and tevt[1] != 'drag' and tevt[1] != 'drop'
                    focusedC\onEvent(tevt)
                elseif focusedC\intersect tonumber(tevt[3]), tonumber(tevt[4])
                    focusedC\onEvent(tevt)
                else -- user has clicked somewhere out of focused component, if user has clicked on a child component, focusedC
                    -- will be set to that component and both new and old focused components will swap their focuse state
                    for i=#@children, 1, -1
                        unless focusedC\compare @children[i]
                            if @children[i]\intersect tonumber(tevt[3]), tonumber(tevt[4])
                                focusedC\focused false
                                focusedC = @children[i]
                                focusedC\focused true
                                focusedC\onEvent(tevt)
                                focusedC\bringToFront!
                                break
            -- trigger event for components that are forced to receive the event
            for j, cj in ipairs @children
                if cj.props.forceReceiveEvent and cj\intersect(tonumber(tevt[3]), tonumber(tevt[4])) then cj\onEvent(tevt)
        @draw!
        tevt
    draw: =>
        if @visible!
            GFX.pushColor @style!.background, @style!.textcolor
            GFX.drawBox @props.x, @props.y, @props.w, @props.h
            GFX.popColor!
            @processChildren!
------------------------------------------------------
class UI.Components.Window extends UI.Component
    new: (hasTitleBar=true, text='', x=0, y=0, w=0, h=0, hasCloseButton=true) =>
        super 'Window', x, y, w, h, text
        @props.Window = {
            hasTitleBar: hasTitleBar, movable: hasTitleBar, hasCloseButton: hasCloseButton
        }
        @props.focusable = true
    hasCloseButton: (state) =>
        return @props.Window.hasCloseButton if state == nil
        @props.Window.hasCloseButton = state
    hasTitleBar: (state) =>
        return @props.Window.hasTitleBar if state == nil
        @props.Window.hasTitleBar = state
        @movable state
    movable: (state) =>
        return @props.Window.movable if state == nil
        @props.Window.movable = state
    reposition: =>
        mx, my = @pos!
        mw, mh = @size!
        if @hasTitleBar! then my += @style!.titleheight - 1
        for i, c in ipairs @children-- some shitty calculations that I don't know what the hell is going on, they just work so let them be there!
            x, y = c\pos!
            w, h = c\size!
            x = 1 if x < 1
            y = 1 if y < 1
            x += mx
            y += my
            w = (mx + mw) - x - 1 if x + w >= mx + mw
            th = (if @hasTitleBar! then return (@style!.titleheight - 1) else return 0)
            if y + h >= (my + mh) - th then h = (my + mh) - y - 1 - th
            if x >= mx + mw - 1 or x <= mx or y >= my + mh - 1 or y <= my then c\visible false 
            else
                c\visible true
                c.props.x = x
                c.props.y = y
                c.props.w = w
                c.props.h = h
    draw: =>
        background, bordercolor, titlecolor, textbgcolor, textfgcolor = @style!.background,  @style!.bordercolor, @style!.titlecolor, @style!.textbgcolor, @style!.textfgcolor
        unless @focused! and @style!.hasnfc
            bg, fg = @style!.nfbgc, @style!.nffg
            background, bordercolor, titlecolor, textbgcolor, textfgcolor = bg, fg, bg, bg, fg
        GFX.pushColor background, bordercolor
        x, y, w, h = @props.x, @props.y, @props.w, @props.h
        GFX.drawBox x, y, w, h
        if @style!.hasborder
            GFX.drawBorder x, y, w, h, @style!.borderchars, false, false
        @reposition!
        @processChildren!
        if @hasTitleBar!
            GFX.pushColor titlecolor, nil
            GFX.drawBox x, y, w, @style!.titleheight
            if @style!.hasborder
                invertTopBottomBorders = false
                invertTopBottomBorders = true if @style!.titleheight <= 1
                GFX.pushColor nil, bordercolor
                GFX.drawBorder x, y, w, @style!.titleheight, @style!.titleborderchars, invertTopBottomBorders
                GFX.popColor!
            GFX.pushColor textbgcolor, textfgcolor
            textpadding = @style!.textpadding
            GFX.drawText @text!, x + textpadding, y + (math.ceil(@style!.titleheight / 2) - 1),
                w - textpadding * 2 - (textpadding + 2), math.ceil(@style!.titleheight / 2),
                @style!.titlevalign, @style!.titlehalign, true, true
            GFX.plot (@props.x + @props.w) - (textpadding + 2), y + (math.ceil(@style!.titleheight / 2) - 1), @style!.closeicon if @hasCloseButton!
            GFX.popColor 2
        GFX.popColor!
    onEvent: (e) =>
        --no window dragging for now!
        --if e[1] == 'drag' and @movable! -- check if the window is being dragged
        --    if e[3] >= @props.x and e[3] < @props.x + @props.w and e[4] >= @props.y and e[4] < @props.y + @style!.titleheight - 1
        --        @pos e[3], e[4]
        --        return
        -- touch or scroll event
        if e[1] == 'touch' or e[1] == 'scroll'
            -- close click check
            if e[1] == 'touch' and tonumber(e[5]) == 0 and @hasTitleBar! and @hasCloseButton!
                textpadding = @style!.textpadding
                x, y, w, h = (@props.x + @props.w) - (textpadding + 2), @props.y + (math.ceil(@style!.titleheight / 2) - 1), 1, 1
                mx, my = tonumber(e[3]), tonumber(e[4])
                if mx >= x and mx < x + w and my >= y and my < y + h
                    GFX.pushColor @style!.titleclickbg, @style!.titleclickfg
                    GFX.plot (@props.x + @props.w) - (textpadding + 2), @props.y + (math.ceil(@style!.titleheight / 2) - 1), @style!.closeicon
                    GFX.popColor!
                    os.sleep(0.3)
                    @focused true
                    @parent!\remove self
                    return
            for i=#@children, 1, -1
                if @children[i]\intersect tonumber(e[3]), tonumber(e[4])
                    @children[i]\onEvent e
                    break
        else --keydown, keyup. these will be triggered on focused element
            for i=#@children, 1, -1 do if @children[i]\focused!
                    @children[i]\onEvent e
                    break
        super e
------------------------------------------------------
class UI.Components.Tabview extends UI.Component
------------------------------------------------------
class UI.Components.Box extends UI.Component
    new: (bg, fg, x=0, y=0, w=0, h=0, fillChar=' ') =>
        super 'Box', x, y, w, h
        @props.Box = bg: bg, fg: fg, fillChar: fillChar
    color: (bg, fg) =>
        return @props.Box.bg, @props.Box.fg unless bg and fg
        @props.Box.bg = bg
        @props.Box.fg = fg
    fillChar: (char) =>
        return @props.Box.fillChar unless char
        @props.Box.fillChar = char
    draw: =>
        GFX.pushColor @props.Box.bg, @props.Box.fg
        GFX.drawBox @props.x, @props.y, @props.w, @props.h, @fillChar!
        GFX.drawBorder @props.x, @props.y, @props.w, @props.h, @style!.borderchars if @style!.hasborder
        GFX.popColor!
------------------------------------------------------
class UI.Components.Label extends UI.Component
    new: (text='', x=0, y=0, w=0, h=0, valign='center', halign='center', wrap=false, clip=false) =>
        super 'Label', x, y, w, h, text
        @props.Label = valign: valign, halign: halign, wrap: wrap, clip: clip
    align: (valign, halign) =>
        return @props.Label.valign, @props.Label.halign if valign and halign
        valign = @props.Label.valign unless valign
        halign = @props.Label.halign unless halign
        @props.Label.valign = valign
        @props.Label.halign = halign
    wrap: (state) =>
        return @props.Label.wrap if state == nil
        @props.Label.wrap = state
    clip: (state) =>
        return @props.Label.clip if state == nil
        @props.Label.clip = state
    draw: =>
        GFX.pushColor @style!.background, @style!.textcolor
        GFX.drawText @text!, @props.x, @props.y, @props.w, @props.h, @props.Label.valign,
            @props.Label.halign, @props.Label.wrap, @props.Label.clip, @style!.background
        GFX.popColor!
------------------------------------------------------
class UI.Components.Button extends UI.Component
    new: (text='', x=0, y=0, w=0, h=0) =>
        super 'Button', x, y, w, h, text
        @props.Button = isClicked: false
    draw: =>
        bg, fg = @style!.background, @style!.textcolor
        bg, fg = @style!.clickedbackground, @style!.clickedtextcolor if @props.Button.isClicked
        padding = 0
        padding = @style!.textpadding if @style!.hasborder
        itbb = @props.h == 1 and true or false
        GFX.pushColor bg, fg
        GFX.drawBorder @props.x, @props.y, @props.w, @props.h, @style!.borderchars, false, itbb if @style!.hasborder
        GFX.drawText @text!, @props.x + padding, @props.y, @props.w - padding * 2, @props.h, @style!.textvalign,
            @style!.texthalign, true, true, @style!.background
        GFX.popColor!
    onEvent: (e) =>
        if e[1] == 'touch' and e[5] == 0
            @props.Button.isClicked = true
            @draw!
            os.sleep @style!.clicksleep
            @props.Button.isClicked = false
            @draw!
        super e
------------------------------------------------------
class UI.Components.Toggle extends UI.Component
    new: (text='', x=0, y=0, w=0, h=0) =>
        super 'Toggle', x, y, w, h, text
        @props.Toggle = isClicked: false, isActive: false
    active: (state) =>
        return @props.Toggle.isActive if state == nil
        @props.Toggle.isActive = state
    draw: =>
        bg, fg = @style!.background, @style!.textcolor
        bg, fg = @style!.clickedbackground, @style!.clickedtextcolor if @props.Toggle.isClicked
        bg, fg = @style!.activebackground, @style!.activetextcolor if @active! and not @props.Toggle.isClicked
        padding = 0
        padding = @style!.textpadding if @style!.hasborder
        itbb = @props.h == 1 and true or false
        GFX.pushColor bg, fg
        GFX.drawBorder @props.x, @props.y, @props.w, @props.h, @style!.borderchars, false, itbb if @style!.hasborder
        GFX.drawText @text!, @props.x + padding, @props.y, @props.w - padding * 2, @props.h, @style!.textvalign,
            @style!.texthalign, true, true, @style!.background
        GFX.popColor!
    onEvent: (e) =>
        if e[1] == 'touch' and e[5] == 0
            @props.Toggle.isClicked = true
            @draw!
            os.sleep @style!.clicksleep
            @props.Toggle.isClicked = false
            @active(not @active!)
            @draw!
        super e
------------------------------------------------------
class UI.Components.List extends UI.Component
------------------------------------------------------
class UI.Components.Spinner extends UI.Component
------------------------------------------------------
class UI.Components.Checkbox extends UI.Component
------------------------------------------------------
class UI.Components.Radiobox extends UI.Component
------------------------------------------------------
class UI.Components.Editbox extends UI.Component
------------------------------------------------------
class UI.Components.Progress extends UI.Component
    new: (x=0, y=0, w=0, h=0, direction='hor') =>
        super 'Progress', x, y, w, h
        @props.Progress = current: 0, direction: direction, inverted: inverted
    direction: (direction) =>
        return @props.Progress.direction unless direction
        @props.Progress.direction = direction if direction == 'ver' or direction == 'hor'
    inverted: (state) =>
        return @props.Progress.inverted if state == nil
        @props.Progress.inverted = state
    progress: (progress, min=0, max=1) =>
        return @props.Progress.current unless progress
        progress = min if progress < min
        progress = max if progress > max
        --Y = (progress - min) / (max - min) * 100 --Y = (X-A)/(B-A) * (D-C) + C  [we have x between a,b want y between c,d]
        @props.Progress.current = progress-- / 100
    draw: =>
        GFX.pushColor @style!.background, @style!.textcolor
        GFX.drawBox @props.x, @props.y, @props.w, @props.h, @style!.emptychar
        GFX.pushColor @style!.prgbackground, @style!.prgtextcolor
        sx, sy, sw, sh = @props.x, @props.y, @props.w, @props.h
        if @style!.hasborder
            sx += 1
            sy += 1
            sw -= 2
            sh -= 2
        if @progress! > 0
            if @direction! == 'hor'
                GFX.drawBox sx, sy, math.floor(sw * @progress!), sh, @style!.prgchar
            else
                progress = math.floor(sh * @progress!)
                GFX.drawBox sx, (sy + (sh - progress)), sw, progress, @style!.prgchar
        GFX.drawBorder @props.x, @props.y, @props.w, @props.h, @style!.borderchars if @style!.hasborder
        GFX.popColor 2
------------------------------------------------------
-- Initialization function
UI.init = (resX, resY) ->
    return false unless occomp.isAvailable'gpu' or occomp.isAvailable'screen'
    ocgpu = occomp.gpu
    --return false if ocgpu.getDepth! < 4
    mrx, mry = ocgpu.maxResolution!
    crx, cry = ocgpu.getResolution!
    resX = crx unless resX
    resY = cry unless resY
    resX = mrx if resX < 1 or resX > mrx
    resY = mry if resY < 1 or resY > mry
    GFX.firstColor GFX.Colors.Black, GFX.Colors.White
    UI.DefaultStyle = UI.Style 'default'
    UI.WindowManager = UI.Components.WindowManager mrx, mry, resX, resY
    UI.WindowManager
------------------------------------------------------
-- Module returns
{UI: UI, GFX: GFX}
------------------------------------------------------
