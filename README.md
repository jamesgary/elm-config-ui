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

### For sursies

- undo/redo
  - each individual field:
    - undo (go to state just before first action in sequence)
    - rewind (go to original file... or to original load? may be different!)
  - whole form:
    - undo tree?
    - rewind to load or file?
    - technically, we could save the undo stack in the cache...
- * for vals that differ from file
- ! for brand new values that haven't been set yet (maybe note that in the field)
- save scrolltop
- custom increment value/factor

### Could be cool

- zebra bgs (or maybe borders)
- bools
- (x,y)

### Eh

- maybe a way to open/close?

### Possible options:
- Keep colors open after refreshing
- Keep header at top (vs scrolling w/ other fields)

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

