# elm-config-gui

## Note: Experimental, and likely to change!

Have a bunch of magic numbers you want to tweak in the browser? Tired of making a `Msg` for every single field? Try `elm-config-gui`!

`elm-config-gui` adds a mini-editor into the browser to let you update values (`Int`s, `Float`s, `String`s, and `Color`s) on the fly without refreshing. Check out a live example in ellie (TODO once package is released)!

This package has the following features:

- Mini-editor in the browser to let you update config values on the fly without refreshing
- Automatically save changes to localStorage
- Encodes config data to JSON so you can save in a more persistent `.json` file

This is meant to be used a dev-facing tool. Hence, there's limited customizability for things like the view. For a fully customizable editor with things like advanced validation and types, you might be better building your own.

# Install

Let's say you want a config record that looks like this:

```elm
type alias Config =
  { headerFontSize : Int
  , bodyFontSize : Int
  , backgroundColor : Color
  }
```

Here are the steps to wire everything up:

## Step 1: Set up run script and code generation

When adding a new field, such as `headerFontColor`, you'd normally have to update the `type alias Config`, add it to the form in the view, add a `Msg`, encoder, decoder, etc. Turns out there's a lot to do, which can slow down development! If you want all this generated for you, you can instead write a schema file:

```elm
module ConfigSchema exposing (main)

import ConfigFormGenerator exposing (Kind(..))
import Html exposing (Html)

myConfigFields : List ( String, Kind )
myConfigFields =
    [ ( "Header Font Size", IntKind "headerFontSize" )
    , ( "Body Font Size", IntKind "bodyFontSize" )
    , ( "Background Color", ColorKind "backgroundColor" )
    -- add more fields here
    ]

main : Html msg
main =
    let
        generatedElmCode =
            ConfigFormGenerator.toFile myConfigFields

        _ =
            Debug.log generatedElmCode ""
    in
    Html.text ""
```

Copy this and save it as `ConfigSchema.elm`. You can now run the following to generate a `Config.elm` file:

```sh
# Compile schema file to tmp js
elm make ConfigSchema.elm --output=~tmp/tmp.js > /dev/null

# Run compiled js with node, which logs out generated elm code, and save to Config.elm:
node ~tmp/tmp.js > Config.elm 2>/dev/null
```

### Watcher script

Here's the script I use to run both the schema watcher, and `elm-live` for the rest of my elm development.

```sh
#!/bin/bash

CONFIG_SCHEMA_ELMFILE=ConfigSchema.elm
CONFIG_ELMFILE=Config.elm
TMP_JS=~/tmp/gen-config.js
MAIN_ELMFILE=Main.elm
SERVER_DIR=public/
MAIN_JS_OUTPUT=public/js/main.js

GENERATE_ARGS="$CONFIG_SCHEMA_ELMFILE $TMP_JS $CONFIG_ELMFILE"

# Command for generating Config.elm from ConfigSchema.elm
generate_config () {
  CONFIG_SCHEMA_ELMFILE=$1
  TMP_JS=$2
  CONFIG_ELMFILE=$3
  
  # Use `elm make` to make an elm app that console.logs the generated Config.elm code
  elm make $CONFIG_SCHEMA_ELMFILE --output=$TMP_JS > /dev/null && \
    # Run it with `node` to print the output and write to Config.elm
    node $TMP_JS > $CONFIG_ELMFILE 2>/dev/null
}
export -f generate_config

# Generate the config initially, just in case it doesn't exist
generate_config $GENERATE_ARGS

# Watch for config changes
chokidar $CONFIG_SCHEMA_ELMFILE --command "generate_config $GENERATE_ARGS" &

# Watch for elm changes
elm-live $MAIN_ELMFILE --dir=$SERVER_DIR -- --output=$MAIN_JS_OUTPUT &

wait
```

This will watch for changes to `ConfigSchema.elm` and generate a `Config.elm` file with all the expanded `Config`, `empty`, and `logics` code. Make sure you have the following installed, too:

```sh
# (use --save-dev instead of --global if you only need it locally for one project)
npm install --global elm elm-live@next chokidir
```


## Step 2: App initialization

When this app is used for the first time, the `config` record should be populated with some kind of hardcoded `configFile`, usually from a `.json` file. This is considered the "default" config. As the user makes tweaks through the gui, the new `config` is stored in `localStorage` and is used thereafter.

Therefore, your flags and decoders should look something like this:

```elm
import Config exposing (Config)
import ConfigForm exposing (ConfigForm)

type alias Flags =
    { localStorage : LocalStorage
    , configFile : Json.Encode.Value
    }


type alias LocalStorage =
    { config : Json.Encode.Value
    }


decodeFlags : Json.Decode.Decoder Flags
decodeFlags =
    Json.Decode.succeed Flags
        |> Json.Decode.Pipeline.required "localStorage" decodeLocalStorage
        |> Json.Decode.Pipeline.required "configFile" Json.Decode.value


decodeLocalStorage : Json.Decode.Decoder LocalStorage
decodeLocalStorage =
    -- if localstorage has not been set yet, fallback to { "configForm": {} }
    Json.Decode.succeed LocalStorage
        |> Json.Decode.Pipeline.optional "config" Json.Decode.value (Json.Encode.object [])

```

Note how both `configFile` and `config` are `Json.Encode.Value`, and not `Config` or `ConfigForm`. This is so that you can make changes to the structure of the `Config` record and not break when elm tries to decode flags with outdated config data. The "real" decoding step happens with `ConfigForm.init`, which you'll use in your `init` function:

```elm
init : Json.Encode.Value -> ( Model, Cmd Msg )
init jsonFlags =
    case Json.Decode.decodeValue decodeFlags jsonFlags of
        Ok flags ->
            let
                ( config, configForm ) =
                    ConfigForm.init
                        { configJson = flags.configFile
                        , configFormJson = flags.localStorage.configForm
                        , logics = Config.logics
                        , emptyConfig =
                            Config.empty
                                { int = 1
                                , float = 1
                                , string = "REPLACE ME"
                                , bool = True
                                , color = Color.rgba 1 0 1 1 -- hot pink!
                                }
                        }
            in
            ( { config = config
              , configForm = configForm
              }
            , Cmd.none
            )

        Err err ->
            Debug.todo (Json.Decode.errorToString err)
```


## Step 3: `Model`

Update your **Model** to include both `Config` and `ConfigForm Config`:

```elm
type alias Model =
    { config : Config
    , configForm : ConfigForm Config
    , ...
    }
```

## Step 4: `Msg`

Add a new `Msg` value `ConfigFormMsg (ConfigForm.Msg Config)`

```elm
type Msg
    = ConfigFormMsg (ConfigForm.Msg Config)
    
    -- If you haven't already, you should have a msg for incoming port messages
    -- This will allow you to use pointerlock for changing Int/Float values
    | ReceivedFromPort Json.Encode.Value 
    | ...
```

## Step 5: `Flags` and `init`

When you first load your app, your `Flags` should 

When you receive a `ConfigFormMsg` or `ReceivedFromPort` for a `ConfigFormPortMsg`, you can call

Your flags should contain two things: config data stored in localstorage (this gets persisted automatically as you tweak config values), and config data stored in a file (this must be saved manually and is used when a user doesn't have any config values in their localstorage).

```html
<!-- index.html -->

<!-- compiled elm code -->
<script src="./main.js"></script>

<!-- elm-config-ui helper js -->
<!-- Copy from https://github.com/jamesgary/elm-config-ui/blob/master/elm-config-ui-helper.js or use this CDN -->
<script src="https://cdn.jsdelivr.net/gh/jamesgary/elm-config-ui@f5200e/elm-config-ui-helper.js"></script>

<script>
  const LOCALSTORAGE_KEY = "my_cool_app";
  const node = document.getElementById('elm');

  // ideally, you would load from json
  fetch('./data/config.json')
    .then(function(resp) { return resp.json() })
    .then(function(json) { init(json) });
  
  /* // alternatively, you could just hardcode it here:
  init({
    "headerFontSize": 32,
    "bodyFontSize": 16,
    ...
  });
  */
    

  function init(configFile) {
    // start main Elm app
    let app = Elm.Main.init({
      node: node,
      flags: {
        localStorage: JSON.parse(localStorage.getItem(LOCALSTORAGE_KEY)),
        configFile: configFile,
      }
    });

    // start configForm
    ConfigForm.init(app.ports.receiveFromPort);
    
    // set up ports
    app.ports.sendToPort.subscribe(function(effect) {
      switch (effect.id) {
        case "SAVE":
          localStorage.setItem(
            LOCALSTORAGE_KEY,
            JSON.stringify(effect.val),
          );
          break;
        case "CONFIG":
          ConfigForm.receivePortMsg(effect.val, node);
          break;
        default:
          console.error("Unknown Effect", effect);
      }
    });
  }
</script>
```

## Step 6: `update`

Your update function will listen to `ConfigFormMsg` and `ConfigFormPortMsg` from ports, then update the `config` and `configForm` in your `model`, and finally send a request to save to localstorage and any pointerlock commands through the port.

```elm
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ConfigFormMsg configFormMsg ->
            ConfigForm.update
                Config.logics
                model.config
                model.configForm
                configFormMsg
                |> handleConfigMsg model

        ReceivedFromPort portJson ->
            case Json.Decode.decodeValue fromPortDecoder portJson of
                Ok receiveMsg ->
                    case receiveMsg of
                        ConfigFormPortMsg json ->
                            ConfigForm.updateFromJson
                                Config.logics
                                model.config
                                model.configForm
                                json
                                |> handleConfigMsg model

                Err err ->
                    let
                        _ =
                            Debug.log "Could not decode incoming port msg: " (Json.Decode.errorToString err)
                    in
                    ( model, Cmd.none )


handleConfigMsg : Model -> ( Config, ConfigForm Config, Maybe Json.Encode.Value ) -> ( Model, Cmd Msg )
handleConfigMsg model ( newConfig, newConfigForm, maybeJsonCmd ) =
    let
        newModel =
            { model
                | config = newConfig
                , configForm = newConfigForm
            }
    in
    ( newModel
    , Cmd.batch
        [ saveToLocalStorageCmd newModel
        , case maybeJsonCmd of
            Just jsonCmd ->
                sendToPort
                    (Json.Encode.object
                        [ ( "id", Json.Encode.string "CONFIG" )
                        , ( "val", jsonCmd )
                        ]
                    )

            Nothing ->
                Cmd.none
        ]
    )


type ReceiveMsg
    = ConfigFormPortMsg Json.Encode.Value


fromPortDecoder : Json.Decode.Decoder ReceiveMsg
fromPortDecoder =
    Json.Decode.field "id" Json.Decode.string
        |> Json.Decode.andThen
            (\id ->
                case id of
                    "CONFIG" ->
                        Json.Decode.field "val" Json.Decode.value
                            |> Json.Decode.map ConfigFormPortMsg

                    str ->
                        Json.Decode.fail ("Bad id to receiveFromPort: " ++ str)
            )


saveToLocalStorageCmd : Model -> Cmd Msg
saveToLocalStorageCmd model =
    sendToPort <|
        Json.Encode.object
            [ ( "id", Json.Encode.string "SAVE" )
            , ( "val"
              , Json.Encode.object
                    [ ( "configForm"
                      , ConfigForm.encodeConfigForm
                            model.configForm
                      )
                    ]
              )
            ]
```

## Step 7: `view`

Lastly, lets add the form to the view! Here's an example using elm-ui:

```elm
import Element as E exposing (Element)
import Element.Background as EBackground
import Element.Border as EBorder
import Element.Events as EEvents
import Element.Font as EFont
import Element.Input as EInput

view : Model -> Html Msg
view model =
    E.layout
        [ E.inFront <| viewConfig model
        , EBackground.color <| colorForE model.config.bgColor
        , E.padding <| model.config.padding
        ]
        (E.column []
            [ E.el [ EFont.size model.config.headerFontSize ] (E.text "Hello")
            , E.el [ EFont.size model.config.bodyFontSize ] (E.text "I am the body text!")
            ]
        )


viewConfig : Model -> Element Msg
viewConfig ({ config } as model) =
    E.el
        [ E.alignRight
        , E.padding 20
        , E.scrollbarY
        ]
        (E.el
            [ E.alignRight
            , E.scrollbarY
            , EBackground.color (E.rgb 1 1 1)
            , EBorder.color (E.rgb 0 0 0)
            , EBorder.width 1
            , EFont.color (E.rgb 0 0 0)
            ]
            (E.column
                [ E.padding 15
                , E.spacing 15
                , E.width <| E.px <| 400
                ]
                [ ConfigForm.viewElement
                    ConfigForm.viewOptions
                    Config.logics
                    model.configForm
                    |> E.map ConfigFormMsg
                , E.paragraph
                    [ EFont.size 16 ]
                    [ E.text "Copy json to public/data/config.json once you're happy with the config values." ]
                , Html.textarea
                    [ Html.Attributes.value
                        (ConfigForm.encode
                            Config.logics
                            model.config
                            |> Json.Encode.encode 2
                        )
                    ]
                    []
                    |> E.html
                    |> E.el []
                ]
            )
        )

colorForE : Color -> E.Color
colorForE color =
    color
        |> Color.toRgba
        |> (\{ red, green, blue, alpha } ->
                E.rgba red green blue alpha
           )
```

# TODO

New features

- undo/redo
  - each individual field:
    - undo (go to state just before first action in sequence)
    - rewind (go to original file... or to original load? may be different!)
  - whole form:
    - undo tree?
    - rewind to load or file?
    - technically, we could save the undo stack in the cache...
- "*" for vals that differ from file
- "!" for brand new values that haven't been set yet (maybe note that in the field)
- save scrolltop
- fancy (or custom) kinds, like elm-ui attributes

Optimizations

- Cleaner run script (remove duplication, tmp file)
- Opaque-ify any types that can be opaque

# Questions

- How opinionated should this be?
  - Should I allow users to skip pointerlock or even saving?
  - Should I include the toggleable form container and JSON preview textarea by default, including the toggle functionality? Or is that best left to the dev to control?
- Is there any way to let users create new vals, like xy or elm-ui attrs?
  - I could add them myself with only non-breaking minor updates
- Relatedly, how customizable should the view be?
  - Might be a good idea to let it be customizable once/if I add elm-ui attrs
- Is it bad that it relies on elm-ui? Code bloat, less performant, duplicate styles...
- Is all this port stuff for pointerlock even worth it?
