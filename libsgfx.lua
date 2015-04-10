local occomponent = require('component')
local unicode = require('unicode')
local GFX = { }
GFX.Util = { }
GFX.Util.checkUnicodeChar = function(char)
  if type(char) == 'number' then
    char = unicode.char(char)
  elseif type(char) == 'string' then
    char = char:sub(1, 1)
  end
  return char
end
GFX.MColors = {
  Black = 0x8000,
  Blue = 0x800,
  Green = 0x2000,
  Red = 0x4000,
  Cyan = 0x200,
  Purple = 0x400,
  Lime = 0x20,
  Pink = 0x40,
  Yellow = 0x10,
  White = 0x1,
  Orange = 0x2,
  Magenta = 0x4,
  LightBlue = 0x8,
  Gray = 0x80,
  LightGray = 0x100,
  Brown = 0x1000
}
GFX.SColors = {
  Black = 0x000000,
  Blue = 0x3366CC,
  Green = 0x57A64E,
  Red = 0xCC4C4C,
  Cyan = 0x4C99B2,
  Purple = 0xB266E5,
  Lime = 0x7FCC19,
  Pink = 0xF2B2CC,
  Yellow = 0xDEDE6C,
  White = 0xF0F0F0,
  Orange = 0xF2B233,
  Magenta = 0xE57FD8,
  LightBlue = 0x99B2F2,
  Gray = 0x4C4C4C,
  LightGray = 0x999999,
  Brown = 0x7F664C
}
GFX.Colors = {
  monitor = GFX.MColors,
  m = GFX.MColors,
  screen = GFX.SColors,
  s = GFX.SColors
}
do
  local _base_0 = {
    gpu = function(self, gpuproxy)
      if not (gpuproxy) then
        return self.props.gpu
      end
      if not (occomponent.type(gpuproxy.address) == 'gpu') then
        return nil
      end
      self.props.gpu = gpuproxy
    end,
    activeDisplay = function(self, displayID)
      if not (displayID) then
        return self.props.activeDisplay
      end
      if displayID >= 1 and displayID <= #self:displays() then
        self.props.activeDisplay = self:display(displayID)
        if self:displayType() == 'screen' then
          return self:gpu().bind(self:display(displayID).address)
        end
      end
    end,
    setActiveDisplayType = function(self, type)
      if not (type) then
        return false
      end
      if type == 'monitor' or type == 'screen' then
        for i, p in ipairs(self:displays()) do
          if p.type == type then
            self:activeDisplay(i)
            return true
          end
        end
      end
      return false
    end,
    display = function(self, displayID)
      return self.props.displays[displayID]
    end,
    displays = function(self)
      return self.props.displays
    end,
    displayType = function(self)
      return self:activeDisplay().type
    end,
    resolution = function(self, width, height)
      self:checkComponentAvailability()
      if not (width and height) then
        local w, h = 0, 0
        if self:displayType() == 'monitor' then
          w, h = self:activeDisplay().getSize()
        end
        if self:displayType() == 'screen' then
          w, h = self:gpu().getResolution()
        end
        return w, h
      end
      if self:displayType() == 'screen' then
        return self:gpu().setResolution(width, height)
      end
      return false, "Monitors doesn't support changing resolution"
    end,
    color = function(self, bg, fg)
      self:checkComponentAvailability()
      if bg and fg then
        if self:displayType() == 'monitor' then
          self:activeDisplay().setBackgroundColor(bg)
          return self:activeDisplay().setTextColor(fg)
        elseif self:displayType() == 'screen' then
          bg = self:gpu().setBackground(bg, false)
          fg = self:gpu().setForeground(fg, false)
          return bg, fg
        end
      else
        if self:displayType() == 'monitor' then
          return false, "You cannot obtain current color from a monitor"
        end
        return self:gpu().getBackground(), self:gpu().getForeground()
      end
    end,
    plot = function(self, x, y, char)
      self:checkComponentAvailability()
      char = GFX.Util.checkUnicodeChar(char)
      if self:displayType() == 'monitor' then
        self:activeDisplay().setCursorPos(x, y)
        return self:activeDisplay().write(char)
      elseif self:displayType() == 'screen' then
        return self:gpu().set(x, y, char, false)
      end
    end,
    set = function(self, x, y, str, vertical)
      self:checkComponentAvailability()
      if self:displayType() == 'screen' then
        return self:gpu().set(x, y, str, vertical)
      elseif self:displayType() == 'monitor' then
        if not (vertical) then
          self:activeDisplay().setCursorPos(x, y)
          return self:activeDisplay().write(str)
        else
          for i = 1, #str do
            self:activeDisplay().setCursorPos(x, (i - 1) + y)
            self:activeDisplay().write(str:sub(i, i))
          end
        end
      end
    end,
    fill = function(self, x, y, w, h, char)
      self:checkComponentAvailability()
      char = GFX.Util.checkUnicodeChar(char)
      if self:displayType() == 'screen' then
        return self:gpu().fill(x, y, w, h, char)
      elseif self:displayType() == 'monitor' then
        local line = ''
        for i = 1, w do
          line = line .. char
        end
        for i = y, y + h do
          self:activeDisplay().setCursorPos(x, i)
          self:activeDisplay().write(line)
        end
      end
    end,
    flush = function(self, stat)
      assert(occomponent.isAvailable('gpu'), 'No GPU was found.')
      assert(occomponent.isAvailable('screen') or occomponent.isAvailable('monitor'), 'No screen or monitor was found.')
      if stat then
        if stat[1] == 'component_removed' then
          if stat[3] == 'monitor' or stat[3] == 'screen' then
            local found = false
            for i, display in ipairs(self:displays()) do
              if self:proxy(i).address == occomponent.proxy(stat[2]).address then
                found = i
                break
              end
            end
            if found then
              return table.remove(self:displays(), found)
            end
          end
        elseif stat[1] == 'component_added' then
          if stat[3] == 'monitor' or stat[3] == 'screen' then
            return table.insert(self:displays(), stat[2])
          end
        end
      else
        self:gpu(occomponent.getPrimary('gpu'))
        for address, type in occomponent.list() do
          if type == 'monitor' or type == 'screen' then
            table.insert(self:displays(), occomponent.proxy(address))
          end
        end
        return self:activeDisplay(1)
      end
    end,
    checkComponentAvailability = function(self)
      assert(self:gpu(), 'No GPU has been bound. Flush the driver.')
      return assert(self:activeDisplay(), 'No active display was found.')
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      self.props = {
        gpu = nil,
        displays = { },
        activeDisplay = nil
      }
      return self:flush()
    end,
    __base = _base_0,
    __name = "Driver"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  GFX.Driver = _class_0
end
do
  local _base_0 = {
    driver = function(self, driver)
      if not (driver) then
        return self.props.driver
      end
      assert(driver, 'Given driver is invalid')
      self.props.driver = driver
    end,
    firstColor = function(self, bg, fg)
      if not (bg and fg) then
        return self.props.colorStack[1].bg, self.props.colorStack[1].fg
      end
      self.props.colorStack[1] = {
        bg = bg,
        fg = fg
      }
      return self:driver():color(bg, fg)
    end,
    pushColor = function(self, bg, fg)
      if not (bg) then
        bg = self.props.colorStack[#self.props.colorStack].bg
      end
      if not (fg) then
        fg = self.props.colorStack[#self.props.colorStack].fg
      end
      table.insert(self.props.colorStack, {
        bg = bg,
        fg = fg
      })
      return self:driver():color(bg, fg)
    end,
    popColor = function(self, times)
      if times == nil then
        times = 1
      end
      local poppedColors = { }
      local cslen
      cslen = function()
        return #self.props.colorStack
      end
      if times >= cslen() or times == 0 then
        times = cslen() - 1
      end
      for i = 1, times do
        if #self.props.colorStack > 1 then
          local last = self.props.colorStack[cslen()]
          local oldbg, oldfg = last.bg, last.fg
          table.remove(self.props.colorStack, cslen())
          last = self.props.colorStack[cslen()]
          local newbg, newfg = last.bg, last.fg
          self:driver():color(newbg, newfg)
          table.insert(poppedColors, {
            oldbg,
            oldfg,
            newbg,
            newfg
          })
        else
          table.insert(poppedColors, {
            self.props.colorStack[1].bg,
            self.props.colorStack[1].fg
          })
        end
      end
      return poppedColors
    end,
    plot = function(self, x, y, char)
      if char == nil then
        char = ' '
      end
      return self:driver():plot(x, y, char)
    end,
    drawLine = function(self, x0, y0, x1, y1, fillChar)
      if fillChar == nil then
        fillChar = ' '
      end
      local dx = math.abs(x1 - x0)
      local sx = x0 < x1 and 1 or -1
      local dy = math.abs(y1 - y0)
      local sy = y0 < y1 and 1 or -1
      local err = (dx > dy and dx or -dy) / 2
      local e2 = 0
      while true do
        self:plot(x0, y0, fillChar)
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
    end,
    drawStaticLine = function(self, x, y, len, vertical, fillChar)
      if vertical == nil then
        vertical = false
      end
      if fillChar == nil then
        fillChar = ' '
      end
      fillChar = GFX.Util.checkUnicodeChar(fillChar)
      local str = ''
      for i = 1, len do
        str = str .. fillChar
      end
      return self:driver():set(x, y, str, isVertical)
    end,
    drawText = function(self, text, x, y, w, h, valign, halign, wrap, clip, fill, hasFilledColor, fillChar)
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
      if fill then
        self:drawBox(x, y, w, h, fillChar)
        if hasFilledColor then
          self:popColor()
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
          self:driver():set(x + padding, y + (lineN - 1), lineT, false)
        end
      end
      if not (halign_draw_text) then
        for i, line in ipairs(lines) do
          self:driver():set(x, y + (i - 1), line, false)
        end
      end
    end,
    drawBox = function(self, x, y, w, h, fillChar)
      if fillChar == nil then
        fillChar = ' '
      end
      return self:driver():fill(x, y, w, h, fillChar)
    end,
    drawBorder = function(self, x, y, w, h, borderSurrounding, invertUpDownBorders, ignoreTopBottomBorders)
      if invertUpDownBorders == nil then
        invertUpDownBorders = false
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
          self:plot(x, y, tl)
          self:drawStaticLine(x + 1, y, w - 2, false, tc)
          self:plot(x + w - 1, y, tr)
        end
        local lbx, lby, lbl = x, y + 1, h - 2
        local rbx, rby, rbl = x + w - 1, y + 1, h - 2
        if ignoreTopBottomBorders then
          lby, lbl = y, h
          rby, rbl = y, h
        end
        self:drawStaticLine(lbx, lby, lbl, true, cl)
        self:drawStaticLine(rbx, rby, rbl, true, cr)
        if not (ignoreTopBottomBorders) then
          self:plot(x, y + h - 1, bl)
          self:drawStaticLine(x + 1, y + h - 1, w - 2, false, bc)
          return self:plot(x + w - 1, y + h - 1, br)
        end
      end
    end,
    clear = function(self)
      local w, h = self:driver():resolution()
      return self:drawBox(1, 1, w, h)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, driver)
      self.props = {
        driver = nil,
        colorStack = { }
      }
      self:driver(driver)
      local displayType = self:driver():displayType()
      return self:firstColor(GFX.Colors[displayType].Black, GFX.Colors[displayType].White)
    end,
    __base = _base_0,
    __name = "Context"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  GFX.Context = _class_0
end
return GFX
