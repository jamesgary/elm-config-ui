port module Main exposing (main)

import Browser
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
import Svg exposing (Svg)
import Svg.Attributes


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
    }


type Msg
    = ConfigFormMsg (ConfigForm.Msg Config)
    | ReceivedFromPort JE.Value
    | ClickedOpenConfig
    | ClickedCloseConfig



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
        (viewLandscape model)


viewMessages : Model -> Element Msg
viewMessages model =
    let
        totalBranches =
            model.config.numBranches ^ model.config.branchRecursions

        messages =
            if totalBranches > model.config.maxBranches then
                [ "Max branches exceeded! "
                , String.fromInt model.config.numBranches
                , " branches ^ "
                , String.fromInt model.config.branchRecursions
                , " recursions = "
                , String.fromInt totalBranches
                , " branches (max is "
                , String.fromInt model.config.maxBranches
                , ")"
                ]
                    |> String.join ""
                    |> List.singleton

            else
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


hasSafeRecursionsExceeded : Model -> Bool
hasSafeRecursionsExceeded model =
    model.config.numBranches ^ model.config.branchRecursions > model.config.maxBranches


viewLandscape : Model -> Element Msg
viewLandscape ({ config } as model) =
    let
        getSafeRecursions numRec =
            if config.numBranches ^ numRec > config.maxBranches then
                getSafeRecursions (numRec - 1)

            else
                numRec

        safeRecursions =
            getSafeRecursions config.branchRecursions
    in
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

        -- tree trunk
        , Svg.line
            [ Svg.Attributes.x1 <| pxInt <| config.viewportWidth // 2
            , Svg.Attributes.y1 <| pxInt <| config.viewportHeight - config.groundHeight
            , Svg.Attributes.x2 <| pxInt <| config.viewportWidth // 2
            , Svg.Attributes.y2 <| pxInt <| config.viewportHeight - config.groundHeight - config.treeTrunkHeight
            , Svg.Attributes.stroke (Color.toCssString config.treeColor)
            , Svg.Attributes.strokeWidth <| pxInt <| config.treeTrunkWidth
            ]
            []

        -- tree branches
        , Svg.g []
            (viewBranches
                config
                ( toFloat config.viewportWidth / 2
                , toFloat <| config.viewportHeight - config.groundHeight - config.treeTrunkHeight
                )
                (-pi / 2)
                (toFloat config.treeTrunkHeight)
                (toFloat config.treeTrunkWidth)
                config.numBranches
                safeRecursions
            )
        ]
        |> E.html
        |> E.el
            [ E.width <| E.px <| config.viewportWidth
            , E.height <| E.px <| config.viewportHeight
            , EBorder.width 1
            , EBorder.color (E.rgb 0 0 0)
            ]


viewBranches : Config -> ( Float, Float ) -> Float -> Float -> Float -> Int -> Int -> List (Svg Msg)
viewBranches config ( x, y ) direction length width numBranches branchRecursions =
    if branchRecursions <= 0 then
        []

    else
        List.range 0 (numBranches - 1)
            |> List.map
                (\i ->
                    let
                        progress =
                            if numBranches <= 1 then
                                0.5

                            else
                                toFloat i / toFloat (numBranches - 1)

                        newLength =
                            length * config.branchLengthPerc / 100

                        newWidth =
                            width * config.branchWidthPerc / 100

                        angleRange =
                            degrees config.branchAngleRangeDegs

                        angle =
                            direction + (-0.5 * angleRange + (progress * angleRange))

                        ( xOffset, yOffset ) =
                            fromPolar ( newLength, angle )
                    in
                    Svg.line
                        [ Svg.Attributes.x1 <| pxFloat <| x
                        , Svg.Attributes.y1 <| pxFloat <| y
                        , Svg.Attributes.x2 <| pxFloat <| x + xOffset
                        , Svg.Attributes.y2 <| pxFloat <| y + yOffset
                        , Svg.Attributes.stroke (Color.toCssString config.treeColor)
                        , Svg.Attributes.strokeWidth <| pxFloat <| newWidth
                        ]
                        []
                        :: viewBranches config ( x + xOffset, y + yOffset ) angle newLength newWidth numBranches (branchRecursions - 1)
                )
            |> List.concat


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
        ]


colorForE : Color -> E.Color
colorForE color =
    color
        |> Color.toRgba
        |> (\{ red, green, blue, alpha } ->
                E.rgba red green blue alpha
           )
