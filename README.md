# elm-config-gui

Have a bunch of magic numbers you want to tweak in the browser? Tired of making a `Msg` for every single field? Try `elm-config-gui`!

## Install

```
npm install -g chokidir
```

Let's say you want a config record that looks like this:

```
type alias Config =
  { headerFontSize : Int
  , bodyFontSize : Int
  , backgroundColor : Color
  }
```

Update your **Model** to include both `Config` and `ConfigForm Config`:

```
-- Main.elm

type alias Model =
    { config : Config
    , configForm : ConfigForm Config
    , ...
    }
```

Add a new `Msg` value `ConfigFormMsg (ConfigForm.Msg Config)`

```
-- Main.elm

type Msg
    = ConfigFormMsg (ConfigForm.Msg Config)
    | ReceivedFromPort Json.Encode.Value -- if you haven't already, you should have a msg for incoming port messages
    | ...
```

When you receive a `ConfigFormMsg` or `ReceivedFromPort` for a `ConfigFormPortMsg`, you can call

Your flags should contain two things: config data stored in localstorage (this gets persisted automatically as you tweak config values), and config data stored in a file (this must be saved manually and is used when a user doesn't have any config values in their localstorage).

```
-- index.html

<!-- compiled elm code -->
<script src="./js/compiled/main.js"></script>

<!-- config helper -->
<script src="./js/config.js"></script>

<script>
  const node = document.getElementById('elm');

  fetch('./data/config.json')
    .then(function(resp) { return resp.json() })
    .then(function(json) { init(json) });

  function init(configFile) {
    // start main Elm app
    let app = Elm.Main.init({
      node: node,
      flags: {
        localStorage: JSON.parse(localStorage.getItem("my_cool_app")),
        configFile: configFile,
      }
    });

    // start configForm
    ConfigForm.init(app.ports.receiveFromPort);
  }
</script>
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
  - optional min
  - optional max
  - onScroll
    - x
    - x%

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
