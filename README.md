# elm-config-gui

## ⚠️ Note: Experimental, and likely to change! ⚠️

Have a bunch of magic numbers you want to tweak in the browser? Tired of making a `Msg` for every single field? Try `elm-config-gui`!

`elm-config-gui` adds a mini-editor into the browser to let you update values (`Int`, `Float`, `String`, and `Color`) on the fly without refreshing. Check out a live example [here](https://elm-boids-demo.s3-us-west-1.amazonaws.com/index.html)!

![Screenshot of boids with elm-config-ui](https://user-images.githubusercontent.com/386075/64661773-dcba6a80-d3fa-11e9-96fa-d5013e0ae9e3.png)

This package has the following features:

- Mini-editor in the browser to let you update config values on the fly without refreshing
- Automatically save changes to localStorage
- Encodes config data to JSON so you can save in a more persistent `.json` file

This module has a **javascript dependency** that sets up webcomponents for saving to localstorage and handling pointerlock for infinite dragging. It also uses a **CLI tool** for generating your `Config.elm` file. Check out the examples directory to see how it all works!

This is meant to be used a dev-facing tool. Hence, there's limited customizability for things like the view. For a fully customizable editor with things like advanced validation and types, feel free to fork and modify!

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

## Step 1: Generate your `Config.elm`

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

# You now have a Config.elm file!
```

This will watch for changes to `ConfigSchema.elm` and generate a `Config.elm` file with all the expanded `Config`, `empty`, and `logics` code.

Check out the `run.sh` scripts in the examples to see how to set up a watcher to do this for you automatically!

## Step 2: App initialization

Initialize your elm app using the `elm-config-ui-helper.js` script:

```html
<!-- index.html -->

<div id="elm"></div>

<!-- your compiled elm code -->
<script src="./main.js"></script>

<!-- elm-config-ui helper js -->
<!-- Copy from https://github.com/jamesgary/elm-config-ui/blob/master/elm-config-ui-helper.js -->
<script src="https://cdn.jsdelivr.net/gh/jamesgary/elm-config-ui@f5200e/elm-config-ui-helper.js"></script>

<script>
  ElmConfigUi.init({
    // This is where you'll persist your config data for other users.
    // It's fine if this file has just an empty object for now, like "{}".
    filepath: "./config.json",
    localStorageKey: "my_app",
    callback: function(elmConfigUiData) {
      // start main Elm app
      let app = Elm.Main.init({
        node: document.getElementById("elm"),
        flags: elmConfigUiData,
      });
    }
  });
</script>
```

`elmConfigUiData` will contain json from your file and your localstorage.

## Step 3: Elm app integration

```elm
-- import your generated Config file and the ConfigForm package
import Config exposing (Config)
import ConfigForm exposing (ConfigForm)

-- add config and configForm to your model
type alias Model =
    { ...
    -- config is your generated config record,
    -- which can be called like model.config.headerFontSize
    , config : Config
    -- configForm is an opaque type that is managed by ConfigForm
    , configForm : ConfigForm
    }

init : Json.Encode.Value -> ( Model, Cmd Msg )
init elmConfigUiFlags =
    let
        -- Initialize your config and configForm,
        -- passing in defaults for any empty config fields
        ( config, configForm ) =
            ConfigForm.init
                { flags = elmConfigUiFlags
                , logics = Config.logics
                , emptyConfig =
                    Config.empty
                        { int = 1
                        , float = 1
                        , string = "SORRY IM NEW HERE"
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

type Msg
    = ConfigFormMsg (ConfigForm.Msg Config)
    | ...

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ConfigFormMsg configFormMsg ->
            let
                ( newConfig, newConfigForm ) =
                    ConfigForm.update
                        Config.logics
                        model.config
                        model.configForm
                        configFormMsg
            in
            ( { model
                | config = newConfig
                , configForm = newConfigForm
              }
            , Cmd.none
            )

-- Lastly, lets add the form to the view!
view : Model -> Html Msg
view model =
    Html.div
        -- some nice styles to render it on the right side of the viewport
        [ style "padding" "12px"
        , style "background" "#eec"
        , style "border" "1px solid #444"
        , style "position" "absolute"
        , style "height" "calc(100% - 80px)"
        , style "right" "20px"
        , style "top" "20px"
        ]
        [ ConfigForm.view
            ConfigForm.viewOptions
            Config.logics
            model.configForm
            |> Html.map ConfigFormMsg

        -- As a developer, you'll want to save your tweaks to your config.json.
        -- You can copy/paste the content from this textarea to your config.json.
        -- Then the next time a new user loads your app, they'll see your updated config.
        , Html.textarea []
            [ ConfigForm.encode model.configForm
                |> Json.Encode.encode 2
                |> Html.text
            ]
        ]
```

# Todo

New features

- Undo/redo
- Reset to default
- Indicator for vals that differ from file (or that are entirely new)
- Save scrolltop
- Fancy (or custom) kinds, like css or elm-ui attributes?

Optimizations

- Cleaner run script (remove duplication and tmp file?)

Tests!
