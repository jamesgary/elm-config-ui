# Config Thing

## Install

```
npm install -g chokidir
```

## Running

```
# Like Makefiles?

make

# Like scripts?

./bin/run.sh
```


## TODO

- undo/redo
  - each individual field:
    - undo (go to state just before first action in sequence)
    - rewind (go to original file... or to original load? may be different!)
  - whole form:
    - undo tree?
    - rewind to load or file?
    - technically, we could save the undo stack in the cache...
- * for vals that differ from file
- maybe a way to open/close?
- close colors when unfocused
- zebra bgs (or maybe borders)
- bools
- (x,y)
- save scrolltop

## WHAT IF ELM-UI??

attributes
- width (px, shrink, fill, fillPortion, maximum, minimum)
- height
- padding (xy, each)
- spacing (xy, evenly)
- alignment
  - centerX
  - centerY
  - alignLeft
  - alignRight
  - alignTop
  - alignBottom
- transparency
- alpha
- pointer
- moveUp/down/left/right
- rotate
- scale
- clip?
- focusstyle?
- mouseover/down/focused?
- background
  - color
  - gradient
- border
  - color
  - width (xy, each)
  - style
  - rounded
  - glow (inner)
  - shadow (inner)
- font
  - color
  - size
  - family
  - alignment
  - letter spacing
  - word spacing
  - more styles
  - weight
  - variants
  - glow
  - shadow

misc
- isWrapped (for row vs wrappedRow)

