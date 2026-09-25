-- Foundry UI: a small immediate-mode UI toolkit for Love2D 11.x.
-- Use as `local UI = require("comp.ui")` or copy it into another LÖVE project.

local UI = {}
UI.__index = UI
local utf8 = require("utf8")

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
local function inside(x, y, r) return x >= r.x and y >= r.y and x <= r.x + r.w and y <= r.y + r.h end
local function rgba(hex)
  assert(type(hex) == "string", "color must be a hex string")
  hex = hex:gsub("#", "")
  assert((#hex == 6 or #hex == 8) and not hex:find("[^%x]"), "color must be RRGGBB or RRGGBBAA")
  return {tonumber(hex:sub(1,2),16)/255, tonumber(hex:sub(3,4),16)/255,
          tonumber(hex:sub(5,6),16)/255, (#hex >= 8 and tonumber(hex:sub(7,8),16)/255 or 1)}
end

local function color(value)
  if type(value)=="string" then return rgba(value) end
  assert(type(value)=="table" and type(value[1])=="number" and type(value[2])=="number" and type(value[3])=="number", "color must be a hex string or RGB(A) table")
  return {value[1],value[2],value[3],value[4] or 1}
end

UI.colors = {
  bg = rgba("#101714"), panel = rgba("#18211D"), raised = rgba("#202C27"), hover = rgba("#293832"),
  line = rgba("#34463E"), text = rgba("#EEF5E9"), muted = rgba("#91A097"), accent = rgba("#E7B35A"),
  accentDark = rgba("#694E24"), green = rgba("#77B983"), red = rgba("#D8756D"), shadow = rgba("#050806B0")
}

function UI.new(theme)
  assert(theme==nil or type(theme)=="table", "theme must be a table")
  local self = setmetatable({}, UI)
  self.theme = {}
  for k,v in pairs(UI.colors) do self.theme[k] = v end
  for k,v in pairs(theme or {}) do self.theme[k] = color(v) end
  self.hot, self.active, self.focused = nil, nil, nil
  self.mx, self.my, self.pressed, self.released, self.pressPositions = 0, 0, {}, {}, {}
  self.scrollY, self.textInput, self.pasteText, self.keyEvents = 0, "", "", {}
  self.tooltip, self.menu = nil, nil
  self.fonts = {}
  return self
end

function UI:load(fonts)
  fonts=fonts or {}
  self.fonts.body = fonts.body or love.graphics.newFont(14)
  self.fonts.small = fonts.small or love.graphics.newFont(12)
  self.fonts.label = fonts.label or love.graphics.newFont(13)
  self.fonts.title = fonts.title or love.graphics.newFont(22)
  self.fonts.big = fonts.big or love.graphics.newFont(30)
  for _, f in pairs(self.fonts) do f:setFilter("linear", "linear") end
end

function UI:setColor(c, a)
  love.graphics.setColor(c[1], c[2], c[3], (c[4] or 1) * (a or 1))
end

function UI:rect(r, color, radius, mode)
  self:setColor(color)
  love.graphics.rectangle(mode or "fill", r.x, r.y, r.w, r.h, radius or 0, radius or 0)
end

function UI:beginFrame()
  self.mx, self.my = love.mouse.getPosition()
  self.hot, self.tooltip = nil, nil
  self._focusClaimed = false
end

function UI:endFrame()
  if self.menu then self:drawMenu() end
  if self.tooltip and not self.menu then self:drawTooltip(self.tooltip) end
  if self.pressed[1] and not self._focusClaimed then self.focused = nil end
  if self.released[1] then self.active, self._menuActive = nil, nil end
  self.pressed, self.released, self.pressPositions, self.scrollY, self.textInput, self.pasteText, self.keyEvents = {}, {}, {}, 0, "", "", {}
end

function UI:mousepressed(x, y, button)
  self.pressed[button] = true
  self.pressPositions[button] = {x=x, y=y}
  if self.menu and not inside(x, y, self.menu.bounds or {x=-1,y=-1,w=0,h=0}) then self:closeMenu() end
end
function UI:mousereleased(_, _, button) self.released[button] = true end
function UI:wheelmoved(_, y) self.scrollY = self.scrollY + y end
function UI:textinput(t) self.textInput = self.textInput .. t end
function UI:keypressed(k)
  self.keyEvents[#self.keyEvents+1] = k
  local keyboard = love.keyboard
  local shortcut = keyboard and keyboard.isDown and (keyboard.isDown("lctrl") or keyboard.isDown("rctrl") or keyboard.isDown("lgui") or keyboard.isDown("rgui"))
  if k == "v" and shortcut and love.system and love.system.getClipboardText then
    local text = love.system.getClipboardText()
    if type(text) == "string" then self.pasteText = self.pasteText .. text:gsub("[\r\n]+", " ") end
  end
end

function UI:isHover(id, r)
  if inside(self.mx, self.my, r) and not self.menu then self.hot = id; return true end
  return false
end

function UI:button(id, r, label, opts)
  opts = opts or {}
  local hover = not opts.disabled and self:isHover(id, r)
  if hover and opts.tooltip then self.tooltip = {text=opts.tooltip, x=self.mx, y=self.my} end
  local press = self.pressPositions[1]
  if not opts.disabled and self.pressed[1] and press and inside(press.x, press.y, r) then self.active = id end
  local clicked = (not opts.disabled and hover and self.released[1] and self.active == id) == true
  local bg = opts.selected and self.theme.accentDark or (hover and self.theme.hover or self.theme.raised)
  self:rect(r, bg, opts.radius or 7)
  if opts.selected then
    self:setColor(self.theme.accent); love.graphics.rectangle("fill", r.x, r.y, 3, r.h, 2, 2)
  end
  if opts.outline then self:setColor(self.theme.line); love.graphics.rectangle("line", r.x+.5,r.y+.5,r.w-1,r.h-1,opts.radius or 7) end
  love.graphics.setFont(opts.font or self.fonts.label)
  self:setColor(opts.disabled and self.theme.muted or (opts.selected and self.theme.accent or self.theme.text), opts.disabled and .45 or 1)
  love.graphics.printf(label, r.x + (opts.pad or 10), r.y + (r.h-love.graphics.getFont():getHeight())/2, r.w-2*(opts.pad or 10), opts.align or "center")
  return clicked, hover
end

function UI:iconButton(id, r, icon, opts)
  local iconOpts = {}
  for k,v in pairs(opts or {}) do iconOpts[k] = v end
  iconOpts.font, iconOpts.pad = self.fonts.body, 0
  return self:button(id, r, icon, iconOpts)
end

function UI:input(id, r, value, placeholder)
  value, placeholder = tostring(value or ""), tostring(placeholder or "")
  local hover = self:isHover(id, r)
  local press = self.pressPositions[1]
  if self.pressed[1] and press and inside(press.x, press.y, r) then
    self.focused, self._focusClaimed = id, true
  end
  local focused = self.focused == id
  if focused then
    value = value .. self.textInput .. self.pasteText
    for _, k in ipairs(self.keyEvents) do
      if k == "backspace" then
        local p = utf8.offset(value, -1); if p then value = value:sub(1,p-1) end
      elseif k == "escape" or k == "return" then self.focused = nil end
    end
  end
  self:rect(r, self.theme.bg, 7)
  self:setColor(focused and self.theme.accent or self.theme.line)
  love.graphics.rectangle("line", r.x+.5,r.y+.5,r.w-1,r.h-1,7,7)
  love.graphics.setFont(self.fonts.body)
  self:setColor(value == "" and self.theme.muted or self.theme.text)
  local display = value == "" and placeholder or value
  local sx,sy,sw,sh = love.graphics.getScissor()
  love.graphics.intersectScissor(r.x+1,r.y+1,r.w-2,r.h-2)
  love.graphics.print(display, r.x+34, r.y+(r.h-self.fonts.body:getHeight())/2)
  self:setColor(self.theme.muted); love.graphics.circle("line",r.x+16,r.y+r.h/2-2,5); love.graphics.line(r.x+20,r.y+r.h/2+2,r.x+24,r.y+r.h/2+6)
  if focused and math.floor(love.timer.getTime()*2)%2 == 0 then
    local tx = r.x+34+self.fonts.body:getWidth(value); self:setColor(self.theme.accent); love.graphics.line(tx,r.y+9,tx,r.y+r.h-9)
  end
  if sx then love.graphics.setScissor(sx,sy,sw,sh) else love.graphics.setScissor() end
  return value
end

function UI:badge(r, text, color)
  color = color or self.theme.accent
  self:setColor(color, .16); love.graphics.rectangle("fill",r.x,r.y,r.w,r.h,r.h/2,r.h/2)
  self:setColor(color); love.graphics.setFont(self.fonts.small)
  love.graphics.printf(text,r.x,r.y+(r.h-self.fonts.small:getHeight())/2,r.w,"center")
end

function UI:progress(r, value, color)
  value = clamp(value,0,1); self:rect(r,self.theme.bg,r.h/2)
  if value > 0 then self:rect({x=r.x,y=r.y,w=r.w*value,h=r.h},color or self.theme.green,r.h/2) end
end

function UI:scrollArea(id, r, contentHeight, draw)
  assert(type(draw)=="function", "scrollArea requires a draw callback")
  self._scrolls = self._scrolls or {}; local max = math.max(0,contentHeight-r.h)
  local pos = clamp(self._scrolls[id] or 0,0,max)
  if inside(self.mx,self.my,r) and self.scrollY ~= 0 then pos = clamp(pos-self.scrollY*36,0,max) end
  self._scrolls[id] = pos
  local sx,sy,sw,sh = love.graphics.getScissor()
  love.graphics.intersectScissor(r.x,r.y,r.w,r.h)
  local ok,reason=pcall(draw,pos)
  if sx then love.graphics.setScissor(sx,sy,sw,sh) else love.graphics.setScissor() end
  if not ok then error(reason,0) end
  if max > 0 then
    local th = math.max(34,r.h*(r.h/contentHeight)); local ty=r.y+(r.h-th)*(pos/max)
    self:rect({x=r.x+r.w-4,y=ty,w=3,h=th},self.theme.line,2)
  end
end

function UI:openMenu(x, y, items)
  assert(type(x)=="number" and type(y)=="number", "menu position must be numeric")
  assert(type(items)=="table", "menu items must be a table")
  for i,item in ipairs(items) do
    assert(type(item)=="table" and type(item.label)=="string", "menu item "..i.." requires a label")
    assert(item.action==nil or type(item.action)=="function", "menu item action must be a function")
  end
  local menu={x=x,y=y,items=items,w=204,row=38}
  menu.bounds={x=x,y=y,w=menu.w,h=#items*menu.row+12}
  self.menu=menu
  return menu
end

function UI:closeMenu() self.menu=nil; self._menuActive=nil end

function UI:drawMenu()
  local m=self.menu; local h=#m.items*m.row+12
  local sw,sh=love.graphics.getDimensions(); m.x=clamp(m.x,10,math.max(10,sw-m.w-10)); m.y=clamp(m.y,10,math.max(10,sh-h-10))
  m.bounds={x=m.x,y=m.y,w=m.w,h=h}
  self:rect({x=m.x+5,y=m.y+7,w=m.w,h=h},self.theme.shadow,9)
  self:rect(m.bounds,self.theme.raised,9); self:setColor(self.theme.line); love.graphics.rectangle("line",m.x+.5,m.y+.5,m.w-1,h-1,9,9)
  for i,item in ipairs(m.items) do
    local r={x=m.x+6,y=m.y+6+(i-1)*m.row,w=m.w-12,h=m.row}
    local hover=inside(self.mx,self.my,r) and not item.disabled
    local press=self.pressPositions[1]
    if not item.disabled and self.pressed[1] and press and inside(press.x,press.y,r) then self._menuActive=item end
    if hover then self:rect(r,self.theme.hover,6) end
    self:setColor(item.danger and self.theme.red or (item.disabled and self.theme.muted or self.theme.text),item.disabled and .45 or 1)
    love.graphics.setFont(self.fonts.body); love.graphics.print(item.icon or "",r.x+10,r.y+11); love.graphics.print(item.label,r.x+36,r.y+10)
    if hover and self.released[1] and self._menuActive==item then
      local action=item.action
      self:closeMenu()
      if action then action() end
      return
    end
  end
end

function UI:drawTooltip(t)
  love.graphics.setFont(self.fonts.small); local w=math.min(260,self.fonts.small:getWidth(t.text)+20); local h=30
  local sw,sh=love.graphics.getDimensions(); local x=clamp(t.x+14,8,math.max(8,sw-w-8)); local y=clamp(t.y+18,8,math.max(8,sh-h-8))
  self:rect({x=x,y=y,w=w,h=h},self.theme.bg,6); self:setColor(self.theme.line); love.graphics.rectangle("line",x+.5,y+.5,w-1,h-1,6,6)
  self:setColor(self.theme.text); love.graphics.printf(t.text,x+10,y+7,w-20,"left")
end

return UI
