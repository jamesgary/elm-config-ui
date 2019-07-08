port module Main exposing (main)

import Browser
import Color exposing (Color)
import Config exposing (Config)
import Egg.ConfigForm as ConfigForm exposing (ConfigForm)
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


port sendToPort : JD.Value -> Cmd msg


port receiveFromPort : (JD.Value -> msg) -> Sub msg


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { config : Config
    , configForm : ConfigForm Config
    }


type Msg
    = ConfigFormMsg (ConfigForm.Msg Config)
    | ReceivedFromPort JE.Value



-- FLAGS


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
            let
                ( newConfig, newConfigForm, maybeJsonCmd ) =
                    ConfigForm.update
                        Config.logics
                        model.config
                        model.configForm
                        configFormMsg

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

        ReceivedFromPort portJson ->
            case JD.decodeValue fromPortDecoder portJson of
                Ok receiveMsg ->
                    case receiveMsg of
                        ConfigFormPortMsg json ->
                            let
                                ( newConfig, newConfigForm, maybeJsonCmd ) =
                                    ConfigForm.updateFromJson
                                        Config.logics
                                        model.config
                                        model.configForm
                                        json

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

                Err err ->
                    let
                        _ =
                            Debug.log "Could not decode incoming port msg: " (JD.errorToString err)
                    in
                    ( model, Cmd.none )


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
view ({ config } as model) =
    E.layout
        [ E.padding 20
        , E.inFront <|
            E.el
                [ E.alignRight
                , E.padding 20
                , E.height E.fill
                , E.width E.fill
                , E.scrollbarY
                ]
                (E.el
                    [ EBackground.color (colorForE config.configTableBgColor)
                    , EBorder.color (colorForE config.configTableBorderColor)
                    , EBorder.width config.configTableBorderWidth
                    , E.scrollbarY
                    , E.alignRight
                    ]
                    (E.column
                        [ E.padding config.configTablePadding
                        , E.spacing 15
                        ]
                        [ ConfigForm.viewElement
                            (ConfigForm.viewOptions
                                |> ConfigForm.withRowSpacing config.configRowSpacing
                                |> ConfigForm.withLabelHighlightBgColor config.configLabelHighlightBgColor
                                |> ConfigForm.withInputHeight config.configInputHeight
                                |> ConfigForm.withFontSize config.configFontSize
                            )
                            Config.logics
                            model.configForm
                            |> E.map ConfigFormMsg
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
        ]
        (E.column []
            [ E.row
                [ EFont.size model.config.headerFontSize
                ]
                [ E.text <| "Header: " ++ model.config.headerString ]
            , E.column []
                (List.range 1 model.config.subheaderNum
                    |> List.map
                        (\_ ->
                            E.el
                                [ EFont.size model.config.subheaderFontSize
                                , EBackground.color (colorForE model.config.subheaderColor)
                                , E.padding model.config.subheaderPadding
                                ]
                                (E.text <| "Subheader: " ++ model.config.subheaderString)
                        )
                )
            ]
        )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ receiveFromPort ReceivedFromPort
        ]


colorForE : Color -> E.Color
colorForE color =
    color
        |> Color.toRgba
        |> (\{ red, green, blue, alpha } ->
                E.rgba red green blue alpha
           )
