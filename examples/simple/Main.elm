{-
   We'll be using ports for pointerlock, i.e. dragging numerical values to resize them.
-}


port module Main exposing (main)

import Browser
import Browser.Events
import Color exposing (Color)
import Config exposing (Config)
import ConfigForm as ConfigForm exposing (ConfigForm)
import Element as E exposing (Element)
import Element.Background as EBackground
import Element.Border as EBorder
import Element.Events as EEvents
import Element.Font as EFont
import Element.Input as EInput
import Html exposing (Html)
import Html.Attributes
import Json.Decode as JD
import Json.Decode.Pipeline as JDP
import Json.Encode as JE
import Point3d exposing (Point3d)
import Random
import Svg exposing (Svg)
import Svg.Attributes



{-
   Ports are often easiest if we have just one for incoming and one for receiving, both of which use Json.Decode.Value.
-}


port sendToPort : JD.Value -> Cmd msg


port receiveFromPort : (JD.Value -> msg) -> Sub msg


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



{-
   Your model will need a Config, which is what your app will read from to get config values.

   These are separate because maybe you have either a DevModel and ProdModel, where the DevModel has both Config and ConfigForm, while the ProdModel just has Config so it won't allow further configuration tweaking by the user.
-}


type alias Model =
    { config : Config
    , configForm : ConfigForm Config
    }



{-
   Your Msg will need to support a ConfigFormMsg value.
-}


type Msg
    = ConfigFormMsg (ConfigForm.Msg Config)
    | ReceivedFromPort JE.Value



-- FLAGS
{-
   Your flags should contain two things:
   - config data stored in localstorage
     - gets persisted automatically as you tweak config values
   - config data stored in a file
     - must be saved manually and is used when a user doesn't have any config values in their localstorage
-}


type alias Flags =
    { localStorage : LocalStorage
    , configFile : JE.Value
    }


type alias LocalStorage =
    { configForm : JE.Value
    }


decodeFlags : JD.Decoder Flags
decodeFlags =
    JD.succeed Flags
        |> JDP.required "localStorage" decodeLocalStorage
        |> JDP.required "configFile" JD.value


decodeLocalStorage : JD.Decoder LocalStorage
decodeLocalStorage =
    JD.succeed LocalStorage
        |> JDP.optional "configForm" JD.value (JE.object [])



-- INIT


init : JE.Value -> ( Model, Cmd Msg )
init jsonFlags =
    case JD.decodeValue decodeFlags jsonFlags of
        Ok flags ->
            let
                {-
                   Initialize your config and configForm, passing in defaults for any empty config fields
                -}
                ( config, configForm ) =
                    ConfigForm.init
                        { configJson = flags.configFile
                        , configFormJson = flags.localStorage.configForm
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

        Err err ->
            Debug.todo (JD.errorToString err)


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
            case JD.decodeValue fromPortDecoder portJson of
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
                            Debug.log "Could not decode incoming port msg: " (JD.errorToString err)
                    in
                    ( model, Cmd.none )


handleConfigMsg : Model -> ( Config, ConfigForm Config, Maybe JE.Value ) -> ( Model, Cmd Msg )
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
                    (JE.object
                        [ ( "id", JE.string "CONFIG" )
                        , ( "val", jsonCmd )
                        ]
                    )

            Nothing ->
                Cmd.none
        ]
    )


type ReceiveMsg
    = ConfigFormPortMsg JE.Value


fromPortDecoder : JD.Decoder ReceiveMsg
fromPortDecoder =
    JD.field "id" JD.string
        |> JD.andThen
            (\id ->
                case id of
                    "CONFIG" ->
                        JD.field "val" JD.value
                            |> JD.map ConfigFormPortMsg

                    str ->
                        JD.fail ("Bad id to receiveFromPort: " ++ str)
            )


saveToLocalStorageCmd : Model -> Cmd Msg
saveToLocalStorageCmd model =
    sendToPort <|
        JE.object
            [ ( "id", JE.string "SAVE" )
            , ( "val"
              , JE.object
                    [ ( "configForm"
                      , ConfigForm.encodeConfigForm
                            model.configForm
                      )
                    ]
              )
            ]


view : Model -> Html Msg
view model =
    E.layout
        [ E.inFront <| viewConfig model
        , EBackground.color <| colorForE model.config.bgColor
        , EFont.color <| colorForE model.config.fontColor
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
                            |> JE.encode 2
                        )
                    ]
                    []
                    |> E.html
                    |> E.el []
                ]
            )
        )


subscriptions : Model -> Sub Msg
subscriptions model =
    receiveFromPort ReceivedFromPort


colorForE : Color -> E.Color
colorForE color =
    color
        |> Color.toRgba
        |> (\{ red, green, blue, alpha } ->
                E.rgba red green blue alpha
           )
