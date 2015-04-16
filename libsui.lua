local SUI = { }
SUI.Util = { }
SUI.Components = { }
local ocevent = require('event')
local ocfs = require('filesystem')
local ocserialization = require('serialization')
local unicode = require('unicode')
package.loaded.json = nil
local json = require('json')
SUI.Util.tblcpy = function(tab, recursive)
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
SUI.Util.intersect = function(self, x, y, w, h, ix, Y)
  if ix >= x and ix < x + w and Y >= y and Y < y + h then
    return true
  end
  return false
end
local default_style = [[{
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
do
  local _base_0 = {
    loadStyle = function(self, style)
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
        return SUI.Util.tblcpy(self.style[component])
      end
      self.style[component] = SUI.Util.tblcpy(style)
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
  SUI.Style = _class_0
end
do
  local _base_0 = {
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
      if self:focusable() then
        if self.props.parent then
          for i, c in ipairs(self.props.parent.children) do
            c.props.focused = false
          end
        end
        self.props.focused = state
      end
    end,
    focusable = function(self, state)
      if state == nil then
        return self.props.focusable
      end
      self.props.focusable = state
    end,
    focusedComponent = function(self, component)
      if not (component) then
        return self.props.focusedComponent
      end
      if component:focusable() then
        for _, c in ipairs(self.children) do
          c:focused(false)
        end
        component:focused(true)
        self.props.focusedComponent = component
        return true
      end
      return false
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
    intersect = function(self, x, y)
      if x >= self.props.x and x < self.props.x + self.props.w and y >= self.props.y and y < self.props.y + self.props.h then
        return true
      end
      return false
    end,
    add = function(self, component)
      table.insert(self.children, component)
      component:parent(self)
      component.props.zorder = self.props.zindex
      self.props.zindex = self.props.zindex + 1
      return self:focusedComponent(component)
    end,
    remove = function(self, component)
      self:sortChildren()
      for _, c in ipairs(self.children) do
        if component:compare(c) then
          table.remove(self.children, component.props.zorder + 1)
          component.props.zorder = 0
          component.props.parent = nil
          self.props.zindex = self.props.zindex - 1
          self:sortChildren()
          component:focused(false)
          self.props.focusedComponent = nil
          for i, c in ipairs(self.children) do
            if self:focusedComponent(self.children[self.props.zindex - (i - 1)]) then
              break
            end
          end
          break
        end
      end
    end,
    bringToFront = function(self)
      if not (self:parent()) then
        return false
      end
      self:parent():sortChildren()
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
      self:parent():focusedComponent(parentChilds[bringOne])
      self:parent():sortChildren()
      return true
    end,
    sendToBack = function(self)
      self:parent():sortChildren()
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
      self.props.zorder = 0
      self:parent():sortChildren()
      for _, c in ipairs(parentChilds) do
        if self:parent():focusedComponent(c) then
          break
        end
      end
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
      return SUI.WindowManager:eventHandler(e, self)
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
        visible = true,
        id = 0,
        focused = false,
        focusable = false,
        focusedComponent = nil,
        forceReceiveEvent = false,
        epx = 0,
        epy = 0
      }
      self.children = { }
      self:style(SUI.DefaultStyle)
      if not (type == 'WindowManager') then
        self.props.id = SUI.WindowManager:cmpid()
      end
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
  SUI.Component = _class_0
end
do
  local _parent_0 = SUI.Component
  local _base_0 = {
    gfx = function(self, gctx)
      if not (gctx) then
        return self.props.WindowManager.gfx
      end
      self.props.WindowManager.gfx = gctx
    end,
    cmpid = function(self)
      self.props.WindowManager.cmpcntr = self.props.WindowManager.cmpcntr + 1
      return self.props.WindowManager.cmpcntr
    end,
    eventHandler = function(self, stuff, component)
      if type(stuff) == 'function' then
        self.props.WindowManager.eventHandler = stuff
      elseif type(stuff) == 'table' then
        if type(self.props.WindowManager.eventHandler) == 'function' then
          return self.props.WindowManager.eventHandler(component, stuff)
        end
      end
    end,
    size = function(self, w, h)
      if not (w and h) then
        return self.props.cw, self.props.ch
      end
      local mw, mh = self:gfx():driver():maxResolution()
      if w > mw or w < 1 then
        w = mw
      end
      if h > mh or h < 1 then
        h = mh
      end
      self.props.w = w
      self.props.h = h
      self.props.cw, self.props.ch = self.props.w, self.props.h
      if self:gfx():driver():resolution(w, h) then
        return true
      end
      return false
    end,
    process = function(self, timeout)
      if timeout == nil then
        timeout = 0.1
      end
      self:sortChildren()
      local e = table.pack(ocevent.pull(timeout))
      if self:visible() then
        local et = e[1]
        if et == 'key_down' or et == 'scroll' or et == 'key_up' or et == 'touch' or et == 'drag' or et == 'drop' or et == 'monitor_touch' then
          local focusedC = self:focusedComponent()
          if focusedC then
            if et ~= 'touch' and et ~= 'drag' and et ~= 'drop' and et ~= 'monitor_touch' then
              focusedC:onEvent(e)
            elseif focusedC:intersect(tonumber(e[3]), tonumber(e[4])) and (et == 'touch' or et == 'drag' or et == 'drop' or et == 'monitor_touch') then
              focusedC:onEvent(e)
            else
              for i = #self.children, 1, -1 do
                if not (focusedC:compare(self.children[i])) then
                  if self.children[i]:intersect(tonumber(e[3]), tonumber(e[4])) then
                    focusedC:focused(false)
                    focusedC = self.children[i]
                    focusedC:focused(true)
                    focusedC:bringToFront()
                    focusedC:onEvent(e)
                    break
                  end
                end
              end
            end
          else
            if et == 'touch' or et == 'drag' or et == 'drop' or et == 'monitor_touch' then
              for i = #self.children, 1, -1 do
                if self.children[i]:focusable() then
                  self.children[i]:focused(true)
                  self.children[i]:bringToFront()
                  self.children[i]:onEvent(e)
                  break
                end
              end
            end
          end
          for j, cj in ipairs(self.children) do
            if cj.props.forceReceiveEvent and cj:intersect(tonumber(e[3]), tonumber(e[4])) then
              cj:onEvent(e)
            end
          end
        end
        self:draw()
      end
      return e
    end,
    draw = function(self)
      SUI.WindowManager:gfx():pushColor(self:style().background, self:style().textcolor)
      SUI.WindowManager:gfx():drawBox(self.props.x, self.props.y, self.props.w, self.props.h)
      SUI.WindowManager:gfx():popColor()
      return self:processChildren()
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, gctx, w, h)
      if w == nil then
        w = 0
      end
      if h == nil then
        h = 0
      end
      _parent_0.__init(self, 'WindowManager', 1, 1, w, h)
      self.props.WindowManager = {
        gfx = gctx,
        cmpcntr = 0
      }
      return self:size(w, h)
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
  SUI.Components.WindowManager = _class_0
end
do
  local _parent_0 = SUI.Component
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
      SUI.WindowManager:gfx():pushColor(background, bordercolor)
      local x, y, w, h = self.props.x, self.props.y, self.props.w, self.props.h
      SUI.WindowManager:gfx():drawBox(x, y, w, h)
      if self:style().hasborder then
        SUI.WindowManager:gfx():drawBorder(x, y, w, h, self:style().borderchars, false, false)
      end
      self:reposition()
      if self:hasTitleBar() then
        SUI.WindowManager:gfx():pushColor(titlecolor, nil)
        SUI.WindowManager:gfx():drawBox(x, y, w, self:style().titleheight)
        if self:style().hasborder then
          local invertTopBottomBorders = false
          if self:style().titleheight <= 1 then
            invertTopBottomBorders = true
          end
          SUI.WindowManager:gfx():pushColor(nil, bordercolor)
          SUI.WindowManager:gfx():drawBorder(x, y, w, self:style().titleheight, self:style().titleborderchars, invertTopBottomBorders)
          SUI.WindowManager:gfx():popColor()
        end
        SUI.WindowManager:gfx():pushColor(textbgcolor, textfgcolor)
        local textpadding = self:style().textpadding
        SUI.WindowManager:gfx():drawText(self:text(), x + textpadding, y + (math.ceil(self:style().titleheight / 2) - 1), w - textpadding * 2 - (textpadding + 2), math.ceil(self:style().titleheight / 2), self:style().titlevalign, self:style().titlehalign, true, true)
        if self:hasCloseButton() then
          SUI.WindowManager:gfx():plot((self.props.x + self.props.w) - (textpadding + 2), y + (math.ceil(self:style().titleheight / 2) - 1), self:style().closeicon)
        end
        SUI.WindowManager:gfx():popColor(2)
      end
      SUI.WindowManager:gfx():popColor()
      return self:processChildren()
    end,
    onEvent = function(self, e)
      if e[1] == 'touch' or e[1] == 'scroll' or e[1] == 'monitor_touch' then
        self.props.epx = tonumber(e[3])
        self.props.epy = tonumber(e[4])
        if (e[1] == 'touch' or e[1] == 'monitor_touch') and tonumber(e[5]) == 0 and self:hasTitleBar() and self:hasCloseButton() then
          local textpadding = self:style().textpadding
          local x, y, w, h = (self.props.x + self.props.w) - (textpadding + 2), self.props.y + (math.ceil(self:style().titleheight / 2) - 1), 1, 1
          local mx, my = tonumber(e[3]), tonumber(e[4])
          if mx >= x and mx < x + w and my >= y and my < y + h then
            SUI.WindowManager:gfx():pushColor(self:style().titleclickbg, self:style().titleclickfg)
            SUI.WindowManager:gfx():plot((self.props.x + self.props.w) - (textpadding + 2), self.props.y + (math.ceil(self:style().titleheight / 2) - 1), self:style().closeicon)
            SUI.WindowManager:gfx():popColor()
            os.sleep(self:style().closedelay)
            self:parent():remove(self)
            local ce = {
              'window_closed'
            }
            SUI.WindowManager:eventHandler(ce, self)
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
    __init = function(self, text, x, y, w, h, hasTitleBar, hasCloseButton)
      if text == nil then
        text = ''
      end
      if x == nil then
        x = 1
      end
      if y == nil then
        y = 1
      end
      if w == nil then
        w = 1
      end
      if h == nil then
        h = 1
      end
      if hasTitleBar == nil then
        hasTitleBar = true
      end
      if hasCloseButton == nil then
        hasCloseButton = true
      end
      _parent_0.__init(self, 'Window', x, y, w, h, text)
      self.props.Window = {
        hasTitleBar = hasTitleBar,
        movable = hasTitleBar,
        hasCloseButton = hasCloseButton,
        beignDragged = false
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
  SUI.Components.Window = _class_0
end
do
  local _parent_0 = SUI.Component
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
      SUI.WindowManager:gfx():pushColor(self.props.Box.bg, self.props.Box.fg)
      SUI.WindowManager:gfx():drawBox(self.props.x, self.props.y, self.props.w, self.props.h, self:fillChar())
      if self:style().hasborder then
        SUI.WindowManager:gfx():drawBorder(self.props.x, self.props.y, self.props.w, self.props.h, self:style().borderchars)
      end
      return SUI.WindowManager:gfx():popColor()
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, bg, fg, x, y, w, h, fillChar)
      if x == nil then
        x = 1
      end
      if y == nil then
        y = 1
      end
      if w == nil then
        w = 1
      end
      if h == nil then
        h = 1
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
  SUI.Components.Box = _class_0
end
do
  local _parent_0 = SUI.Component
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
      SUI.WindowManager:gfx():pushColor(self:style().background, self:style().textcolor)
      SUI.WindowManager:gfx():drawText(self:text(), self.props.x, self.props.y, self.props.w, self.props.h, self.props.Label.valign, self.props.Label.halign, self.props.Label.wrap, self.props.Label.clip, self:style().background)
      return SUI.WindowManager:gfx():popColor()
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
  SUI.Components.Label = _class_0
end
do
  local _parent_0 = SUI.Component
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
      SUI.WindowManager:gfx():pushColor(bg, fg)
      if self:style().hasborder then
        SUI.WindowManager:gfx():drawBorder(self.props.x, self.props.y, self.props.w, self.props.h, self:style().borderchars, false, itbb)
      end
      SUI.WindowManager:gfx():drawText(self:text(), self.props.x + padding, self.props.y, self.props.w - padding * 2, self.props.h, self:style().textvalign, self:style().texthalign, true, true, self:style().background)
      return SUI.WindowManager:gfx():popColor()
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
        x = 1
      end
      if y == nil then
        y = 1
      end
      if w == nil then
        w = 1
      end
      if h == nil then
        h = 1
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
  SUI.Components.Button = _class_0
end
do
  local _parent_0 = SUI.Component
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
      SUI.WindowManager:gfx():pushColor(bg, fg)
      if self:style().hasborder then
        SUI.WindowManager:gfx():drawBorder(self.props.x, self.props.y, self.props.w, self.props.h, self:style().borderchars, false, itbb)
      end
      SUI.WindowManager:gfx():drawText(self:text(), self.props.x + padding, self.props.y, self.props.w - padding * 2, self.props.h, self:style().textvalign, self:style().texthalign, true, true, self:style().background)
      return SUI.WindowManager:gfx():popColor()
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
        x = 1
      end
      if y == nil then
        y = 1
      end
      if w == nil then
        w = 1
      end
      if h == nil then
        h = 1
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
  SUI.Components.Toggle = _class_0
end
do
  local _parent_0 = SUI.Component
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
      SUI.WindowManager:gfx():pushColor(self:style().background, self:style().textcolor)
      SUI.WindowManager:gfx():drawBox(self.props.x, self.props.y, self.props.w, self.props.h, self:style().emptychar)
      SUI.WindowManager:gfx():pushColor(self:style().prgbackground, self:style().prgtextcolor)
      local sx, sy, sw, sh = self.props.x, self.props.y, self.props.w, self.props.h
      if self:style().hasborder then
        sx = sx + 1
        sy = sy + 1
        sw = sw - 2
        sh = sh - 2
      end
      if self:progress() > 0 then
        if self:direction() == 'hor' then
          SUI.WindowManager:gfx():drawBox(sx, sy, math.floor(sw * self:progress()), sh, self:style().prgchar)
        else
          local progress = math.floor(sh * self:progress())
          SUI.WindowManager:gfx():drawBox(sx, (sy + (sh - progress)), sw, progress, self:style().prgchar)
        end
      end
      if self:style().hasborder then
        SUI.WindowManager:gfx():drawBorder(self.props.x, self.props.y, self.props.w, self.props.h, self:style().borderchars)
      end
      return SUI.WindowManager:gfx():popColor(2)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, x, y, w, h, direction)
      if x == nil then
        x = 1
      end
      if y == nil then
        y = 1
      end
      if w == nil then
        w = 1
      end
      if h == nil then
        h = 1
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
  SUI.Components.Progress = _class_0
end
do
  local _parent_0 = SUI.Component
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Tabs",
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
  SUI.Components.Tabs = _class_0
end
do
  local _parent_0 = SUI.Component
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Panel",
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
  SUI.Components.Panel = _class_0
end
do
  local _parent_0 = SUI.Component
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Modal",
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
  SUI.Components.Modal = _class_0
end
do
  local _parent_0 = SUI.Component
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Layout",
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
  SUI.Components.Layout = _class_0
end
do
  local _parent_0 = SUI.Component
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Scroller",
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
  SUI.Components.Scroller = _class_0
end
do
  local _parent_0 = SUI.Component
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
  SUI.Components.List = _class_0
end
do
  local _parent_0 = SUI.Component
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
  SUI.Components.Spinner = _class_0
end
do
  local _parent_0 = SUI.Component
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
  SUI.Components.Checkbox = _class_0
end
do
  local _parent_0 = SUI.Component
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
  SUI.Components.Radiobox = _class_0
end
do
  local _parent_0 = SUI.Component
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
  SUI.Components.Editbox = _class_0
end
SUI.init = function(gctx)
  if gctx then
    SUI.DefaultStyle = SUI.Style('default')
    SUI.WindowManager = SUI.Components.WindowManager(gctx)
    return SUI.WindowManager
  end
  return nil
end
return SUI
