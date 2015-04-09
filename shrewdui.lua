local UI = { }
UI.Components = { }
local Util = { }
local GFX = { }
local occomp = require('component')
local ocevent = require('event')
local ocfs = require('filesystem')
local ocserialization = require('serialization')
local unicode = require('unicode')
package.loaded.json = nil
local json = require('json')
local ocgpu
local compcounter = 0
Util.tblcpy = function(tab, recursive)
  local shallowcopy
  shallowcopy = function(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
      copy = { }
      for orig_key, orig_value in pairs(orig) do
        copy[orig_key] = orig_value
      end
    else
      copy = orig
    end
    return copy
  end
  local deepcopy
  deepcopy = function(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
      copy = { }
      for orig_key, orig_value in next,orig,nil do
        copy[deepcopy(orig_key)] = deepcopy(orig_value)
      end
      setmetatable(copy, deepcopy(getmetatable(orig)))
    else
      copy = orig
    end
    return copy
  end
  if recursive then
    return deepcopy(tab)
  else
    return shallowcopy(tab)
  end
end
Util.checkNotExceedScrBounds = function(x, y, trueVals, wrap)
  if x == nil then
    x = 1
  end
  if y == nil then
    y = 1
  end
  if trueVals == nil then
    trueVals = false
  end
  if wrap == nil then
    wrap = false
  end
  local mw, mh = UI.WindowManager:size()
  if trueVals then
    if wrap then
      local needsScroll = false
      if x < 1 then
        x, y = 1, y - 1
      end
      if x > mw then
        x, y = 1, y + 1
      end
      if y < 1 then
        x, y = 1, 1
      end
      if y > mh then
        x, y, needsScroll = 1, mh, true
      end
      return x, y, needsScroll
    else
      if x < 1 then
        x = 1
      end
      if x > mw then
        x = mw
      end
      if y < 1 then
        y = 1
      end
      if y > mh then
        y = mh
      end
      return x, y
    end
  else
    if x < 1 or x > mw or y < 1 or y > mh then
      return true
    else
      return false
    end
  end
  return x, y, mw, mh
end
Util.intersect = function(self, x, y, w, h, ix, iy)
  print(tostring(x), tostring(y), tostring(w), tostring(h), tostring(ix), tostring(iy))
  if ix >= x and ix < x + w and iy >= y and iy < y + h then
    return true
  end
  return false
end
Util.checkUnicodeChar = function(char)
  if type(char) == 'number' then
    char = unicode.char(char)
  elseif type(char) == 'string' then
    char = char:sub(1, 1)
  end
  return char
end
GFX.__colorStack = { }
GFX.Colors = {
  Black = 0x000000,
  Blue = 0x0000FF,
  Green = 0x00FF00,
  Red = 0xFF0000,
  Yellow = 0xFFFF00,
  Cyan = 0x00FFFF,
  Purple = 0xFF00FF,
  White = 0xFFFFFF
}
GFX.firstColor = function(bg, fg)
  if not (bg and fg) then
    return GFX.__colorStack[1].bg, GFX.__colorStack[1].fg
  end
  GFX.__colorStack[1] = {
    bg = bg,
    fg = fg
  }
end
GFX.pushColor = function(bg, fg)
  if not (bg) then
    bg = GFX.__colorStack[#GFX.__colorStack].bg
  end
  if not (fg) then
    fg = GFX.__colorStack[#GFX.__colorStack].fg
  end
  table.insert(GFX.__colorStack, {
    bg = bg,
    fg = fg
  })
  ocgpu.setBackground(bg, false)
  return ocgpu.setForeground(fg, false)
end
GFX.popColor = function(times)
  if times == nil then
    times = 1
  end
  local poppedColors = { }
  local cslen
  cslen = function()
    return #GFX.__colorStack
  end
  if times >= cslen() or times == 0 then
    times = cslen() - 1
  end
  for i = 1, times do
    if #GFX.__colorStack > 1 then
      local last = GFX.__colorStack[cslen()]
      local oldbg, oldfg = last.bg, last.fg
      table.remove(GFX.__colorStack, cslen())
      last = GFX.__colorStack[cslen()]
      local newbg, newfg = last.bg, last.fg
      ocgpu.setBackground(newbg, false)
      ocgpu.setForeground(newfg, false)
      table.insert(poppedColors, {
        oldbg,
        oldfg,
        newbg,
        newfg
      })
    else
      table.insert(poppedColors, {
        GFX.__colorStack[1].bg,
        GFX.__colorStack[1].fg
      })
    end
  end
  return poppedColors
end
GFX.plot = function(x, y, char)
  if char == nil then
    char = ' '
  end
  char = Util.checkUnicodeChar(char)
  if tonumber(char) then
    char = tonumber(char)
  end
  return ocgpu.set(x, y, char, false)
end
GFX.drawStaticLine = function(x, y, len, isVertical, fillChar)
  if isVertical == nil then
    isVertical = false
  end
  if fillChar == nil then
    fillChar = ' '
  end
  fillChar = Util.checkUnicodeChar(fillChar)
  local str = ''
  for i = 1, len do
    str = str .. fillChar
  end
  return ocgpu.set(x, y, str, isVertical)
end
GFX.drawLine = function(x0, y0, x1, y1, fillChar)
  if fillChar == nil then
    fillChar = ' '
  end
  fillChar = Util.checkUnicodeChar(fillChar)
  local dx = math.abs(x1 - x0)
  local sx = x0 < x1 and 1 or -1
  local dy = math.abs(y1 - y0)
  local sy = y0 < y1 and 1 or -1
  local err = (dx > dy and dx or -dy) / 2
  local e2 = 0
  while true do
    GFX.plot(x0, y0, fillChar)
    if x0 == x1 and y0 == y1 then
      break
    end
    e2 = err
    if e2 > -dx then
      err = err - dy
      x0 = x0 + sx
    end
    if e2 < dy then
      err = err + dx
      y0 = y0 + sy
    end
  end
end
GFX.drawText = function(text, x, y, w, h, valign, halign, wrap, clip, fill, hasFilledColor, fillChar)
  if w == nil then
    w = 0
  end
  if h == nil then
    h = 0
  end
  if valign == nil then
    valign = 'center'
  end
  if halign == nil then
    halign = 'center'
  end
  if wrap == nil then
    wrap = false
  end
  if clip == nil then
    clip = false
  end
  if fill == nil then
    fill = false
  end
  if hasFilledColor == nil then
    hasFilledColor = false
  end
  if fillChar == nil then
    fillChar = ' '
  end
  fillChar = Util.checkUnicodeChar(fillChar)
  if fill then
    GFX.drawBox(x, y, w, h, fillChar)
    if hasFilledColor then
      GFX.popColor()
    end
  end
  local lines = { }
  if wrap then
    local token
    token = function(s)
      local tokens = { }
      for word in s:gmatch('%S+') do
        table.insert(tokens, word)
      end
      return tokens
    end
    local spaceleft = w
    local line = { }
    for _, word in ipairs(token(text)) do
      if word:len() + 1 > spaceleft then
        table.insert(lines, table.concat(line, ' '))
        line = { }
        table.insert(line, word)
        spaceleft = w - word:len() + 1
      else
        table.insert(line, word)
        spaceleft = spaceleft - (word:len() + 1)
      end
    end
    table.insert(lines, table.concat(line, ' '))
  else
    local tmptext = ''
    for i = 1, text:len() do
      local c = text:sub(i, i)
      if c == '\n' then
        table.insert(lines, tmptext)
        tmptext = ''
      else
        tmptext = tmptext .. c
      end
    end
    table.insert(lines, tmptext)
  end
  if clip then
    local tmplines = { }
    for lineN, lineT in ipairs(lines) do
      if lineN - 1 < h then
        local tmptext = ''
        for i = 1, lineT:len() do
          if i - 1 < w then
            tmptext = tmptext .. lineT:sub(i, i)
          else
            break
          end
        end
        table.insert(tmplines, tmptext)
      else
        break
      end
    end
    lines = tmplines
  end
  if valign ~= 'top' then
    local linesL = #lines
    if linesL < h then
      local padding = valign == 'center' and (h - linesL) / 2 or h - linesL
      for i = 1, padding do
        table.insert(lines, i, '')
      end
    end
  end
  local halign_draw_text = false
  if halign ~= 'left' then
    halign_draw_text = true
    for lineN, lineT in ipairs(lines) do
      local lineL = lineT:len()
      local padding = 0
      if lineL < w then
        padding = halign == 'center' and (w - lineL) / 2 or w - lineL
      end
      ocgpu.set(x + padding, y + (lineN - 1), lineT, false)
    end
  end
  if not (halign_draw_text) then
    for i, line in ipairs(lines) do
      ocgpu.set(x, y + (i - 1), line, false)
    end
  end
end
GFX.drawBox = function(x, y, w, h, fillChar)
  if fillChar == nil then
    fillChar = ' '
  end
  fillChar = Util.checkUnicodeChar(fillChar)
  return ocgpu.fill(x, y, w, h, fillChar)
end
GFX.drawBorder = function(x, y, w, h, borderSurrounding, invertTopBottomBorders, ignoreTopBottomBorders)
  if invertTopBottomBorders == nil then
    invertTopBottomBorders = false
  end
  if ignoreTopBottomBorders == nil then
    ignoreTopBottomBorders = false
  end
  if not (borderSurrounding or type(borderSurrounding) == 'table') then
    borderSurrounding = {
      88,
      88,
      88,
      88,
      88,
      88,
      88,
      88
    }
  end
  if #borderSurrounding < 8 then
    for i = #borderSurrounding, 8 do
      table.insert(borderSurrounding, 88)
    end
  end
  local tl, tc, tr = borderSurrounding[1], borderSurrounding[2], borderSurrounding[3]
  local cl, cr = borderSurrounding[8], borderSurrounding[4]
  local bl, bc, br = borderSurrounding[7], borderSurrounding[6], borderSurrounding[5]
  if invertTopBottomBorders then
    local l, c, r = tl, tc, tr
    tl, tc, tr = bl, bc, br
    bl, bc, br = l, c, r
  end
  if not (ignoreTopBottomBorders) then
    GFX.plot(x, y, tl)
    GFX.drawStaticLine(x + 1, y, w - 2, false, tc)
    GFX.plot(x + w - 1, y, tr)
  end
  local lbx, lby, lbl = x, y + 1, h - 2
  local rbx, rby, rbl = x + w - 1, y + 1, h - 2
  if ignoreTopBottomBorders then
    lby, lbl = y, h
    rby, rbl = y, h
  end
  GFX.drawStaticLine(lbx, lby, lbl, true, cl)
  GFX.drawStaticLine(rbx, rby, rbl, true, cr)
  if not (ignoreTopBottomBorders) then
    GFX.plot(x, y + h - 1, bl)
    GFX.drawStaticLine(x + 1, y + h - 1, w - 2, false, bc)
    return GFX.plot(x + w - 1, y + h - 1, br)
  end
end
do
  local _base_0 = {
    loadStyle = function(self, style)
      local default_style = [[{
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
      local jsonstr = ''
      if style == 'default' then
        jsonstr = default_style
      else
        if ocfs.exists(style) then
          local f = io.open(style, 'r')
          if f then
            jsonstr = {
              f = read('*all')
            }
            local _ = {
              f = close()
            }
            if not (jsonstr) then
              return false
            end
          end
        elseif type(style) == 'string' then
          jsonstr = style
        end
      end
      if #jsonstr > 0 then
        self.style = json:decode(jsonstr)
        for c, t in pairs(self.style) do
          if type(t) == 'table' then
            for p, v in pairs(t) do
              if type(v) == 'string' and v:len() > 3 and v:sub(1, 1) == '$' and v:sub(3, 3) == ':' then
                local cmd = v:sub(2, 2)
                local tmpstr = ''
                for i = 4, v:len() do
                  if cmd == 'c' then
                    tmpstr = v:sub(i, i)
                    self.style[c][p] = tmpstr
                    break
                  elseif cmd == 's' or cmd == 'n' or cmd == 't' then
                    tmpstr = tmpstr .. v:sub(i, i)
                  end
                end
                if cmd == 's' then
                  self.style[c][p] = tmpstr
                end
                if cmd == 'n' then
                  self.style[c][p] = tonumber(tmpstr)
                end
                if cmd == 't' then
                  local tmptbl = ocserialization.unserialize("{" .. tostring(tmpstr) .. "}")
                  for i, v in ipairs(tmptbl) do
                    if tonumber(v) then
                      tmptbl[i] = tonumber(v)
                    end
                  end
                  self.style[c][p] = tmptbl
                end
              end
            end
          end
        end
      end
      return jsonstr
    end,
    prop = function(self, prop, val)
      if not (val) then
        return self.style[prop]
      end
      self.style[prop] = val
    end,
    componentStyleProp = function(self, component, prop, val)
      if not (val) then
        return self.style[component][prop]
      end
      self.style[component][prop] = val
    end,
    componentStyle = function(self, component, style)
      if not (style) then
        return Util.tblcpy(self.style[component])
      end
      self.style[component] = Util.tblcpy(style)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, style)
      self.style = { }
      return self:loadStyle(style)
    end,
    __base = _base_0,
    __name = "Style"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  UI.Style = _class_0
end
do
  local _base_0 = {
    prop = function(self, prop, val)
      if not (val) then
        return self.props[prop]
      end
      self.props[prop] = val
    end,
    pprop = function(self, prop, c, val)
      if not (val) then
        return self.props[prop][c]
      end
      self.props[prop][c] = val
    end,
    parent = function(self, parent)
      if not (parent) then
        return self.props.parent
      end
      self.props.parent = parent
    end,
    size = function(self, w, h)
      if not (w and h) then
        return self.props.cw, self.props.ch
      end
      if w then
        self.props.w = w
      end
      if h then
        self.props.h = h
      end
      self.props.cw, self.props.ch = self.props.w, self.props.h
    end,
    pos = function(self, x, y)
      if not (x and y) then
        return self.props.cx, self.props.cy
      end
      if x then
        self.props.x = x
      end
      if y then
        self.props.y = y
      end
      self.props.cx, self.props.cy = self.props.x, self.props.y
    end,
    weight = function(self, weight)
      if not (weight) then
        return self.props.weight
      end
      self.props.weight = weight
    end,
    text = function(self, text)
      if text then
        self.props.text = text
      else
        return self.props.text
      end
    end,
    style = function(self, style)
      if not (style) then
        return self.props.style
      end
      self.props.style = style:componentStyle(self:type())
    end,
    type = function(self, type)
      if not (type) then
        return self.props.type
      end
      self.props.type = type
    end,
    focused = function(self, state)
      if state == nil then
        return self.props.focused
      end
      if self.props.parent then
        for i, c in ipairs(self.props.parent.children) do
          c.props.focused = false
        end
      end
      self.props.focused = state
    end,
    visible = function(self, state)
      if state == nil then
        return self.props.visible
      end
      self.props.visible = state
    end,
    compare = function(self, component)
      if self.props.id == component.props.id then
        return true
      end
      return false
    end,
    add = function(self, component)
      table.insert(self.children, component)
      component:parent(self)
      component.props.zorder = self.props.zindex
      self.props.zindex = self.props.zindex + 1
      for i, c in ipairs(self.children) do
        if c.props.focusable and (function()
          local _base_1 = c
          local _fn_0 = _base_1.focused
          return function(...)
            return _fn_0(_base_1, ...)
          end
        end)() then
          c:focused(false)
        end
      end
      if component.props.focusable then
        component:focused(true)
      end
      return self:sortChildren()
    end,
    remove = function(self, component)
      self:sortChildren()
      for i, c in ipairs(self.children) do
        if component:compare(c) then
          table.remove(self.children, component.props.zorder + 1)
          component.props.zorder = 0
          self.props.zindex = self.props.zindex - 1
          if component.props.focusable then
            component:focused(false)
          end
          self:sortChildren()
          if self.props.zindex > 0 then
            self.children[self.props.zindex]:focused(true)
          end
          break
        end
      end
    end,
    intersect = function(self, x, y)
      if x >= self.props.x and x < self.props.x + self.props.w and y >= self.props.y and y < self.props.y + self.props.h then
        return true
      end
      return false
    end,
    bringToFront = function(self)
      self:sortChildren()
      local parentChilds = self:parent().children
      local bringOne = self.props.zorder
      local oldOne = self.props.zorder
      local bringElement = self
      for _, w in ipairs(parentChilds) do
        if bringOne < w.props.zorder and not self:compare(w) then
          bringOne = w.props.zorder
          bringElement = w
        end
      end
      self.props.zorder = bringOne
      bringElement.props.zorder = oldOne
      self:focused(true)
      return self:sortChildren()
    end,
    sendToBack = function(self)
      self:sortChildren()
      local parentChilds = self:parent().children
      local bringOne = self.props.zorder
      local willMove = { }
      for _, w in ipairs(parentChilds) do
        if bringOne >= w.props.zorder and not self:compare(w) then
          table.insert(willMove, w)
        end
      end
      for _, w in ipairs(willMove) do
        w.props.zorder = w.props.zorder + 1
      end
      willMove[1]:focused(true)
      self.props.zorder = 0
      return self:sortChildren()
    end,
    firstFocusableChild = function(self)
      for i = #self.children, 1, -1 do
        if self.children[i].props.focusable and not self.children[i]:focused() then
          return self.children[i]
        end
      end
      return nil
    end,
    sortChildren = function(self)
      local sort
      sort = function(a, b)
        return a.props.zorder < b.props.zorder
      end
      return table.sort(self.children, sort)
    end,
    processChildren = function(self)
      self:sortChildren()
      for i, component in ipairs(self.children) do
        if component:visible() then
          component:draw()
        end
      end
    end,
    reposition = function(self) end,
    draw = function(self) end,
    onEvent = function(self, e)
      return UI.WindowManager:eventHandler(e, self)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, type, x, y, w, h, text)
      if text == nil then
        text = ''
      end
      self.props = {
        parent = nil,
        weight = 1,
        text = text,
        type = type,
        x = x,
        y = y,
        w = w,
        h = h,
        cx = x,
        cy = y,
        cw = w,
        ch = h,
        zorder = 0,
        zindex = 0,
        style = { },
        focused = false,
        focusable = false,
        visible = true,
        id = compcounter,
        forceReceiveEvent = false
      }
      self.children = { }
      self.eventListeners = { }
      compcounter = compcounter + 1
      return self:style(UI.DefaultStyle)
    end,
    __base = _base_0,
    __name = "Component"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  UI.Component = _class_0
end
do
  local _parent_0 = UI.Component
  local _base_0 = {
    eventHandler = function(self, stuff, c)
      if type(stuff) == 'function' then
        self.props.WindowManager.eventHandler = stuff
      elseif type(stuff) == 'table' then
        if type(self.props.WindowManager.eventHandler) == 'function' then
          return self.props.WindowManager.eventHandler(c, stuff)
        end
      end
    end,
    size = function(self, w, h)
      if not (w and h) then
        return self.props.w, self.props.h
      end
      if w < 1 then
        w = 1
      end
      if w > self.props.WindowManager.maxResX then
        w = self.props.WindowManager.maxResX
      end
      if h < 1 then
        h = 1
      end
      if h > self.props.WindowManager.maxResY then
        h = self.props.WindowManager.maxResY
      end
      if w then
        self.props.w = w
      end
      if h then
        self.props.h = h
      end
      return ocgpu.setResolution(self.props.w, self.props.h)
    end,
    maxSize = function(self)
      return self.props.WindowManager.maxResX, self.props.WindowManager.maxResY
    end,
    process = function(self)
      self:sortChildren()
      local tevt = table.pack(ocevent.pull(0.1))
      local focusedC
      for i, c in ipairs(self.children) do
        if c:focused() then
          focusedC = c
          break
        end
      end
      if tevt[1] == 'key_down' or tevt[1] == 'scroll' or tevt[1] == 'key_up' or tevt[1] == 'touch' or tevt[1] == 'drag' or tevt[1] == 'drop' then
        if focusedC then
          if tevt[1] ~= 'touch' and tevt[1] ~= 'drag' and tevt[1] ~= 'drop' then
            focusedC:onEvent(tevt)
          elseif focusedC:intersect(tonumber(tevt[3]), tonumber(tevt[4])) then
            focusedC:onEvent(tevt)
          else
            for i = #self.children, 1, -1 do
              if not (focusedC:compare(self.children[i])) then
                if self.children[i]:intersect(tonumber(tevt[3]), tonumber(tevt[4])) then
                  focusedC:focused(false)
                  focusedC = self.children[i]
                  focusedC:focused(true)
                  focusedC:onEvent(tevt)
                  focusedC:bringToFront()
                  break
                end
              end
            end
          end
        end
        for j, cj in ipairs(self.children) do
          if cj.props.forceReceiveEvent and cj:intersect(tonumber(tevt[3]), tonumber(tevt[4])) then
            cj:onEvent(tevt)
          end
        end
      end
      self:draw()
      return tevt
    end,
    draw = function(self)
      if self:visible() then
        GFX.pushColor(self:style().background, self:style().textcolor)
        GFX.drawBox(self.props.x, self.props.y, self.props.w, self.props.h)
        GFX.popColor()
        return self:processChildren()
      end
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, maxResX, maxResY, resX, resY)
      _parent_0.__init(self, 'WindowManager', 1, 1, resX, resY)
      self.props.WindowManager = {
        maxResX = maxResX,
        maxResY = maxResY,
        eventHandler = nil
      }
      return self:size(resX, resY)
    end,
    __base = _base_0,
    __name = "WindowManager",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  UI.Components.WindowManager = _class_0
end
do
  local _parent_0 = UI.Component
  local _base_0 = {
    hasCloseButton = function(self, state)
      if state == nil then
        return self.props.Window.hasCloseButton
      end
      self.props.Window.hasCloseButton = state
    end,
    hasTitleBar = function(self, state)
      if state == nil then
        return self.props.Window.hasTitleBar
      end
      self.props.Window.hasTitleBar = state
      return self:movable(state)
    end,
    movable = function(self, state)
      if state == nil then
        return self.props.Window.movable
      end
      self.props.Window.movable = state
    end,
    reposition = function(self)
      local mx, my = self:pos()
      local mw, mh = self:size()
      if self:hasTitleBar() then
        my = my + (self:style().titleheight - 1)
      end
      for i, c in ipairs(self.children) do
        local x, y = c:pos()
        local w, h = c:size()
        if x < 1 then
          x = 1
        end
        if y < 1 then
          y = 1
        end
        x = x + mx
        y = y + my
        if x + w >= mx + mw then
          w = (mx + mw) - x - 1
        end
        local th = ((function()
          if self:hasTitleBar() then
            return (self:style().titleheight - 1)
          else
            return 0
          end
        end)())
        if y + h >= (my + mh) - th then
          h = (my + mh) - y - 1 - th
        end
        if x >= mx + mw - 1 or x <= mx or y >= my + mh - 1 or y <= my then
          c:visible(false)
        else
          c:visible(true)
          c.props.x = x
          c.props.y = y
          c.props.w = w
          c.props.h = h
        end
      end
    end,
    draw = function(self)
      local background, bordercolor, titlecolor, textbgcolor, textfgcolor = self:style().background, self:style().bordercolor, self:style().titlecolor, self:style().textbgcolor, self:style().textfgcolor
      if not (self:focused() and self:style().hasnfc) then
        local bg, fg = self:style().nfbgc, self:style().nffg
        background, bordercolor, titlecolor, textbgcolor, textfgcolor = bg, fg, bg, bg, fg
      end
      GFX.pushColor(background, bordercolor)
      local x, y, w, h = self.props.x, self.props.y, self.props.w, self.props.h
      GFX.drawBox(x, y, w, h)
      if self:style().hasborder then
        GFX.drawBorder(x, y, w, h, self:style().borderchars, false, false)
      end
      self:reposition()
      self:processChildren()
      if self:hasTitleBar() then
        GFX.pushColor(titlecolor, nil)
        GFX.drawBox(x, y, w, self:style().titleheight)
        if self:style().hasborder then
          local invertTopBottomBorders = false
          if self:style().titleheight <= 1 then
            invertTopBottomBorders = true
          end
          GFX.pushColor(nil, bordercolor)
          GFX.drawBorder(x, y, w, self:style().titleheight, self:style().titleborderchars, invertTopBottomBorders)
          GFX.popColor()
        end
        GFX.pushColor(textbgcolor, textfgcolor)
        local textpadding = self:style().textpadding
        GFX.drawText(self:text(), x + textpadding, y + (math.ceil(self:style().titleheight / 2) - 1), w - textpadding * 2 - (textpadding + 2), math.ceil(self:style().titleheight / 2), self:style().titlevalign, self:style().titlehalign, true, true)
        if self:hasCloseButton() then
          GFX.plot((self.props.x + self.props.w) - (textpadding + 2), y + (math.ceil(self:style().titleheight / 2) - 1), self:style().closeicon)
        end
        GFX.popColor(2)
      end
      return GFX.popColor()
    end,
    onEvent = function(self, e)
      if e[1] == 'touch' or e[1] == 'scroll' then
        if e[1] == 'touch' and tonumber(e[5]) == 0 and self:hasTitleBar() and self:hasCloseButton() then
          local textpadding = self:style().textpadding
          local x, y, w, h = (self.props.x + self.props.w) - (textpadding + 2), self.props.y + (math.ceil(self:style().titleheight / 2) - 1), 1, 1
          local mx, my = tonumber(e[3]), tonumber(e[4])
          if mx >= x and mx < x + w and my >= y and my < y + h then
            GFX.pushColor(self:style().titleclickbg, self:style().titleclickfg)
            GFX.plot((self.props.x + self.props.w) - (textpadding + 2), self.props.y + (math.ceil(self:style().titleheight / 2) - 1), self:style().closeicon)
            GFX.popColor()
            os.sleep(0.3)
            self:focused(true)
            self:parent():remove(self)
            return 
          end
        end
        for i = #self.children, 1, -1 do
          if self.children[i]:intersect(tonumber(e[3]), tonumber(e[4])) then
            self.children[i]:onEvent(e)
            break
          end
        end
      else
        for i = #self.children, 1, -1 do
          if self.children[i]:focused() then
            self.children[i]:onEvent(e)
            break
          end
        end
      end
      return _parent_0.onEvent(self, e)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, hasTitleBar, text, x, y, w, h, hasCloseButton)
      if hasTitleBar == nil then
        hasTitleBar = true
      end
      if text == nil then
        text = ''
      end
      if x == nil then
        x = 0
      end
      if y == nil then
        y = 0
      end
      if w == nil then
        w = 0
      end
      if h == nil then
        h = 0
      end
      if hasCloseButton == nil then
        hasCloseButton = true
      end
      _parent_0.__init(self, 'Window', x, y, w, h, text)
      self.props.Window = {
        hasTitleBar = hasTitleBar,
        movable = hasTitleBar,
        hasCloseButton = hasCloseButton
      }
      self.props.focusable = true
    end,
    __base = _base_0,
    __name = "Window",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  UI.Components.Window = _class_0
end
do
  local _parent_0 = UI.Component
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Tabview",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  UI.Components.Tabview = _class_0
end
do
  local _parent_0 = UI.Component
  local _base_0 = {
    color = function(self, bg, fg)
      if not (bg and fg) then
        return self.props.Box.bg, self.props.Box.fg
      end
      self.props.Box.bg = bg
      self.props.Box.fg = fg
    end,
    fillChar = function(self, char)
      if not (char) then
        return self.props.Box.fillChar
      end
      self.props.Box.fillChar = char
    end,
    draw = function(self)
      GFX.pushColor(self.props.Box.bg, self.props.Box.fg)
      GFX.drawBox(self.props.x, self.props.y, self.props.w, self.props.h, self:fillChar())
      if self:style().hasborder then
        GFX.drawBorder(self.props.x, self.props.y, self.props.w, self.props.h, self:style().borderchars)
      end
      return GFX.popColor()
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, bg, fg, x, y, w, h, fillChar)
      if x == nil then
        x = 0
      end
      if y == nil then
        y = 0
      end
      if w == nil then
        w = 0
      end
      if h == nil then
        h = 0
      end
      if fillChar == nil then
        fillChar = ' '
      end
      _parent_0.__init(self, 'Box', x, y, w, h)
      self.props.Box = {
        bg = bg,
        fg = fg,
        fillChar = fillChar
      }
    end,
    __base = _base_0,
    __name = "Box",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  UI.Components.Box = _class_0
end
do
  local _parent_0 = UI.Component
  local _base_0 = {
    align = function(self, valign, halign)
      if valign and halign then
        return self.props.Label.valign, self.props.Label.halign
      end
      if not (valign) then
        valign = self.props.Label.valign
      end
      if not (halign) then
        halign = self.props.Label.halign
      end
      self.props.Label.valign = valign
      self.props.Label.halign = halign
    end,
    wrap = function(self, state)
      if state == nil then
        return self.props.Label.wrap
      end
      self.props.Label.wrap = state
    end,
    clip = function(self, state)
      if state == nil then
        return self.props.Label.clip
      end
      self.props.Label.clip = state
    end,
    draw = function(self)
      GFX.pushColor(self:style().background, self:style().textcolor)
      GFX.drawText(self:text(), self.props.x, self.props.y, self.props.w, self.props.h, self.props.Label.valign, self.props.Label.halign, self.props.Label.wrap, self.props.Label.clip, self:style().background)
      return GFX.popColor()
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, text, x, y, w, h, valign, halign, wrap, clip)
      if text == nil then
        text = ''
      end
      if x == nil then
        x = 0
      end
      if y == nil then
        y = 0
      end
      if w == nil then
        w = 0
      end
      if h == nil then
        h = 0
      end
      if valign == nil then
        valign = 'center'
      end
      if halign == nil then
        halign = 'center'
      end
      if wrap == nil then
        wrap = false
      end
      if clip == nil then
        clip = false
      end
      _parent_0.__init(self, 'Label', x, y, w, h, text)
      self.props.Label = {
        valign = valign,
        halign = halign,
        wrap = wrap,
        clip = clip
      }
    end,
    __base = _base_0,
    __name = "Label",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  UI.Components.Label = _class_0
end
do
  local _parent_0 = UI.Component
  local _base_0 = {
    draw = function(self)
      local bg, fg = self:style().background, self:style().textcolor
      if self.props.Button.isClicked then
        bg, fg = self:style().clickedbackground, self:style().clickedtextcolor
      end
      local padding = 0
      if self:style().hasborder then
        padding = self:style().textpadding
      end
      local itbb = self.props.h == 1 and true or false
      GFX.pushColor(bg, fg)
      if self:style().hasborder then
        GFX.drawBorder(self.props.x, self.props.y, self.props.w, self.props.h, self:style().borderchars, false, itbb)
      end
      GFX.drawText(self:text(), self.props.x + padding, self.props.y, self.props.w - padding * 2, self.props.h, self:style().textvalign, self:style().texthalign, true, true, self:style().background)
      return GFX.popColor()
    end,
    onEvent = function(self, e)
      if e[1] == 'touch' and e[5] == 0 then
        self.props.Button.isClicked = true
        self:draw()
        os.sleep(self:style().clicksleep)
        self.props.Button.isClicked = false
        self:draw()
      end
      return _parent_0.onEvent(self, e)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, text, x, y, w, h)
      if text == nil then
        text = ''
      end
      if x == nil then
        x = 0
      end
      if y == nil then
        y = 0
      end
      if w == nil then
        w = 0
      end
      if h == nil then
        h = 0
      end
      _parent_0.__init(self, 'Button', x, y, w, h, text)
      self.props.Button = {
        isClicked = false
      }
    end,
    __base = _base_0,
    __name = "Button",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  UI.Components.Button = _class_0
end
do
  local _parent_0 = UI.Component
  local _base_0 = {
    active = function(self, state)
      if state == nil then
        return self.props.Toggle.isActive
      end
      self.props.Toggle.isActive = state
    end,
    draw = function(self)
      local bg, fg = self:style().background, self:style().textcolor
      if self.props.Toggle.isClicked then
        bg, fg = self:style().clickedbackground, self:style().clickedtextcolor
      end
      if self:active() and not self.props.Toggle.isClicked then
        bg, fg = self:style().activebackground, self:style().activetextcolor
      end
      local padding = 0
      if self:style().hasborder then
        padding = self:style().textpadding
      end
      local itbb = self.props.h == 1 and true or false
      GFX.pushColor(bg, fg)
      if self:style().hasborder then
        GFX.drawBorder(self.props.x, self.props.y, self.props.w, self.props.h, self:style().borderchars, false, itbb)
      end
      GFX.drawText(self:text(), self.props.x + padding, self.props.y, self.props.w - padding * 2, self.props.h, self:style().textvalign, self:style().texthalign, true, true, self:style().background)
      return GFX.popColor()
    end,
    onEvent = function(self, e)
      if e[1] == 'touch' and e[5] == 0 then
        self.props.Toggle.isClicked = true
        self:draw()
        os.sleep(self:style().clicksleep)
        self.props.Toggle.isClicked = false
        self:active(not self:active())
        self:draw()
      end
      return _parent_0.onEvent(self, e)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, text, x, y, w, h)
      if text == nil then
        text = ''
      end
      if x == nil then
        x = 0
      end
      if y == nil then
        y = 0
      end
      if w == nil then
        w = 0
      end
      if h == nil then
        h = 0
      end
      _parent_0.__init(self, 'Toggle', x, y, w, h, text)
      self.props.Toggle = {
        isClicked = false,
        isActive = false
      }
    end,
    __base = _base_0,
    __name = "Toggle",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  UI.Components.Toggle = _class_0
end
do
  local _parent_0 = UI.Component
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "List",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  UI.Components.List = _class_0
end
do
  local _parent_0 = UI.Component
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Spinner",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  UI.Components.Spinner = _class_0
end
do
  local _parent_0 = UI.Component
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Checkbox",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  UI.Components.Checkbox = _class_0
end
do
  local _parent_0 = UI.Component
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Radiobox",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  UI.Components.Radiobox = _class_0
end
do
  local _parent_0 = UI.Component
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Editbox",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  UI.Components.Editbox = _class_0
end
do
  local _parent_0 = UI.Component
  local _base_0 = {
    direction = function(self, direction)
      if not (direction) then
        return self.props.Progress.direction
      end
      if direction == 'ver' or direction == 'hor' then
        self.props.Progress.direction = direction
      end
    end,
    inverted = function(self, state)
      if state == nil then
        return self.props.Progress.inverted
      end
      self.props.Progress.inverted = state
    end,
    progress = function(self, progress, min, max)
      if min == nil then
        min = 0
      end
      if max == nil then
        max = 1
      end
      if not (progress) then
        return self.props.Progress.current
      end
      if progress < min then
        progress = min
      end
      if progress > max then
        progress = max
      end
      self.props.Progress.current = progress
    end,
    draw = function(self)
      GFX.pushColor(self:style().background, self:style().textcolor)
      GFX.drawBox(self.props.x, self.props.y, self.props.w, self.props.h, self:style().emptychar)
      GFX.pushColor(self:style().prgbackground, self:style().prgtextcolor)
      local sx, sy, sw, sh = self.props.x, self.props.y, self.props.w, self.props.h
      if self:style().hasborder then
        sx = sx + 1
        sy = sy + 1
        sw = sw - 2
        sh = sh - 2
      end
      if self:progress() > 0 then
        if self:direction() == 'hor' then
          GFX.drawBox(sx, sy, math.floor(sw * self:progress()), sh, self:style().prgchar)
        else
          local progress = math.floor(sh * self:progress())
          GFX.drawBox(sx, (sy + (sh - progress)), sw, progress, self:style().prgchar)
        end
      end
      if self:style().hasborder then
        GFX.drawBorder(self.props.x, self.props.y, self.props.w, self.props.h, self:style().borderchars)
      end
      return GFX.popColor(2)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, x, y, w, h, direction)
      if x == nil then
        x = 0
      end
      if y == nil then
        y = 0
      end
      if w == nil then
        w = 0
      end
      if h == nil then
        h = 0
      end
      if direction == nil then
        direction = 'hor'
      end
      _parent_0.__init(self, 'Progress', x, y, w, h)
      self.props.Progress = {
        current = 0,
        direction = direction,
        inverted = inverted
      }
    end,
    __base = _base_0,
    __name = "Progress",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  UI.Components.Progress = _class_0
end
UI.init = function(resX, resY)
  if not (occomp.isAvailable('gpu') or occomp.isAvailable('screen')) then
    return false
  end
  ocgpu = occomp.gpu
  local mrx, mry = ocgpu.maxResolution()
  local crx, cry = ocgpu.getResolution()
  if not (resX) then
    resX = crx
  end
  if not (resY) then
    resY = cry
  end
  if resX < 1 or resX > mrx then
    resX = mrx
  end
  if resY < 1 or resY > mry then
    resY = mry
  end
  GFX.firstColor(GFX.Colors.Black, GFX.Colors.White)
  UI.DefaultStyle = UI.Style('default')
  UI.WindowManager = UI.Components.WindowManager(mrx, mry, resX, resY)
  return UI.WindowManager
end
return {
  UI = UI,
  GFX = GFX
}
