
-- ShrewdUI By ShrewdSpirit
-- A GUI (Graphical User Interface) library for OpenOS
-- MIT License
-- Version 0.1

------------------------------------------------------
-- namespaces
SUI = {}
SUI.Util = {}
SUI.Components = {}
------------------------------------------------------
-- module imports
ocevent = require'event'
ocfs = require'filesystem'
ocserialization = require'serialization'
unicode = require'unicode'
package.loaded.json = nil
json = require'json'
------------------------------------------------------
-- Utility functions
-- copies a table (recursive or not) and returns the copied table
SUI.Util.tblcpy = (tab, recursive) ->
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
SUI.Util.intersect = (x, y, w, h, ix, Y) =>
    return true if ix >= x and ix < x + w and Y >= y and Y < y + h
    false
------------------------------------------------------
-- default style thing. I should put it somewhere else!
default_style = [[{
"WindowManager": {
    "background": "$n:0x00f000",
    "textcolor": "$n:0xffffff"
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
    "closeicon": "$n:10005",
    "closedelay": 0.3
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
-- Style class
class SUI.Style
    new: (style) =>
        @style = {}
        @loadStyle style
    --------------------------------------
    loadStyle: (style) =>
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
    --------------------------------------
    -- Gets or sets the given component's property in loaded style
    componentStyleProp: (component, prop, val) =>
        return @style[component][prop] unless val
        @style[component][prop] = val
    --------------------------------------
    -- Gets or sets the component style. copies whole component style so changes wont affect the style itself
    componentStyle: (component, style) =>
        return SUI.Util.tblcpy @style[component] unless style
        @style[component] = SUI.Util.tblcpy style
    --------------------------------------
------------------------------------------------------
-- Component base class
class SUI.Component
    new: (type, x, y, w, h, text='') =>
        @props = {
            parent: nil, weight: 1
            text: text, type: type -- type: string. the name of class
            x: x, y: y, w: w, h: h -- these are used for rendering the component
            cx: x, cy: y, cw: w, ch: h -- constant coordinates used for getting the first position of component set by user or whoever else!
            zorder: 0, zindex: 0 -- zorder: index in parent's children, zindex: component's children index
            style: {}, visible: true, id: 0
            focused: false, focusable: false, focusedComponent: nil -- focused component is used by containers
            forceReceiveEvent: false,
            -- extra properties used for events
            epx: 0, epy: 0 -- previous pos
        }
        @children = {}
        @style SUI.DefaultStyle -- set the default style
        -- set component id
        @props.id = SUI.WindowManager\cmpid! unless type == 'WindowManager'
    --------------------------------------
    -- gets or sets the parent. parent should be a component itself
    parent: (parent) =>
        return @props.parent unless parent
        @props.parent = parent
    --------------------------------------
    -- gets or sets the size of the component
    size: (w, h) =>
        return @props.cw, @props.ch unless w and h
        @props.w = w if w
        @props.h = h if h
        @props.cw, @props.ch = @props.w, @props.h
    --------------------------------------
    -- gets or sets the position of the component
    pos: (x, y) =>
        return @props.cx, @props.cy unless x and y
        @props.x = x if x
        @props.y = y if y
        @props.cx, @props.cy = @props.x, @props.y
    --------------------------------------
    -- gets or sets the component's weight. its used in automatic positioning layouts
    weight: (weight) =>
        return @props.weight unless weight
        @props.weight = weight
    --------------------------------------
    -- gets or sets the text. its only visible on components with text rendering
    text: (text) =>
        if text then @props.text = text
        else @props.text
    --------------------------------------
    -- gets or sets the component style
    style: (style) =>
        return @props.style unless style
        @props.style = style\componentStyle(@type!)
    --------------------------------------
    -- gets or sets the component's type text
    type: (type) =>
        return @props.type unless type
        @props.type = type
    --------------------------------------
    -- gets or sets the component's focused state. changing the focused state requires focusable property to be enabled
    focused: (state) =>
        return @props.focused if state == nil
        if @focusable!
            if @props.parent then for i,c in ipairs @props.parent.children
                c.props.focused = false
            @props.focused = state
    --------------------------------------
    -- gets or sets the focusable state
    focusable: (state) =>
        return @props.focusable if state == nil
        @props.focusable = state
    --------------------------------------
    -- gets or sets the container's focused component. returns true on assignment, false if no component could be focused
    focusedComponent: (component) =>
        return @props.focusedComponent unless component
        -- unfocuse previous components
        if component\focusable!
            c\focused false for _,c in ipairs @children
            component\focused true
            @props.focusedComponent = component
            return true
        false
    --------------------------------------
    -- gets or sets the component visibility
    visible: (state) =>
        return @props.visible if state == nil
        @props.visible = state
    --------------------------------------
    -- compares this component with given component
    compare: (component) =>
        return true if @props.id == component.props.id
        false
    --------------------------------------
    -- checks if given point is inside component
    intersect: (x, y) =>
        return true if x >= @props.x and x < @props.x + @props.w and y >= @props.y and y < @props.y + @props.h
        false
    --------------------------------------
    -- adds a child to component
    add: (component) =>
        table.insert @children, component
        component\parent self
        component.props.zorder = @props.zindex
        @props.zindex += 1
        @focusedComponent component
    --------------------------------------
    -- removes the matching component from the children
    remove: (component) =>
        @sortChildren!
        for _,c in ipairs @children
            if component\compare c
                table.remove @children, component.props.zorder + 1 -- remove the component at that index!
                component.props.zorder = 0
                component.props.parent = nil
                @props.zindex -= 1
                @sortChildren! -- sort'em all again
                component\focused false
                @props.focusedComponent = nil
                for i,c in ipairs @children do if @focusedComponent @children[@props.zindex - (i - 1)] then break -- focuse on last component
                break
    --------------------------------------
    -- bring the component to front (if it has a parent of course)
    bringToFront: =>
        return false unless @parent!
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
        @parent!\focusedComponent parentChilds[bringOne]
        @parent!\sortChildren!
        true
    --------------------------------------
    -- sends the component to back
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
        @props.zorder = 0
        @parent!\sortChildren!
        for _,c in ipairs parentChilds do if @parent!\focusedComponent c then break -- focuse last focusable component!
    --------------------------------------
    -- sort the container's children
    sortChildren: =>
        sort = (a, b) -> a.props.zorder < b.props.zorder
        table.sort @children, sort
    --------------------------------------
    -- call children's draw function
    processChildren: =>
        @sortChildren!
        for i, component in ipairs(@children)
            component\draw! if component\visible!
    --------------------------------------
    -- reposition callback
    reposition: =>
    --------------------------------------
    -- draw callback
    draw: =>
    --------------------------------------
    -- on event callback. this calls the event handler
    onEvent: (e) =>
        SUI.WindowManager\eventHandler e, self
    --------------------------------------
------------------------------------------------------
class SUI.Components.WindowManager extends SUI.Component
    new: (gctx, w=0, h=0) =>
        super 'WindowManager', 1, 1, w, h
        @props.WindowManager = gfx: gctx, cmpcntr: 0
        @size w, h
    --------------------------------------
    -- gets or sets the graphics context
    gfx: (gctx) =>
        return @props.WindowManager.gfx unless gctx
        @props.WindowManager.gfx = gctx
    --------------------------------------
    -- returns a component id
    cmpid: =>
        @props.WindowManager.cmpcntr += 1
        @props.WindowManager.cmpcntr
    --------------------------------------
    -- sets or calls the event handler callback
    -- if you pass a function to it, it will set the event handler
    -- an event table will be passed to this function from other components to trigger the handler callback
    -- stuff can be a function or event table
    eventHandler: (stuff, component) =>
        if type(stuff) == 'function' then @props.WindowManager.eventHandler = stuff
        elseif type(stuff) == 'table' then if type(@props.WindowManager.eventHandler) == 'function' then @props.WindowManager.eventHandler(component, stuff)
    --------------------------------------
    -- gets or sets window manager size (screen resolution) returns true on successful resolution change
    size: (w, h) =>
        return @props.cw, @props.ch unless w and h
        mw, mh = @gfx!\driver!\maxResolution!
        w = mw if w > mw or w < 1
        h = mh if h > mh or h < 1
        @props.w = w
        @props.h = h
        @props.cw, @props.ch = @props.w, @props.h
        return true if @gfx!\driver!\resolution w, h
        false
    --------------------------------------
    -- the heart of the window manager! this should be called in a loop. it returns an event table
    process: (timeout=0.1) =>
        @sortChildren!
        e = table.pack ocevent.pull(timeout) -- retrieve an event
        if @visible!
            et = e[1] -- event type
            -- trigger event on focused component if it was a touch or scroll event
            if et == 'key_down' or et == 'scroll' or et == 'key_up' or et == 'touch' or et == 'drag' or et == 'drop' or et == 'monitor_touch' -- touch event should be taken care of
                -- get focused component
                focusedC = @focusedComponent!
                if focusedC
                    if et != 'touch' and et != 'drag' and et != 'drop' and et != 'monitor_touch'
                        focusedC\onEvent(e)
                    elseif focusedC\intersect(tonumber(e[3]), tonumber(e[4])) and (et == 'touch' or et == 'drag' or et == 'drop' or et == 'monitor_touch')
                        focusedC\onEvent(e)
                    else -- user has clicked somewhere out of focused component, if user has clicked on a child component, focusedC
                        -- will be set to that component and both new and old focused components will swap their focuse state
                        for i=#@children, 1, -1
                            unless focusedC\compare @children[i]
                                if @children[i]\intersect tonumber(e[3]), tonumber(e[4])
                                    focusedC\focused false
                                    focusedC = @children[i]
                                    focusedC\focused true
                                    focusedC\bringToFront!
                                    focusedC\onEvent(e)
                                    break
                else -- nothing is focused, so focuse on something!
                    if et == 'touch' or et == 'drag' or et == 'drop' or et == 'monitor_touch'
                        for i=#@children, 1, -1 do if @children[i]\focusable!
                            @children[i]\focused true
                            @children[i]\bringToFront!
                            @children[i]\onEvent(e)
                            break
                -- trigger event for components that are forced to receive the event
                for j, cj in ipairs @children
                    if cj.props.forceReceiveEvent and cj\intersect(tonumber(e[3]), tonumber(e[4])) then cj\onEvent(e)
            @draw!
        e -- return the event. so caller can see what the hell has happened!
    --------------------------------------
    draw: =>
        SUI.WindowManager\gfx!\pushColor @style!.background, @style!.textcolor
        SUI.WindowManager\gfx!\drawBox @props.x, @props.y, @props.w, @props.h
        SUI.WindowManager\gfx!\popColor!
        @processChildren!
    --------------------------------------
------------------------------------------------------
class SUI.Components.Window extends SUI.Component
    new: (text='', x=1, y=1, w=1, h=1, hasTitleBar=true, hasCloseButton=true) =>
        super 'Window', x, y, w, h, text
        @props.Window = {
            hasTitleBar: hasTitleBar, movable: hasTitleBar, hasCloseButton: hasCloseButton
            beignDragged: false
        }
        @props.focusable = true -- a window should be focusable, else it won't receive any events
    --------------------------------------
    -- name says everything!
    hasCloseButton: (state) =>
        return @props.Window.hasCloseButton if state == nil
        @props.Window.hasCloseButton = state
    --------------------------------------
    -- name says everything!
    hasTitleBar: (state) =>
        return @props.Window.hasTitleBar if state == nil
        @props.Window.hasTitleBar = state
        @movable state
    --------------------------------------
    -- name says everything!
    movable: (state) =>
        return @props.Window.movable if state == nil
        @props.Window.movable = state
    --------------------------------------
    -- reposition the children, so they will be drawn in window content area
    reposition: =>
        mx, my = @pos!
        mw, mh = @size!
        if @hasTitleBar! then my += @style!.titleheight - 1
        for i, c in ipairs @children -- some shitty calculations that I don't know what the hell is going on, they just work so let them be there!
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
    --------------------------------------
    draw: =>
        background, bordercolor, titlecolor, textbgcolor, textfgcolor = @style!.background,  @style!.bordercolor, @style!.titlecolor, @style!.textbgcolor, @style!.textfgcolor
        unless @focused! and @style!.hasnfc -- change window color if its not focused and supports notfocusecolor
            bg, fg = @style!.nfbgc, @style!.nffg
            background, bordercolor, titlecolor, textbgcolor, textfgcolor = bg, fg, bg, bg, fg
        SUI.WindowManager\gfx!\pushColor background, bordercolor
        x, y, w, h = @props.x, @props.y, @props.w, @props.h
        SUI.WindowManager\gfx!\drawBox x, y, w, h -- draw window box
        if @style!.hasborder -- window border
            SUI.WindowManager\gfx!\drawBorder x, y, w, h, @style!.borderchars, false, false
        @reposition!
        if @hasTitleBar!
            SUI.WindowManager\gfx!\pushColor titlecolor, nil
            SUI.WindowManager\gfx!\drawBox x, y, w, @style!.titleheight -- titlebar box
            if @style!.hasborder -- titlebar border
                invertTopBottomBorders = false
                invertTopBottomBorders = true if @style!.titleheight <= 1
                SUI.WindowManager\gfx!\pushColor nil, bordercolor
                SUI.WindowManager\gfx!\drawBorder x, y, w, @style!.titleheight, @style!.titleborderchars, invertTopBottomBorders
                SUI.WindowManager\gfx!\popColor!
            SUI.WindowManager\gfx!\pushColor textbgcolor, textfgcolor
            textpadding = @style!.textpadding -- title
            SUI.WindowManager\gfx!\drawText @text!, x + textpadding, y + (math.ceil(@style!.titleheight / 2) - 1),
                w - textpadding * 2 - (textpadding + 2), math.ceil(@style!.titleheight / 2),
                @style!.titlevalign, @style!.titlehalign, true, true
            SUI.WindowManager\gfx!\plot (@props.x + @props.w) - (textpadding + 2), y + (math.ceil(@style!.titleheight / 2) - 1), @style!.closeicon if @hasCloseButton! -- close button
            SUI.WindowManager\gfx!\popColor 2
        SUI.WindowManager\gfx!\popColor!
        @processChildren!
    --------------------------------------
    onEvent: (e) =>
        -- window dragging (NOT WORKING!)
        --if e[1] == 'drag' and @movable! -- check if the window is being dragged
        --    if tonumber(e[3]) >= @props.x - 1 and tonumber(e[3]) < @props.x + @props.w and
        --        tonumber(e[4]) >= @props.y - 1 and tonumber(e[4]) < @props.y + @style!.titleheight - 1
        --    dx = tonumber(e[3]) - @props.epx
        --    dy = tonumber(e[4]) - @props.epy
        --    @pos @props.x + dx, @props.y + dy
        --    @props.epx = tonumber(e[3])
        --    @props.epy = tonumber(e[4])
        --    return
        -- touch or scroll event
        if e[1] == 'touch' or e[1] == 'scroll' or e[1] == 'monitor_touch'
            @props.epx = tonumber(e[3])
            @props.epy = tonumber(e[4])
            -- close click check
            if (e[1] == 'touch' or e[1] == 'monitor_touch') and tonumber(e[5]) == 0 and @hasTitleBar! and @hasCloseButton! -- if user clicked close button (if available)
                textpadding = @style!.textpadding -- find the position of close button to check if click was inside of it
                x, y, w, h = (@props.x + @props.w) - (textpadding + 2), @props.y + (math.ceil(@style!.titleheight / 2) - 1), 1, 1
                mx, my = tonumber(e[3]), tonumber(e[4])
                if mx >= x and mx < x + w and my >= y and my < y + h
                    SUI.WindowManager\gfx!\pushColor @style!.titleclickbg, @style!.titleclickfg
                    SUI.WindowManager\gfx!\plot (@props.x + @props.w) - (textpadding + 2), @props.y + (math.ceil(@style!.titleheight / 2) - 1), @style!.closeicon
                    SUI.WindowManager\gfx!\popColor!
                    os.sleep @style!.closedelay
                    @parent!\remove self
                    ce = {'window_closed'} -- custom event
                    SUI.WindowManager\eventHandler ce, self
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
    --------------------------------------
------------------------------------------------------
class SUI.Components.Box extends SUI.Component
    new: (bg, fg, x=1, y=1, w=1, h=1, fillChar=' ') =>
        super 'Box', x, y, w, h
        @props.Box = bg: bg, fg: fg, fillChar: fillChar
    --------------------------------------
    color: (bg, fg) =>
        return @props.Box.bg, @props.Box.fg unless bg and fg
        @props.Box.bg = bg
        @props.Box.fg = fg
    --------------------------------------
    fillChar: (char) =>
        return @props.Box.fillChar unless char
        @props.Box.fillChar = char
    --------------------------------------
    draw: =>
        SUI.WindowManager\gfx!\pushColor @props.Box.bg, @props.Box.fg
        SUI.WindowManager\gfx!\drawBox @props.x, @props.y, @props.w, @props.h, @fillChar!
        SUI.WindowManager\gfx!\drawBorder @props.x, @props.y, @props.w, @props.h, @style!.borderchars if @style!.hasborder
        SUI.WindowManager\gfx!\popColor!
    --------------------------------------
------------------------------------------------------
class SUI.Components.Label extends SUI.Component
    new: (text='', x=0, y=0, w=0, h=0, valign='center', halign='center', wrap=false, clip=false) =>
        super 'Label', x, y, w, h, text
        @props.Label = valign: valign, halign: halign, wrap: wrap, clip: clip
    --------------------------------------
    align: (valign, halign) =>
        return @props.Label.valign, @props.Label.halign if valign and halign
        valign = @props.Label.valign unless valign
        halign = @props.Label.halign unless halign
        @props.Label.valign = valign
        @props.Label.halign = halign
    --------------------------------------
    wrap: (state) =>
        return @props.Label.wrap if state == nil
        @props.Label.wrap = state
    --------------------------------------
    clip: (state) =>
        return @props.Label.clip if state == nil
        @props.Label.clip = state
    --------------------------------------
    draw: =>
        SUI.WindowManager\gfx!\pushColor @style!.background, @style!.textcolor
        SUI.WindowManager\gfx!\drawText @text!, @props.x, @props.y, @props.w, @props.h, @props.Label.valign,
            @props.Label.halign, @props.Label.wrap, @props.Label.clip, @style!.background
        SUI.WindowManager\gfx!\popColor!
    --------------------------------------
------------------------------------------------------
class SUI.Components.Button extends SUI.Component
    new: (text='', x=1, y=1, w=1, h=1) =>
        super 'Button', x, y, w, h, text
        @props.Button = isClicked: false
    --------------------------------------
    draw: =>
        bg, fg = @style!.background, @style!.textcolor
        bg, fg = @style!.clickedbackground, @style!.clickedtextcolor if @props.Button.isClicked
        padding = 0
        padding = @style!.textpadding if @style!.hasborder
        itbb = @props.h == 1 and true or false
        SUI.WindowManager\gfx!\pushColor bg, fg
        SUI.WindowManager\gfx!\drawBorder @props.x, @props.y, @props.w, @props.h, @style!.borderchars, false, itbb if @style!.hasborder
        SUI.WindowManager\gfx!\drawText @text!, @props.x + padding, @props.y, @props.w - padding * 2, @props.h, @style!.textvalign,
            @style!.texthalign, true, true, @style!.background
        SUI.WindowManager\gfx!\popColor!
    --------------------------------------
    onEvent: (e) =>
        if e[1] == 'touch' and e[5] == 0
            @props.Button.isClicked = true
            @draw!
            os.sleep @style!.clicksleep
            @props.Button.isClicked = false
            @draw!
        super e
    --------------------------------------
------------------------------------------------------
class SUI.Components.Toggle extends SUI.Component
    new: (text='', x=1, y=1, w=1, h=1) =>
        super 'Toggle', x, y, w, h, text
        @props.Toggle = isClicked: false, isActive: false
    --------------------------------------
    active: (state) =>
        return @props.Toggle.isActive if state == nil
        @props.Toggle.isActive = state
    --------------------------------------
    draw: =>
        bg, fg = @style!.background, @style!.textcolor
        bg, fg = @style!.clickedbackground, @style!.clickedtextcolor if @props.Toggle.isClicked
        bg, fg = @style!.activebackground, @style!.activetextcolor if @active! and not @props.Toggle.isClicked
        padding = 0
        padding = @style!.textpadding if @style!.hasborder
        itbb = @props.h == 1 and true or false
        SUI.WindowManager\gfx!\pushColor bg, fg
        SUI.WindowManager\gfx!\drawBorder @props.x, @props.y, @props.w, @props.h, @style!.borderchars, false, itbb if @style!.hasborder
        SUI.WindowManager\gfx!\drawText @text!, @props.x + padding, @props.y, @props.w - padding * 2, @props.h, @style!.textvalign,
            @style!.texthalign, true, true, @style!.background
        SUI.WindowManager\gfx!\popColor!
    --------------------------------------
    onEvent: (e) =>
        if e[1] == 'touch' and e[5] == 0
            @props.Toggle.isClicked = true
            @draw!
            os.sleep @style!.clicksleep
            @props.Toggle.isClicked = false
            @active(not @active!)
            @draw!
        super e
    --------------------------------------
------------------------------------------------------
class SUI.Components.Progress extends SUI.Component
    new: (x=1, y=1, w=1, h=1, direction='hor') =>
        super 'Progress', x, y, w, h
        @props.Progress = current: 0, direction: direction, inverted: inverted
    --------------------------------------
    direction: (direction) =>
        return @props.Progress.direction unless direction
        @props.Progress.direction = direction if direction == 'ver' or direction == 'hor'
    --------------------------------------
    inverted: (state) =>
        return @props.Progress.inverted if state == nil
        @props.Progress.inverted = state
    --------------------------------------
    progress: (progress, min=0, max=1) =>
        return @props.Progress.current unless progress
        progress = min if progress < min
        progress = max if progress > max
        @props.Progress.current = progress
    --------------------------------------
    draw: =>
        SUI.WindowManager\gfx!\pushColor @style!.background, @style!.textcolor
        SUI.WindowManager\gfx!\drawBox @props.x, @props.y, @props.w, @props.h, @style!.emptychar
        SUI.WindowManager\gfx!\pushColor @style!.prgbackground, @style!.prgtextcolor
        sx, sy, sw, sh = @props.x, @props.y, @props.w, @props.h
        if @style!.hasborder
            sx += 1
            sy += 1
            sw -= 2
            sh -= 2
        if @progress! > 0
            if @direction! == 'hor'
                SUI.WindowManager\gfx!\drawBox sx, sy, math.floor(sw * @progress!), sh, @style!.prgchar
            else
                progress = math.floor(sh * @progress!)
                SUI.WindowManager\gfx!\drawBox sx, (sy + (sh - progress)), sw, progress, @style!.prgchar
        SUI.WindowManager\gfx!\drawBorder @props.x, @props.y, @props.w, @props.h, @style!.borderchars if @style!.hasborder
        SUI.WindowManager\gfx!\popColor 2
    --------------------------------------
------------------------------------------------------
class SUI.Components.Tabs extends SUI.Component
    --------------------------------------
------------------------------------------------------
class SUI.Components.Panel extends SUI.Component
    --------------------------------------
------------------------------------------------------
class SUI.Components.Modal extends SUI.Component
    --------------------------------------
------------------------------------------------------
class SUI.Components.Layout extends SUI.Component
    --------------------------------------
------------------------------------------------------
class SUI.Components.Scroller extends SUI.Component
    --------------------------------------
------------------------------------------------------
class SUI.Components.List extends SUI.Component
    --------------------------------------
------------------------------------------------------
class SUI.Components.Spinner extends SUI.Component
    --------------------------------------
------------------------------------------------------
class SUI.Components.Checkbox extends SUI.Component
    --------------------------------------
------------------------------------------------------
class SUI.Components.Radiobox extends SUI.Component
    --------------------------------------
------------------------------------------------------
class SUI.Components.Editbox extends SUI.Component
    --------------------------------------
------------------------------------------------------
-- initialization function. returns the window manager and assigned display width and height
SUI.init = (gctx) ->
    if gctx
        SUI.DefaultStyle = SUI.Style 'default'
        SUI.WindowManager = SUI.Components.WindowManager gctx
        return SUI.WindowManager
    nil
------------------------------------------------------
-- module returns
SUI
------------------------------------------------------
