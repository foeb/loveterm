# ![](header.png])
> Simple 1-bit tiled graphics for Love2d

LoveTerm is a small library for drawing tiled greyscaled images with 
foreground and background colors. Its main intended use is to emulate
terminal graphics and semigraphics from the comfort of Love2d and Lua
for roguelike games, but it could be useful for other retro style games.

The included tilesets follow Code Page 437, but you could use any images
you want. However, `loveterm.print` expects the ASCII codes to match
their respective characters in the tileset. For example, `48` is 0, `65`
is A, etc.

![](example.png)

## Installation
To use LoveTerm in your Love2d project, simply drop any of the files you
need into its directory and include it by adding 
`local loveterm = require "loveterm"`.

## Documentation
See the LDoc documentation in `doc/` for examples and an overview of the 
library.

## Meta
LoveTerm is released into the public domain with the help of CC0. See
`COPYING` for more information.
