port module Main exposing (main)

import Browser
import Color exposing (Color)
import Config exposing (Config)
import ConfigForm exposing (ConfigForm)
import Element as E exposing (Element)
import Element.Background as EBackground
import Element.Events as EEvents
import Element.Font as EFont
import Element.Input as EInput
import Html exposing (Html)
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
        |> JDP.optional "configForm" JE.value (JE.object [])



-- INIT


init : JE.Value -> ( Model, Cmd Msg )
init jsonFlags =
    case JD.decodeValue decodeFlags jsonFlags of
        Ok flags ->
            let
                ( config, configForm ) =
                    ConfigForm.init
                        { configJson = flags.config
                        , configFormJson = flags.configForm
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
                    --CF.update Config.ff configFormMsg model.config
                    ConfigForm.update
                        configFormMsg
                        model.configForm

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
                                    --CF.update Config.ff (CF.portMsgFromJson json) model.config
                                    ConfigForm.updateFromJson json model.configForm

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
                      , Config.encodeForm model.configForm
                      )
                    ]
              )
            ]


view : Model -> Html Msg
view { config } =
    E.layout
        [ E.padding 20
        , E.inFront
            (E.el
                [ E.alignRight
                , E.moveLeft 20
                , E.moveDown 20
                , E.height E.fill
                , E.scrollbars
                ]
                (Config.view config
                    |> E.map ConfigFormMsg
                )
            )
        ]
        (E.column []
            [ E.row
                [ EFont.size (round config.fooFontSize)
                ]
                [ E.text <| "Foo: " ++ config.fooString ]
            , E.row
                [ EFont.size (round config.barFontSize)
                , EBackground.color (colorForE config.barColor)
                ]
                [ E.text <| "Bar: " ++ config.barString ]
            , E.row [] [ E.text " " ]
            , E.row [] [ E.text "---" ]
            , E.row [] [ E.text " " ]
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
