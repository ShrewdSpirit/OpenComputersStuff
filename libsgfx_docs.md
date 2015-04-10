
#Shrewd Graphics Library Documentation

Driver class
-----
The driver class holds information and proxies about attached screens and Computer Craft monitors and GPUs.

There should be at least one graphics driver in your application to be able to work with the library.

Functions:
- gpu: `(gpuproxy: component proxy) GPU proxy: table` gets or sets current gpu being used by driver
- activeDisplay: `(displayID: number) display proxy: table` sets or gets the active display
- setActiveDisplayType: `(displayType: string) success: boolean` sets the active display type (a screen or a monitor)
- display: `(displayID: number) display proxy: table` gets the display proxy
- displays: `() table of display proxies: table` returns a table of available displays (OpenComputers screens and ComputerCraft monitors)
- displayType: `() display type: string` returns active display type
- resolution: `(widht: number, height: number) width: number, height: number` sets or gets the resolution of active display (changing resolution of a monitor isn't possible)
- color: `(background: number, foreground: number) background: number, foreground: number` sets or gets the color of active display (getting the current color of a monitor isn't possible)
- plot: `(x: number, y: number, char: number|string)` plots a character (string or unicode code!) at given position
- set: `(x: number, y: number, str: string|number, vertical: boolean)` writes a string at given position (or a single character/unicode)
- fill: `(x: number, y: number, w: number, h: number, char: number|string)` fills a rectangle with given coordinates
- flush: `(stat: table)`
    flushes the displays informations. this should be called when a gpu,screen or monitor has been removed, added or resized. stat is the event (run dmesg and try adding or removing screens,monitors). if stat is nil, driver will be reinitialized
- checkComponentAvailability: `()` checks if theres a gpu and an active display

Context class
-----
The graphics context class is used to draw stuff on a display. It has an internal driver which should be initialized by user.

Functions:
- driver `(driver: Driver instance) driver: Driver instance` sets or gets current driver being used
- firstColor `(background: number, foreground: number) background: number, foreground: number` gets or sets the first color in color stack. this color cannot be popped out of stack
- pushColor `(background: number, foreground: number) background: number, foreground: number` pushes a color into color stack. use this to set the current color
- popColor `(times=1: number) background: number, foreground: number`
    Pops 'times' colors from stack and returns them as a table: { {bg: color, fg: color}, { ... }, ... }. If 'times' is bigger than size of color stack or is zero, the color stack will be cleared and all colors will be returned as a table. used to restore the previous set color
- plot `(x: number, y: number, char=' ': number|string)` plots a character/pixel at given position
- drawLine `(x0: number, y0: number, x1: number, y1: number, fillChar=' ': number|string)` draws a line
- drawStaticLine `x: number, y: number, len: number, vertical=false: boolean, fillChar=' ': number|string` draws a horizontal or vertical line (faster than drawLine)
- drawText `(text: string, x: number, y: number, w=0: number, h=0: number, valign='center': string, halign='center': string, wrap=false: boolean, clip=false: boolean, fill=false: boolean, hasFilledColor=false: boolean, fillChar=' ': string|number)`
    Draws a text with given position and size. wrap wraps the text to new line if height > 1. clip will trim the parts of text that are out of given height and width. if fill then it will draw a box with given coordinates. if hasFilledColor then it will pop a color from color stack. this is useful when you want a different color for the box and another color for the text. first pushed color will be used for text and second color will be applied to box
- drawBox `(x: number, y: number, w: number, h: number, fillChar=' ': string|number)` draws a box
- drawBorder `(x: number, y: number, w: number, h: number, borderSurrounding: table, invertUpDownBorders=false: boolean, ignoreTopBottomBorders=false: boolean)`
    draws a border! borderSurrounding should be a table of these values: {topleft char,topcenter char,topright char,centerright char,bottomright char,bottomcenter char,bottomleft char,centerleft char}
- clear `()` clears the display and sets cursor position to 1,1 if current display is a monitor

Colors table
-----
This is a table of 16 predefined colors. Because monitors doesn't support hex values, there are two color tables with two different aliases:
- MColors `monitor supported colors`
- SColors `screen supported colors`

Aliases:
- MColors:
    - Colors.m
    - Colors['m']
    - Colors.monitor
    - Colors['monitor']
- SColors:
    - Colors.s
    - Colors['s']
    - Colors.screen
    - Colors['screen']

Available colors:
- Black
- Blue
- Green
- Red
- Cyan
- Purple
- Lime
- Pink
- Yellow
- White
- Orange
- Magenta
- LightBlue
- Gray
- LightGray
- Brown
