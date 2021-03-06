module Main exposing (main)

import Browser
import Browser.Events
import Color exposing (Color)
import Config exposing (Config)
import ConfigForm as ConfigForm exposing (ConfigForm)
import Html exposing (Html)
import Html.Attributes exposing (style)
import Json.Decode
import Json.Decode.Pipeline
import Json.Encode
import Point3d exposing (Point3d)
import Random
import Svg exposing (Svg)
import Svg.Attributes


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



{-
   Your model will need a Config, which is what your app will read from to get config values.

   These are separate because maybe you have either a DevModel and ProdModel, where the DevModel has both Config and ConfigForm, while the ProdModel just has Config so it won't allow further configuration tweaking by the user (plus saves on js filesize).
-}


type alias Model =
    { config : Config
    , configForm : ConfigForm
    }



{-
   Your Msg will need to support a ConfigFormMsg value.
-}


type Msg
    = ConfigFormMsg (ConfigForm.Msg Config)



-- FLAGS
{-
   Your flags should be (or contain) a json Value that you got using `ElmConfigUi.init` in your javascript.
   It contains the following:
   - config data stored in localstorage
     - gets persisted automatically as you tweak config values
   - config data stored in a file
     - must be saved manually and is used when a user doesn't have any config values in their localstorage
-}
-- INIT


init : Json.Encode.Value -> ( Model, Cmd Msg )
init flags =
    let
        {-
           Initialize your config and configForm, passing in defaults for any empty config fields
        -}
        ( config, configForm ) =
            ConfigForm.init
                { flags = flags
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


view : Model -> Html Msg
view model =
    Html.div
        [ style "background" (Color.toCssString model.config.bgColor)
        , style "font-size" "22px"
        , style "padding" "20px"
        , style "height" "100%"
        , style "font-family" "sans-serif"
        ]
        [ Html.h1
            [ style "font-size" (String.fromInt model.config.headerFontSize ++ "px")
            , style "line-height" "0"
            ]
            [ Html.text "Some Header Text" ]
        , Html.p
            [ style "font-size" (String.fromInt model.config.bodyFontSize ++ "px") ]
            [ Html.text "I am the body text!" ]
        , Html.div
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
            , Html.hr [] []
            , Html.text "Copy this json to config.json:"
            , Html.br [] []
            , Html.textarea
                [ style "width" "100%"
                , style "height" "100px"
                , Html.Attributes.readonly True
                ]
                [ ConfigForm.encode model.configForm
                    |> Json.Encode.encode 2
                    |> Html.text
                ]
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
