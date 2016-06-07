-- 
-- LoveTerm - simple 1-bit tiled graphics for Love2d
--
-- Written in 2016 by Mina Phoebe Bell minaphoebebell@gmail.com
--
-- To the extent possible under law, the author(s) have dedicated all copyright
-- and related and neighboring rights to this software to the public domain
-- worldwide. This software is distributed without any warranty.
--
-- You should have received a copy of the CC0 Public Domain Dedication along 
-- with this software. If not, see 
--      <http://creativecommons.org/publicdomain/zero/1.0/>. 
--

-- @tfield[opt=0] int currentLine the line to start drawing
-- @tfield[opt=true] bool visible set to false to hide the canvas


--- LoveTerm - simple 1-bit tiled graphics for Love2d
--
-- Full example: @{main.lua}
-- @module loveterm
-- @author Mina Phoebe Bell
-- @license CC0

local loveterm = {}

--- @usage
local usage = [[
local loveterm = require "loveterm"
local codes = require "extra/cp437"
local color = require "extra/color"

function love.load()
  screen = loveterm.create("tilesets/CGA8x8thick.png", 80, 40)
  screen:print(
      screen.wrapString(
          "LoveTerm is a small library for drawing 1-bit " .. 
          "tiled graphics, such as terminal emulators.",
          21),
      5, 5)
  screen:set(codes.heart, color.c64.pink, screen.defaultbg, 3, 5)
end

function love.draw()
  screen:draw()
end
]]

--- Create and initialize a new loveterm object.
-- @string tileset a string of the location of the tileset image
-- @int width the maximum number of tiles displayed on the x-axis
-- @int height the maximum number of tiles displayed on the y-axis
-- @tparam[opt=white] Color fg the default foreground color
-- @tparam[opt=black] Color bg the default background color
-- @int[opt=16] tilesetWidth the width of the tileset image in tiles
-- @int[opt=16] tilesetHeight the height of the tileset image in tiles
-- @return a new loveterm object
function loveterm.create(tileset, width, height, fg, bg, tilesetWidth, tilesetHeight)
  local s = {}
  s.width = width
  s.height = height
  s.defaultfg = fg or { 255, 255, 255 }
  s.defaultbg = bg or { 0, 0, 0 }
  s.values = {}
  s.fg = {}
  s.bg = {}
  s.currentLine = 0

  s.visible = true
  s.modifiedDraw = false

  s.tileset = love.graphics.newImage(tileset)
  s.tilesetWidth = tilesetWidth or 16
  s.tilesetHeight  = tilesetHeight or 16
  s.tileWidth = s.tileset:getWidth()/s.tilesetWidth
  s.tileHeight = s.tileset:getHeight()/s.tilesetHeight
  s.tilesetQuads = {}
  for i = 0, 255 do
    s.tilesetQuads[i] = love.graphics.newQuad(
        (i%16) * s.tileWidth,
        math.floor(i/16) * s.tileHeight,
        s.tileWidth,
        s.tileHeight,
        s.tileset:getWidth(),
        s.tileset:getHeight())
  end
  s.canvas = love.graphics.newCanvas(
      s.width * s.tileWidth, s.height * s.tileHeight)
  -- Used for drawin images to the screen.
  s.tempCanvas = love.graphics.newCanvas(s.width, s.height)

  setmetatable(s, { __index = loveterm })
  return s
end

--- Draw the canvas at x, y.
-- @function draw
-- @method
-- @int[opt=0] x the x coordinate in pixels
-- @int[opt=0] y the y coordinate in pixels
-- @bool[opt=false] force flush the loveterm object no matter what
function loveterm:draw(x, y, force)
  if self.modifiedDraw or force then
    self:flush()
  end

  if self.visible then
    x = x or 0
    y = y or 0
    love.graphics.draw(self.canvas, x, y)
  end
end

--- Render to the canvas.
-- @method
function loveterm:flush()
  self.modifiedDraw = false
  love.graphics.setCanvas(self.canvas)
  local start = self.currentLine * self.width
  for i = start, self.width * self.height - 1 + start do
    love.graphics.setColor(self.bg[i] or self.defaultbg)
    love.graphics.rectangle(
        "fill", 
        (i % self.width) * self.tileWidth, 
        math.floor((i - start) / self.width) * self.tileHeight,
        self.tileWidth, 
        self.tileHeight)
    love.graphics.setColor(self.fg[i] or self.defaultfg)
    love.graphics.draw(
        self.tileset,
        self.tilesetQuads[self.values[i] or 0], 
        (i % self.width) * self.tileWidth, 
        math.floor((i - start) / self.width) * self.tileHeight)
  end
  love.graphics.setColor(255, 255, 255)
  love.graphics.setCanvas()
end

--- Set the character at coordinates x, y to be v.
-- @method
-- @int v the tile number
-- @int x the x coordinate of the cell to be set
-- @int[opt=0] y the y coordinate of the cell to be set
-- @usage screen:setValue(1, 5, 2)
-- @usage for i = 0, screen.width * screen.height - 1 do
--   screen:setValue(1, i)
-- end
function loveterm:setValue(v, x, y)
  y = y or 0
  self.values[x + y * self.width] = v
  self:makeModified()
end

local function map(a, fun)
  for i = 1, #a do
    a[i] = fun(a[i])
  end
  return a
end

local function blendColors(c1, c2)
  local alpha = (c2[4] or 255)/255
  local r = math.floor(c1[1] * (1 - alpha) + c2[1] * alpha)
  local g = math.floor(c1[2] * (1 - alpha) + c2[2] * alpha)
  local b = math.floor(c1[3] * (1 - alpha) + c2[3] * alpha)
  local a = math.floor((c1[4] or 255) * (1 - alpha) + 255 * alpha)
  return { r, g, b, a }
end

--- Set the foreground color at coordinates x, y to be fg.
-- @method
-- @tparam Color fg the new foreground color
-- @int x the x coordinate of the cell to be set
-- @int[opt=0] y the y coordinate of the cell to be set
function loveterm:setfg(fg, x, y)
  y = y or 0
  local index = x + y * self.width
  local oldfg = self.fg[index] or self.defaultfg
  self.fg[index] = blendColors(oldfg, fg)
  self:makeModified()
end

--- Set the background color at coordinates x, y to be bg.
-- @method
-- @tparam Color bg the new background color
-- @int[opt=0] x the x coordinate of the cell to be set
-- @int[opt=0] y the y coordinate of the cell to be set
function loveterm:setbg(bg, x, y)
  y = y or 0
  local index = x + y * self.width
  local oldbg = self.bg[index] or self.defaultbg
  self.bg[index] = blendColors(oldbg, bg)
  self:makeModified()
end

--- Set the foreground and background colors at coordinates x, y to be fg, bg.
-- @method
-- @tparam Color fg the new foreground color
-- @tparam Color bg the new background color
-- @int[opt=0] x the x coordinate of the cell to be set
-- @int[opt=0] y the y coordinate of the cell to be set
function loveterm:setColor(fg, bg, x, y)
  y = y or 0
  self:setfg(fg, x, y)
  self:setbg(bg, x, y)
  self:makeModified()
end

--- Set the character, foreground and background colors at coordinates x, y to be v, fg and bg.
-- @method
-- @int v the tile number
-- @tparam Color fg the new foreground color
-- @tparam Color bg the new background color
-- @int[opt=0] x the x coordinate of the cell to be set
-- @int[opt=0] y the y coordinate of the cell to be set
function loveterm:set(v, fg, bg, x, y)
  y = y or 0
  self:setValue(v, x, y)
  self:setfg(fg, x, y)
  self:setbg(bg, x, y)
  self:makeModified()
end

--- Flip the `modifiedDraw` flag so that the screen is rerendered next time `draw` is called.
-- @local
-- @method
function loveterm:makeModified()
  self.modifiedDraw = true
end

--- Empty the screen back to the default background color.
-- @method
function loveterm:clear()
  local offset = self.currentLine * self.width
  for i = offset, self.width * self.height - 1 + offset do
    self.bg[i] = nil
    self.fg[i] = nil
    self.values[i] = nil
  end
end

--- Get the number of the line at the top of the screen.
-- @method
-- @treturn int the current line
function loveterm:getCurrentLine()
  return self.currentLine
end

--- Set the current line number. This is useful for scrolling.
-- @method
-- @int lineNumber the new line number
function loveterm:setCurrentLine(lineNumber)
  self.currentLine = lineNumber
  self:makeModified()
end

--- Check if it is visible.
-- @method
-- @treturn bool
function loveterm:is_visible()
  return self.visible
end

--- Set whether or not it is visible.
--
-- Not visible objects aren't drawn when called with @{draw}.
-- @method
-- @bool[opt=true] is_visible use false to hide it
function loveterm:setVisible(is_visible)
  is_visible = is_visible or true
  self.visible = is_visible
end

--- Adds a rectangle to the screen.
--
-- The `options` table has the fields `fg` and `bg` to set the colors, as
-- well as `topLeft`, `topRight`, `bottomLeft`, `bottomRight`,
-- `vertical`, and `horizontal` to set the various components of the
-- rectangle when mode is set to `line`. `options` also has a `fill`
-- field to set which character is drawn when mode is `fill`.
-- @method
-- @param mode can either be "fill" or "line"
-- @int x
-- @int y
-- @int w the width of the rectangle in cells
-- @int h the height of the rectangle in cells
-- @tparam table options
function loveterm:rectangle(mode, x, y, w, h, options)
  assert(mode == "fill" or mode == "line", "Unknown mode: " .. tostring(mode))
  options = options or {}
  local fg = options.fg or self.defaultfg
  local bg = options.bg or self.defaultbg
  local topLeft = options.topLeft or 218
  local topRight = options.topRight or 191
  local bottomLeft = options.bottomLeft or 192
  local bottomRight = options.bottomRight or 217
  local vertical = options.vertical or 179
  local horizontal = options.horizontal or 196
  local fill = options.fill or 219
  
  for ny = y, y + h do
    for nx = x, x + w do
      if mode == "line" then
        if ny == y and nx == x then
          self:set(topLeft, fg, bg, nx, ny)
        elseif ny == y and nx == x + w then
          self:set(topRight, fg, bg, nx, ny)
        elseif ny == y + h and nx == x then
          self:set(bottomLeft, fg, bg, nx, ny)
        elseif ny == y + h and nx == x + w  then
          self:set(bottomRight, fg, bg, nx, ny)
        elseif ny == y or ny == y + h then
          self:set(horizontal, fg, bg, nx, ny)
        elseif nx == x or nx == x + w then
          self:set(vertical, fg, bg, nx, ny)
        end
      elseif mode == "fill" then
        self:set(fill, fg, bg, nx, ny)
      else
        error("Mode must be either 'line' or 'fill'", 2)
      end
    end
  end
end

--- Adds a line from (x1, y1) to (x2, y2) on the screen.
--  @method
--  @int x1
--  @int y1
--  @int x2
--  @int y2
--  @tparam Color fg the foreground color
--  @tparam Color bg the background color
--  @int v the index of the tile you want to have drawn
function loveterm:line(x1, y1, x2, y2, fg, bg, v)
  fg = fg or self.defaultfg
  bg = bg or self.defaultbg
  v = v or 219

  local function plotfn(screen, x, y)
    loveterm.set(screen, v, fg, bg, x, y)
  end

  loveterm.bresenham(nil, plotfn, x1, y1, x2, y2)
end

--- Plots a line from (x1, y1) to (x2, y2) on map using a function
--
-- See the source code of @{line} for an example of use.
-- @param map passed as the first argument to `plotfn`
-- @tparam function(map,x,y) plotfn called every time a point is plotted
-- @int x1
-- @int y1
-- @int x2
-- @int y2
function loveterm.bresenham(map, plotfn, x1, y1, x2, y2)
  local delta_x = x2 - x1
  local ix = delta_x > 0 and 1 or -1
  delta_x = 2 * math.abs(delta_x)

  local delta_y = y2 - y1
  local iy = delta_y > 0 and 1 or -1
  delta_y = 2 * math.abs(delta_y)

  plotfn(map, x1, y1)

  if delta_x >= delta_y then
    local error = delta_y - delta_x / 2

    while x1 ~= x2 do
      if (error >= 0) and ((error ~= 0) or (ix > 0)) then
        error = error - delta_x
        y1 = y1 + iy
      end

      error = error + delta_y
      x1 = x1 + ix

      plotfn(map, x1, y1)
    end
  else
    local error = delta_x - delta_y / 2

    while y1 ~= y2 do
      if (error >= 0) and ((error ~= 0) or (iy > 0)) then
        error = error - delta_y
        x1 = x1 + ix
      end

      error = error + delta_x
      y1 = y1 + iy

      plotfn(map, x1, y1)
    end
  end
end

--- Draw an image to the screen.
--
-- The options table can include `setfg` (default: false), `setbg` (default: true),
-- `filter` (default: "linear", other possible setting is "nearest"), or `alpha`
-- (default: 255), which is the alpha to draw the image with.
-- @method
-- @tparam Drawable drawable a love2d drawable object, such as an image or canvas
-- @tparam[opt={}] table options the options table
-- @int[opt=0] x the x coordinate of the screen to start drawing on
-- @int[opt=0] y the y coordinate of the screen to start drawing on
-- @int[opt=0] r orientation in radians
-- @int[opt=1] sx scale-factor (x-axis)
-- @int[opt=sx] sy scale-factor (y-axis)
-- @int[opt=0] ox origin offset (x-axis)
-- @int[opt=0] oy origin offset (y-axis)
-- @int[opt=0] kx shearing factor (x-axis)
-- @int[opt=0] ky shearing factor (y-axis)
function loveterm:drawImage(drawable, options, x, y, r, sx, sy, ox, oy, kx, ky)
  x = x or 0
  y = y or 0
  r = r or 0
  sx = sx or 1
  sy = sy or sx
  ox = ox or 0
  oy = oy or 0
  kx = kx or 0
  ky = ky or 0
  options = options or {}
  local setfg = options.setfg or false
  local setbg = options.setbg or true
  local filter = options.filter or "linear"
  local alpha = options.alpha or 255

  self.tempCanvas:setFilter(filter, filter)
  love.graphics.setCanvas(self.tempCanvas)
  love.graphics.clear()
  love.graphics.draw(drawable, x, y, r, sx, sy, ox, oy, kx, ky)
  love.graphics.setCanvas()

  local image = self.tempCanvas:newImageData()
  for ny = 0, image:getHeight()-1 do
    for nx = 0, image:getWidth()-1 do
      local r, g, b, a = image:getPixel(nx, ny)
      a = math.floor((a or 255) * alpha/255)
      if setfg then
        self:setfg({r, g, b, a}, nx, ny)
      end
      
      if setbg then
        self:setbg({r, g, b, a}, nx, ny)
      end
    end
  end
end

--- Print a plaintext string to the screen.
--
-- Can also take two colored text of the form
-- { fgcolor1, bgcolor1, string1, fgcolor2, ... }
-- @method
-- @param s the string or two colored text to be printed
-- @int[opt=0] x
-- @int[opt=0] y
function loveterm:print(s, x, y)
  if type(s) == "string" then
    s = { self.defaultfg, self.defaultbg, s }
  end
  x = x or 0
  y = y or 0
  local offset = 0
  for i = 1, #s, 3 do
    local bytes = { s[i+2]:byte(1, -1) }
    for _,v in ipairs(bytes) do
      if v == 10 then -- 10 is a newline character ('\n')
        y = y + 1
        offset = 0
      else
        self:set(v, s[i], s[i+1], x + offset, y)
        offset = offset + 1
      end
    end
  end
end

--- Format and print a plaintext string to the screen.
-- @method
-- @string s the string to be printed
-- @int[opt=0] x
-- @int[opt=0] y
-- @int[opt=78] width the maximum line width
-- @string[opt="left"] align can be `"left"`, `"right"`, or `"center"`
function loveterm:printf(s, x, y, width, align)
  self:print(self.wrapString(s, width, align), x, y)
end

local function stripTrailingSpace(s)
  while s ~= "" and s:sub(s:len()) == " " do
    s = s:sub(1, -2)
  end
  return s
end

local function flushRight(text, width)
  local acc = ""
  local function iter()
    local iter_i = 1
    return function()
      if iter_i <= text:len() then
        local newlines = text:match("^\n+", iter_i)
        if newlines then
          acc = acc .. newlines
          iter_i = iter_i + newlines:len()
        end
        local result = text:match("^[^\n]+", iter_i)
        iter_i = iter_i + result:len()
        return result
      end
    end
  end
  for line in iter() do
    line = stripTrailingSpace(line)

    for _ = 1, width - line:len() do
      acc = acc .. " "
    end
    acc = acc .. line
  end
  return acc
end

local function centerText(text, width)
  local acc = ""
  local function iter()
    local iter_i = 1
    return function()
      if iter_i <= text:len() then
        local newlines = text:match("^\n+", iter_i)
        if newlines then
          acc = acc .. newlines
          iter_i = iter_i + newlines:len()
        end
        local result = text:match("^[^\n]+", iter_i)
        iter_i = iter_i + result:len()
        return result
      end
    end
  end
  for line in iter() do
    line = stripTrailingSpace(line)

    local extraspace = width - line:len()
    for _ = 1, math.floor(extraspace/2) do
      acc = acc .. " "
    end
    acc = acc .. line
  end
  return acc
end

--- Wrap a string according to a certain width.
-- @string s
-- @int[opt=78] width the maximum line width
-- @string[opt="left"] align the alignment of the text. Can be `"left"`, `"right"`, or `"center"`.
-- @treturn string the string with added newlines
function loveterm.wrapString(s, width, align)
  assert(type(s) == "string", "The first argument of wrapString needs to " ..
      "be a string. Did you accidentally call it using a colon?")
  width = width or 78
  align = align or "left"
  local function iter()
    local iter_i = 1
    return function()
      local result
      if iter_i > s:len() then
        return
      elseif s:match("^%w+%-", iter_i) then
        result = s:match("^%w+%-", iter_i)
      elseif s:match("^%w+%,", iter_i) then
        result = s:match("^%w+%,", iter_i)
      elseif s:match("^%w+%.", iter_i) then
        result = s:match("^%w+%.", iter_i)
      elseif s:match("^%w+", iter_i) then
        result = s:match("^%w+", iter_i)
      elseif s:match("^% +", iter_i) then
        result = s:match("^% +", iter_i)
      else
        result = s:sub(iter_i, iter_i)
      end
      iter_i = iter_i + result:len()
      return result
    end
  end


  local spaceLeft = width
  local acc = ""
  for token in iter() do
    if token == '\n' then
      spaceLeft = width + 1
    elseif spaceLeft - token:len() < 0 then
      if spaceLeft < width then
        acc = acc .. '\n'
        spaceLeft = width
      end

      while token:len() > width do
        acc = acc .. token:sub(1, width) .. '\n'
        token = token:sub(width + 1)
      end

      -- strip leading whitespace from the token
      local i = token:find("[^%s]")
      if i then
        token = token:sub(i)
      else
        token = ""
      end
    end

    acc = acc .. token
    spaceLeft = spaceLeft - token:len()
  end

  if align == "right" then
    return flushRight(acc, width)
  elseif align == "center" then
    return centerText(acc, width)
  end
  return acc
end

return loveterm
