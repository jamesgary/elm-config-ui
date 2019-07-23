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
import Tree exposing (Tree)


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
    , isConfigOpen : Bool
    , autostep : Bool
    , tree : Tree
    }


type Msg
    = ConfigFormMsg (ConfigForm.Msg Config)
    | ReceivedFromPort JE.Value
    | ClickedOpenConfig
    | ClickedCloseConfig
    | ClickedStep
    | ClickedAutoStep
    | Tick Float



-- FLAGS


type alias Flags =
    { localStorage : LocalStorage
    , configFile : JE.Value
    }


type alias LocalStorage =
    { configForm : JE.Value

    -- other things you may not necessarily want in your config form
    , isConfigOpen : Bool
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
        |> JDP.optional "isConfigOpen" JD.bool False



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
                                , bool = True
                                , color = Color.rgba 1 0 1 1 -- hot pink!
                                }
                        }
            in
            ( { config = config
              , configForm = configForm
              , isConfigOpen = flags.localStorage.isConfigOpen
              , tree = initTree config
              , autostep = False
              }
            , Cmd.none
            )

        Err err ->
            Debug.todo (JD.errorToString err)


initTree : Config -> Tree
initTree config =
    Random.step
        (Tree.generator
            { rootPos =
                Point3d.fromCoordinates
                    ( toFloat config.viewportWidth / 2
                    , toFloat <| config.viewportHeight - config.groundHeight
                    , 0
                    )
            , cloudCenter =
                Point3d.fromCoordinates
                    ( toFloat config.viewportWidth / 2
                    , toFloat config.viewportHeight - toFloat config.groundHeight - config.cloudHeight
                    , 0
                    )
            , cloudRad = config.cloudRad
            , cloudCount = config.cloudCount
            , growDist = -config.growDist
            , minDist = config.minDist
            , maxDist = config.maxDist
            }
        )
        (Random.initialSeed config.seed)
        |> Tuple.first


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
                        , tree = initTree newConfig
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
                                        , tree = initTree newConfig
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

        ClickedOpenConfig ->
            let
                newModel =
                    { model | isConfigOpen = True }
            in
            ( newModel
            , saveToLocalStorageCmd newModel
            )

        ClickedCloseConfig ->
            let
                newModel =
                    { model | isConfigOpen = False }
            in
            ( newModel
            , saveToLocalStorageCmd newModel
            )

        ClickedStep ->
            ( { model
                | tree = Tree.step model.tree
              }
            , Cmd.none
            )

        ClickedAutoStep ->
            ( { model
                | autostep = not model.autostep
              }
            , Cmd.none
            )

        Tick d ->
            ( { model
                | tree =
                    if model.autostep then
                        Tree.step model.tree

                    else
                        model.tree
              }
            , Cmd.none
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
                    , ( "isConfigOpen"
                      , JE.bool model.isConfigOpen
                      )
                    ]
              )
            ]


view : Model -> Html Msg
view model =
    E.layout
        [ E.inFront <| viewConfig model
        , E.inFront <| viewMessages model
        , E.width E.fill
        , E.height E.fill
        , E.padding 20
        ]
        (E.row
            [ E.spacing 10
            ]
            [ viewLandscape model
            , viewControlButtons model
            ]
        )


viewControlButtons : Model -> Element Msg
viewControlButtons model =
    E.column
        [ E.spacing 10
        , E.alignTop
        ]
        [ EInput.button
            [ E.paddingXY 20 10
            , E.pointer
            , EFont.size 24
            , EBackground.color (E.rgb 0.9 0.9 0.5)
            , EBorder.width 2
            , EBorder.rounded 5
            ]
            { onPress = Just ClickedStep
            , label =
                E.text "Step"
            }
        , EInput.button
            [ E.paddingXY 20 10
            , E.pointer
            , EFont.size 24
            , EBackground.color (E.rgb 0.9 0.9 0.5)
            , EBorder.width 2
            , EBorder.rounded 5
            ]
            { onPress = Just ClickedAutoStep
            , label =
                if model.autostep then
                    E.text "Turn off auto-step"

                else
                    E.text "Turn on auto-step"
            }
        ]


viewMessages : Model -> Element Msg
viewMessages model =
    let
        messages =
            []
    in
    if List.isEmpty messages then
        E.none

    else
        E.column
            [ EBackground.color (E.rgba 1 1 1 0.8)
            , EBorder.color (E.rgba 0.5 0.5 0.5 1)
            , EBorder.width 1
            , E.padding 10
            , E.moveDown 30
            , E.moveRight 30
            ]
            (messages
                |> List.map
                    (\message ->
                        E.text message
                    )
            )


viewConfig : Model -> Element Msg
viewConfig ({ config } as model) =
    E.el
        [ E.alignRight
        , E.padding 20
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
                (if model.isConfigOpen then
                    [ EInput.button
                        [ E.alignRight
                        ]
                        { onPress = Just ClickedCloseConfig
                        , label =
                            E.el
                                [ EFont.underline
                                ]
                                (E.text "Close Config")
                        }
                    , ConfigForm.viewElement
                        (ConfigForm.viewOptions
                            |> ConfigForm.withRowSpacing config.configRowSpacing
                            |> ConfigForm.withLabelHighlightBgColor config.configLabelHighlightBgColor
                            |> ConfigForm.withInputWidth config.configInputWidth
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

                 else
                    [ EInput.button
                        []
                        { onPress = Just ClickedOpenConfig
                        , label = E.el [ EFont.underline ] (E.text "Open Config")
                        }
                    ]
                )
            )
        )


viewLandscape : Model -> Element Msg
viewLandscape ({ config } as model) =
    Svg.svg
        [ Svg.Attributes.width "100%"
        , Svg.Attributes.height "100%"
        ]
        [ -- sky
          Svg.rect
            [ Svg.Attributes.x "0"
            , Svg.Attributes.y "0"
            , Svg.Attributes.width "100%"
            , Svg.Attributes.height "100%"
            , Svg.Attributes.fill (Color.toCssString config.skyColor)
            ]
            []

        -- ground
        , Svg.rect
            [ Svg.Attributes.x "0"
            , Svg.Attributes.y <| pxInt <| config.viewportHeight - config.groundHeight
            , Svg.Attributes.width "100%"
            , Svg.Attributes.height <| pxInt config.groundHeight
            , Svg.Attributes.fill (Color.toCssString config.groundColor)
            ]
            []

        -- tree
        , Tree.toSvg
            { cloudPointRad = config.cloudPointRad
            , cloudPointColor = config.cloudPointColor
            , treeColor = config.treeColor
            , branchThickness = config.branchThickness
            }
            model.tree
        ]
        |> E.html
        |> E.el
            [ E.width <| E.px <| config.viewportWidth
            , E.height <| E.px <| config.viewportHeight
            , EBorder.width 1
            , EBorder.color (E.rgb 0 0 0)
            ]


percFloat : Float -> String
percFloat val =
    String.fromFloat val ++ "%"


pxInt : Int -> String
pxInt val =
    String.fromInt val ++ "px"


pxFloat : Float -> String
pxFloat val =
    String.fromFloat val ++ "px"


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ receiveFromPort ReceivedFromPort
        , if model.autostep then
            Browser.Events.onAnimationFrameDelta Tick

          else
            Sub.none
        ]


colorForE : Color -> E.Color
colorForE color =
    color
        |> Color.toRgba
        |> (\{ red, green, blue, alpha } ->
                E.rgba red green blue alpha
           )