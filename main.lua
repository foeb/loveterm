local loveterm = require "loveterm"
local codes = require "extra/cp437"
local color = require "extra/color"
local palette = color.c64

function love.load()
  -- Create a new screen object
  screen = loveterm.create("tilesets/CGA8x8thick.png", 80, 40)
  
  -- Print a wrapped string to our screen at the coordinates 5, 5
  screen:print(
      screen.wrapString(
          "LoveTerm is a small library for drawing 1-bit tiled graphics, such as terminal emulators.",
          21),
      5, 5)
  -- Now let's add a pink heart next to it
  screen:set(codes.heart, palette.pink, screen.defaultbg, 3, 5)
  
  -- We can easily iterate through all of the available tiles
  for i = 0, 255 do
    screen:setValue(i, (i % 16) + 32, math.floor(i / 16) + 5)
  end

  -- Here we show off the included Commodore 64 color scheme
  local i = 0
  for k, v in pairs(palette) do
    if k ~= "white" and k ~= "lightgray" and k ~= "gray" 
          and k ~= "darkgray" and k ~= "black" then
      screen:set(codes.smiley, v, screen.defaultbg, i*2 + 26, 22)
      screen:set(0, palette.black, v, i*2 + 26, 24)
      i = i + 1
    end
  end
end

function love.draw()
  screen:draw()
end
