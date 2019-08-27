module ConfigForm exposing
    ( ConfigForm, init, InitOptions, Defaults
    , Msg
    , update, updateFromJson
    , encode, encodeConfigForm
    , view
    , viewOptions, withRowSpacing, withLabelHighlightBgColor, withInputWidth, withInputHeight, withFontSize
    , int, float, string, bool, color, section
    )

{-|


# Main stuff

@docs ConfigForm, init, InitOptions, Defaults


# Msg

@docs Msg


# Update

@docs update, updateFromJson


# Encoding

@docs encode, encodeConfigForm


# View

@docs view


# View options

@docs viewOptions, withRowSpacing, withLabelHighlightBgColor, withInputWidth, withInputHeight, withFontSize


# Used only by generated Config code

@docs int, float, string, bool, color, section

-}

import Color exposing (Color)
import ColorPicker
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes exposing (style)
import Html.Events
import Html.Events.Extra.Pointer as Pointer
import Json.Decode as JD
import Json.Decode.Pipeline as JDP
import Json.Encode as JE
import OrderedDict exposing (OrderedDict)
import Round


{-| ConfigForm is the state of the config form. Keep it in your model along with the regular `config` record. TODO make opaque
-}
type alias ConfigForm config =
    { file : config -- unused for now
    , fields : OrderedDict String Field
    , changingField : Maybe String
    , scrollTop : Int -- also unused
    , undoStack : List ( String, Field ) -- also unused
    }


{-| Field
-}
type Field
    = IntField IntFieldData
    | FloatField FloatFieldData
    | StringField StringFieldData
    | BoolField BoolFieldData
    | ColorField ColorFieldData
    | SectionField String


type alias IntFieldData =
    { val : Int
    , str : String
    , power : Int
    }


type alias FloatFieldData =
    { val : Float
    , str : String
    , power : Int
    }


type alias StringFieldData =
    { val : String
    }


type alias BoolFieldData =
    { val : Bool
    }


type alias ColorFieldData =
    { val : Color
    , meta : ColorFieldMeta
    }


type ColorFieldMeta
    = ColorFieldMeta
        { state : ColorPicker.State
        , isOpen : Bool
        }


type alias Flags =
    { configJson : JE.Value -- currently unused
    , configFormJson : JE.Value
    , defaults : Defaults
    }


{-| If a particular value isn't found from localStorage or file, then it fallbacks to these values. It might be a good idea to use wild values that are easy to spot so you can quickly replace them with real values.

    defaults =
        { int = -9999
        , float = -9999
        , string = "PLEASE REPLACE ME"
        , bool = True
        , color = Color.rgb 1 0 1 -- hot pink
        }

-}
type alias Defaults =
    { int : Int
    , float : Float
    , string : String
    , bool : Bool
    , color : Color
    }


{-| InitOptions are used to initialize your config and ConfigForm.

    { configJson = flags.configFile
    , configFormJson = flags.localStorage.json
    , logics = Config.logics
    , emptyConfig = Config.empty
    }

-}
type alias InitOptions config =
    { configJson : JE.Value
    , configFormJson : JE.Value
    , logics : List (Logic config)
    , emptyConfig : config
    }


{-| `init` will create both a valid `Config` and `ConfigForm`.
-}
init : InitOptions config -> ( config, ConfigForm config )
init options =
    let
        config =
            decodeConfig
                options.logics
                options.emptyConfig
                options.configJson

        configForm =
            decodeConfigForm
                options.logics
                config
                options.configFormJson
    in
    ( configFromConfigForm options.logics configForm.fields config
    , configForm
    )



-- STUFF NEEDED ONLY BY GENERATED CONFIG STUFF
{- Logic stuff. Never persist Logic in your model! -}


type alias Logic config =
    { fieldName : String
    , label : String
    , kind : LogicKind config
    }


type LogicKind config
    = IntLogic (config -> Int) (Int -> config -> config)
    | FloatLogic (config -> Float) (Float -> config -> config)
    | StringLogic (config -> String) (String -> config -> config)
    | ColorLogic (config -> Color) (Color -> config -> config)
    | BoolLogic (config -> Bool) (Bool -> config -> config)
    | SectionLogic


{-| Creates the logic for Int values
-}
int : String -> String -> (config -> Int) -> (Int -> config -> config) -> Logic config
int fieldName label getter setter =
    { fieldName = fieldName
    , label = label
    , kind = IntLogic getter setter
    }


{-| Creates the logic for Float values
-}
float : String -> String -> (config -> Float) -> (Float -> config -> config) -> Logic config
float fieldName label getter setter =
    { fieldName = fieldName
    , label = label
    , kind = FloatLogic getter setter
    }


{-| Creates the logic for String values
-}
string : String -> String -> (config -> String) -> (String -> config -> config) -> Logic config
string fieldName label getter setter =
    { fieldName = fieldName
    , label = label
    , kind = StringLogic getter setter
    }


{-| Creates the logic for Bool values
-}
bool : String -> String -> (config -> Bool) -> (Bool -> config -> config) -> Logic config
bool fieldName label getter setter =
    { fieldName = fieldName
    , label = label
    , kind = BoolLogic getter setter
    }


{-| Creates the logic for Color values
-}
color : String -> String -> (config -> Color) -> (Color -> config -> config) -> Logic config
color fieldName label getter setter =
    { fieldName = fieldName
    , label = label
    , kind = ColorLogic getter setter
    }


{-| Creates the logic for Section values
-}
section : String -> Logic config
section sectionStr =
    { fieldName = ""
    , label = sectionStr
    , kind = SectionLogic
    }


{-| A Msg is an opaque type for ConfigForm to communicate with your app through ConfigForm.update.
-}
type Msg config
    = ChangedConfigForm String Field
    | ClickedPointerLockLabel String


{-| Encodes the current Config in your ConfigForm. This encode just the config itself, so it's usually used to be save to a json file and added to your version control.
-}
encode : List (Logic config) -> config -> JE.Value
encode logics config =
    logics
        |> List.filterMap
            (\logic ->
                case logic.kind of
                    IntLogic getter _ ->
                        Just
                            ( logic.fieldName
                            , JE.int (getter config)
                            )

                    FloatLogic getter _ ->
                        Just
                            ( logic.fieldName
                            , JE.float (getter config)
                            )

                    StringLogic getter _ ->
                        Just
                            ( logic.fieldName
                            , JE.string (getter config)
                            )

                    BoolLogic getter _ ->
                        Just
                            ( logic.fieldName
                            , JE.bool (getter config)
                            )

                    ColorLogic getter _ ->
                        Just
                            ( logic.fieldName
                            , getter config
                                |> encodeColor
                            )

                    SectionLogic ->
                        Nothing
            )
        |> JE.object


encodeColor : Color -> JE.Value
encodeColor col =
    col
        |> Color.toRgba
        |> (\{ red, green, blue, alpha } ->
                JE.object
                    [ ( "r", JE.float red )
                    , ( "g", JE.float green )
                    , ( "b", JE.float blue )
                    , ( "a", JE.float alpha )
                    ]
           )


{-| Encodes the current data of your config form to be persisted, including meta-data. This is typically used to save to localStorage.
-}
encodeConfigForm : ConfigForm config -> JE.Value
encodeConfigForm configForm =
    {-
       do i even need a config at all?
       does configform even need config?
       only need it for view...
    -}
    JE.object
        [ ( "fields", encodeFields configForm.fields )
        , ( "scrollTop", JE.int configForm.scrollTop )
        ]


encodeFields : OrderedDict String Field -> JE.Value
encodeFields fields =
    fields
        |> OrderedDict.toList
        |> List.filterMap
            (\( fieldName, field ) ->
                case encodeField field of
                    Just json ->
                        Just
                            ( fieldName
                            , json
                            )

                    Nothing ->
                        Nothing
            )
        |> JE.object


tuple2Encoder : (a -> JE.Value) -> (b -> JE.Value) -> ( a, b ) -> JE.Value
tuple2Encoder enc1 enc2 ( val1, val2 ) =
    -- from https://stackoverflow.com/a/52676142
    JE.list identity [ enc1 val1, enc2 val2 ]


encodeField : Field -> Maybe JE.Value
encodeField field =
    case field of
        IntField data ->
            -- TODO be able to encode w/o dev data like power
            ( data.val, data.power )
                |> tuple2Encoder JE.int JE.int
                |> Just

        FloatField data ->
            -- TODO be able to encode w/o dev data like power
            ( data.val, data.power )
                |> tuple2Encoder JE.float JE.int
                |> Just

        StringField data ->
            JE.string data.val
                |> Just

        BoolField data ->
            JE.bool data.val
                |> Just

        ColorField data ->
            encodeColor data.val
                |> Just

        SectionField _ ->
            Nothing


{-| When you receive a Config.Msg, update your `Config` and `ConfigForm` using this. It returns a new `Config` and `ConfigForm`, plus possible json to pass through ports for pointerlock.

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
                                (Json.Encode.object
                                    [ ( "id", Json.Encode.string "CONFIG" )
                                    , ( "val", jsonCmd )
                                    ]
                                )

                        Nothing ->
                            Cmd.none
                    ]
                )

-}
update : List (Logic config) -> config -> ConfigForm config -> Msg config -> ( config, ConfigForm config, Maybe JE.Value )
update logics config configForm msg =
    case msg of
        ChangedConfigForm fieldName field ->
            let
                newConfigForm =
                    configForm.fields
                        |> OrderedDict.insert fieldName field
            in
            ( configFromConfigForm logics newConfigForm config
            , { configForm
                | fields = newConfigForm
              }
            , Nothing
            )

        ClickedPointerLockLabel fieldName ->
            ( config
            , { configForm | changingField = Just fieldName }
            , Just (JE.string "LOCK_POINTER")
            )


configFromConfigForm : List (Logic config) -> OrderedDict String Field -> config -> config
configFromConfigForm logics configForm config =
    logics
        |> List.foldl
            (\logic newConfig ->
                let
                    maybeField =
                        OrderedDict.get logic.fieldName configForm
                in
                case ( maybeField, logic.kind ) of
                    ( Just (IntField data), IntLogic getter setter ) ->
                        setter data.val newConfig

                    ( Just (FloatField data), FloatLogic getter setter ) ->
                        setter data.val newConfig

                    ( Just (StringField data), StringLogic getter setter ) ->
                        setter data.val newConfig

                    ( Just (BoolField data), BoolLogic getter setter ) ->
                        setter data.val newConfig

                    ( Just (ColorField data), ColorLogic getter setter ) ->
                        setter data.val newConfig

                    _ ->
                        newConfig
            )
            config


{-| Similar to `update`, but for port Msgs.

When you receive a Msg through your port from elm-config-gui.js, update your `Config` and `ConfigForm` using this. It returns a new `Config` and `ConfigForm`, plus possible json to pass through ports for pointerlock.

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ReceivedFromPort portJson ->
                case Json.Decode.decodeValue fromPortDecoder portJson of
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
                                                (Json.Encode.object
                                                    [ ( "id", Json.Encode.string "CONFIG" )
                                                    , ( "val", jsonCmd )
                                                    ]
                                                )

                                        Nothing ->
                                            Cmd.none
                                    ]
                                )

-}
updateFromJson : List (Logic config) -> config -> ConfigForm config -> JE.Value -> ( config, ConfigForm config, Maybe JE.Value )
updateFromJson logics config configForm json =
    case JD.decodeValue portDecoder json of
        Ok portMsg ->
            case portMsg of
                MouseMove num ->
                    let
                        newConfigForm =
                            case configForm.changingField of
                                Just fieldName ->
                                    { configForm
                                        | fields =
                                            configForm.fields
                                                |> OrderedDict.update fieldName
                                                    (\maybeField ->
                                                        case maybeField of
                                                            Just (IntField data) ->
                                                                let
                                                                    newVal =
                                                                        data.val + (num * (10 ^ data.power))
                                                                in
                                                                Just
                                                                    (IntField
                                                                        { data
                                                                            | val = newVal
                                                                            , str = formatPoweredInt data.power newVal
                                                                        }
                                                                    )

                                                            Just (FloatField data) ->
                                                                let
                                                                    newVal =
                                                                        data.val + toFloat (num * (10 ^ data.power))
                                                                in
                                                                Just
                                                                    (FloatField
                                                                        { data
                                                                            | val = newVal
                                                                            , str = formatPoweredFloat data.power newVal
                                                                        }
                                                                    )

                                                            _ ->
                                                                Nothing
                                                    )
                                    }

                                Nothing ->
                                    configForm
                    in
                    ( configFromConfigForm
                        logics
                        newConfigForm.fields
                        config
                    , newConfigForm
                    , Nothing
                    )

                MouseUp ->
                    ( config
                    , { configForm | changingField = Nothing }
                    , Nothing
                    )

        Err err ->
            let
                _ =
                    --Debug.log
                    --    "Could not decode incoming config port msg: "
                    --    (JD.errorToString err)
                    0
            in
            ( config, configForm, Nothing )


type PortMsg
    = MouseMove Int
    | MouseUp


portDecoder : JD.Decoder PortMsg
portDecoder =
    JD.field "id" JD.string
        |> JD.andThen
            (\id ->
                case id of
                    "MOUSE_MOVE" ->
                        JD.field "x" JD.int
                            |> JD.map MouseMove

                    "MOUSE_UP" ->
                        JD.succeed MouseUp

                    _ ->
                        JD.fail ("Could not decode ConfigForm port msg id: " ++ id)
            )


formatPoweredInt : Int -> Int -> String
formatPoweredInt power val =
    Round.round -power (toFloat val)


formatPoweredFloat : Int -> Float -> String
formatPoweredFloat power val =
    Round.round -power val


poweredInt : Int -> Int -> Int
poweredInt power val =
    round <| Round.roundNum -power (toFloat val)


poweredFloat : Int -> Float -> Float
poweredFloat power val =
    Round.roundNum -power val


decodeConfigForm : List (Logic config) -> config -> JE.Value -> ConfigForm config
decodeConfigForm logics config json =
    { file = config
    , fields =
        logics
            |> List.map
                (\logic ->
                    ( logic.fieldName
                    , case logic.kind of
                        IntLogic getter setter ->
                            let
                                decoder =
                                    JD.at [ "fields", logic.fieldName ]
                                        (JD.oneOf
                                            [ JD.int
                                                |> JD.map
                                                    (\i ->
                                                        -- got a prod val
                                                        ( i, 0 )
                                                    )
                                            , JD.map2 Tuple.pair
                                                (JD.index 0 JD.int)
                                                (JD.index 1 JD.int)
                                            ]
                                        )

                                ( val, power ) =
                                    case JD.decodeValue decoder json of
                                        Ok v ->
                                            v

                                        Err err ->
                                            ( getter config, 0 )
                            in
                            IntField
                                { val = val
                                , str = formatPoweredInt power val
                                , power = power
                                }

                        FloatLogic getter setter ->
                            let
                                decoder =
                                    JD.at [ "fields", logic.fieldName ]
                                        (JD.oneOf
                                            [ JD.float
                                                |> JD.map
                                                    (\f ->
                                                        -- got a prod val
                                                        ( f, 0 )
                                                    )
                                            , JD.map2 Tuple.pair
                                                (JD.index 0 JD.float)
                                                (JD.index 1 JD.int)
                                            ]
                                        )

                                ( val, power ) =
                                    case JD.decodeValue decoder json of
                                        Ok v ->
                                            v

                                        Err err ->
                                            ( getter config, 0 )
                            in
                            FloatField
                                { val = val
                                , str = formatPoweredFloat power val
                                , power = power
                                }

                        StringLogic getter setter ->
                            let
                                decoder =
                                    JD.at [ "fields", logic.fieldName ] JD.string

                                val =
                                    case JD.decodeValue decoder json of
                                        Ok v ->
                                            v

                                        Err err ->
                                            getter config
                            in
                            StringField
                                { val = val
                                }

                        BoolLogic getter setter ->
                            let
                                decoder =
                                    JD.at [ "fields", logic.fieldName ] JD.bool

                                val =
                                    case JD.decodeValue decoder json of
                                        Ok v ->
                                            v

                                        Err err ->
                                            getter config
                            in
                            BoolField
                                { val = val
                                }

                        ColorLogic getter setter ->
                            let
                                decoder =
                                    JD.at [ "fields", logic.fieldName ] colorValDecoder

                                val =
                                    case JD.decodeValue decoder json of
                                        Ok v ->
                                            v

                                        Err err ->
                                            getter config
                            in
                            ColorField
                                { val = val
                                , meta =
                                    ColorFieldMeta
                                        { state = ColorPicker.empty
                                        , isOpen = False
                                        }
                                }

                        SectionLogic ->
                            SectionField logic.fieldName
                    )
                )
            |> OrderedDict.fromList
    , changingField = Nothing
    , scrollTop =
        case JD.decodeValue (JD.field "scrollTop" JD.int) json of
            Ok scrollTop ->
                scrollTop

            Err _ ->
                0
    , undoStack = []
    }



-- JSON encode/decoder stuff


decodeConfig : List (Logic config) -> config -> JE.Value -> config
decodeConfig logics emptyConfig configJson =
    logics
        |> List.foldl
            (\logic config ->
                case logic.kind of
                    IntLogic getter setter ->
                        case JD.decodeValue (JD.field logic.fieldName JD.int) configJson of
                            Ok intVal ->
                                setter intVal config

                            Err err ->
                                config

                    FloatLogic getter setter ->
                        case JD.decodeValue (JD.field logic.fieldName JD.float) configJson of
                            Ok floatVal ->
                                setter floatVal config

                            Err err ->
                                config

                    StringLogic getter setter ->
                        case JD.decodeValue (JD.field logic.fieldName JD.string) configJson of
                            Ok str ->
                                setter str config

                            Err err ->
                                config

                    BoolLogic getter setter ->
                        case JD.decodeValue (JD.field logic.fieldName JD.bool) configJson of
                            Ok str ->
                                setter str config

                            Err err ->
                                config

                    ColorLogic getter setter ->
                        case JD.decodeValue (JD.field logic.fieldName colorValDecoder) configJson of
                            Ok col ->
                                setter col config

                            Err err ->
                                config

                    SectionLogic ->
                        config
            )
            emptyConfig


colorValDecoder : JD.Decoder Color
colorValDecoder =
    JD.map4 Color.rgba
        (JD.field "r" JD.float)
        (JD.field "g" JD.float)
        (JD.field "b" JD.float)
        (JD.field "a" JD.float)



-- VIEW


{-| View the config form.
-}
view : ViewOptions -> List (Logic config) -> ConfigForm config -> Html (Msg config)
view options logics configForm =
    Html.table []
        (logics
            |> List.indexedMap
                (\i logic ->
                    Html.tr []
                        [ viewLabel options configForm i logic
                        , viewChanger options configForm i logic
                        ]
                )
        )


viewLabel : ViewOptions -> ConfigForm config -> Int -> Logic config -> Html (Msg config)
viewLabel options configForm i logic =
    let
        defaultAttrs =
            --[ style "vertical-align" "center" ]
            [ style "height" "100%" ]
    in
    Html.td
        (defaultAttrs
            ++ (case logic.kind of
                    StringLogic getter setter ->
                        []

                    IntLogic getter setter ->
                        resizeAttrs options configForm logic

                    FloatLogic getter setter ->
                        resizeAttrs options configForm logic

                    BoolLogic getter setter ->
                        []

                    ColorLogic getter setter ->
                        closeAttrs options configForm i logic

                    SectionLogic ->
                        [ style "font-weight" "bold"
                        , style "padding" "20px 0 5px 0"
                        , Html.Attributes.colspan 2
                        ]
               )
        )
        [ Html.text logic.label ]


closeAttrs : ViewOptions -> ConfigForm config -> Int -> Logic config -> List (Html.Attribute (Msg config))
closeAttrs options configForm i logic =
    let
        maybeCloseMsg =
            case OrderedDict.get logic.fieldName configForm.fields of
                Just (ColorField data) ->
                    let
                        shouldShow =
                            case data.meta of
                                ColorFieldMeta meta ->
                                    meta.isOpen
                    in
                    if shouldShow then
                        let
                            meta =
                                case data.meta of
                                    ColorFieldMeta m ->
                                        m
                        in
                        Just
                            (ChangedConfigForm
                                logic.fieldName
                                (ColorField
                                    { data
                                        | meta =
                                            ColorFieldMeta
                                                { meta
                                                    | isOpen = False
                                                }
                                    }
                                )
                            )

                    else
                        Nothing

                _ ->
                    Nothing
    in
    case maybeCloseMsg of
        Just msg ->
            [-- E.inFront <|
             --   E.el
             --       [ E.width E.fill
             --       , E.padding 6
             --       ]
             --       (EInput.button
             --           [ E.alignRight
             --           , EBackground.color (E.rgba 1 1 1 0.9)
             --           , EBorder.color (E.rgba 0 0 0 0.9)
             --           , EBorder.width 1
             --           , EBorder.rounded 4
             --           , E.width (E.px (1.5 * toFloat options.fontSize |> round))
             --           , E.height (E.px (1.5 * toFloat options.fontSize |> round))
             --           , Html.Attributes.tabindex (1 + i) |> E.htmlAttribute
             --           ]
             --           { onPress = Just msg
             --           , label =
             --               E.el
             --                   [ E.centerX
             --                   , E.centerY
             --                   , E.paddingEach
             --                       { top = 3
             --                       , right = 0
             --                       , bottom = 0
             --                       , left = 2
             --                       }
             --                   ]
             --                   (E.text "❌")
             --           }
             --       )
            ]

        Nothing ->
            []


resizeAttrs : ViewOptions -> ConfigForm config -> Logic config -> List (Html.Attribute (Msg config))
resizeAttrs options configForm logic =
    let
        makePowerEl power newIncField newDecField isDownDisabled =
            Html.div
                [ style "text-align" "right"
                , style "top" "-6px" -- E.moveDown 6
                , style "padding" "5px 2px" --E.paddingXY 5 2

                --, style "font-size" "16px" --EFont.size 16
                ]
                [ Html.span
                    [ style "padding" "5px 0"
                    ]
                    -- label
                    [ Html.text ("x" ++ String.fromInt (10 ^ power)) ]
                , Html.span
                    [ --style "font-size" (0.8 * toFloat options.fontSize |> px)
                      style "top" "1px"
                    , Pointer.onWithOptions "pointerdown"
                        { stopPropagation = True
                        , preventDefault = True
                        }
                        (\_ -> ChangedConfigForm logic.fieldName newIncField)
                    , if isDownDisabled then
                        style "opacity" "0.4"

                      else
                        style "cursor" "pointer"
                    ]
                    -- down btn
                    [ Html.text "↙️" ]
                , Html.span
                    [ --style "font-size" (0.8 * toFloat options.fontSize |> px)
                      style "top" "1px"
                    , Pointer.onWithOptions "pointerdown"
                        { stopPropagation = True
                        , preventDefault = True
                        }
                        (\_ -> ChangedConfigForm logic.fieldName newDecField)
                    , style "cursor" "pointer"
                    ]
                    -- up btn
                    [ Html.text "↗️" ]
                ]

        powerEl =
            case OrderedDict.get logic.fieldName configForm.fields of
                Just (IntField data) ->
                    makePowerEl data.power
                        (IntField
                            { data
                                | power = data.power - 1 |> max 0
                                , str = formatPoweredInt (data.power - 1 |> max 0) data.val
                                , val = poweredInt (data.power - 1 |> max 0) data.val
                            }
                        )
                        (IntField
                            { data
                                | power = data.power + 1
                                , str = formatPoweredInt (data.power + 1) data.val
                                , val = poweredInt (data.power + 1) data.val
                            }
                        )
                        (data.power <= 0)

                Just (FloatField data) ->
                    makePowerEl data.power
                        (FloatField
                            { data
                                | power = data.power - 1
                                , str = formatPoweredFloat (data.power - 1) data.val
                                , val = poweredFloat (data.power - 1) data.val
                            }
                        )
                        (FloatField
                            { data
                                | power = data.power + 1
                                , str = formatPoweredFloat (data.power + 1) data.val
                                , val = poweredFloat (data.power + 1) data.val
                            }
                        )
                        False

                _ ->
                    Html.text ""
    in
    [ Html.Events.onMouseDown (ClickedPointerLockLabel logic.fieldName)
    , style "cursor" "ew-resize"

    --, Html.Events.onMouseOver (HoveredLabel logic.fieldName)
    --[ style "background" (Color.toCssString options.labelHighlightBgColor)
    --]
    , style "width" "100%"
    , style "height" "100%"

    -- TODOOOOOOOOOOOOOOOOO ??????????
    -- TODOOOOOOOOOOOOOOOOO ??????????
    -- TODOOOOOOOOOOOOOOOOO ??????????
    --, E.inFront
    --    (E.el
    --        [ E.width E.fill
    --        , E.height E.fill
    --        , E.transparent True
    --        , E.mouseOver
    --            [ E.transparent False
    --            ]
    --        ]
    --        powerEl
    --    )
    --, style "padding-right" "80px"
    ]


viewChanger : ViewOptions -> ConfigForm config -> Int -> Logic config -> Html (Msg config)
viewChanger options configForm i logic =
    let
        defaultAttrs =
            [ style "width" (pxInt options.inputWidth)
            , style "height" (pxInt options.inputHeight)
            ]

        tabAttrs =
            [ Html.Attributes.tabindex (1 + i)
            ]

        incrementalAttrs strToNum wrapper data =
            [ Html.Events.on "keydown"
                (JD.map
                    (\key ->
                        let
                            maybeNewNum =
                                case key of
                                    38 ->
                                        Just <| data.val + 1

                                    40 ->
                                        Just <| data.val - 1

                                    _ ->
                                        Nothing
                        in
                        ChangedConfigForm logic.fieldName
                            (wrapper
                                (case maybeNewNum of
                                    Just newNum ->
                                        { data
                                            | val = newNum
                                            , str = strToNum newNum
                                        }

                                    Nothing ->
                                        data
                                )
                            )
                    )
                    Html.Events.keyCode
                )
            ]

        maybeField =
            OrderedDict.get logic.fieldName configForm.fields

        colspan =
            case maybeField of
                Just (SectionField _) ->
                    0

                _ ->
                    1
    in
    case maybeField of
        Just (StringField data) ->
            Html.td []
                [ textInputHelper
                    { label = logic.label
                    , valStr = data.val
                    , attrs = defaultAttrs ++ tabAttrs
                    , setterMsg =
                        \newStr ->
                            ChangedConfigForm
                                logic.fieldName
                                (StringField { data | val = newStr })
                    }
                ]

        Just (BoolField data) ->
            Html.td []
                [ Html.input
                    (defaultAttrs
                        ++ tabAttrs
                        ++ [ Html.Attributes.type_ "checkbox"
                           , Html.Attributes.checked data.val
                           , Html.Events.onCheck
                                (\newBool ->
                                    ChangedConfigForm
                                        logic.fieldName
                                        (BoolField { data | val = newBool })
                                )
                           ]
                    )
                    []
                ]

        Just (IntField data) ->
            Html.td []
                [ textInputHelper
                    { label = logic.label
                    , valStr = data.str
                    , attrs =
                        defaultAttrs
                            ++ tabAttrs
                            ++ incrementalAttrs String.fromInt IntField data
                            ++ (if String.toInt data.str == Nothing then
                                    [ style "background" "1,0,0,0.3)" ]

                                else
                                    []
                               )
                    , setterMsg =
                        \newStr ->
                            ChangedConfigForm
                                logic.fieldName
                            <|
                                IntField
                                    { data
                                        | str = newStr
                                        , val =
                                            case String.toInt newStr of
                                                Just num ->
                                                    num

                                                Nothing ->
                                                    data.val
                                    }
                    }
                ]

        Just (FloatField data) ->
            Html.td []
                [ textInputHelper
                    { label = logic.label
                    , valStr = data.str
                    , attrs =
                        defaultAttrs
                            ++ tabAttrs
                            ++ incrementalAttrs String.fromFloat FloatField data
                            ++ (if String.toFloat data.str == Nothing then
                                    [ style "background" "rgba(1,0,0,0.3)" ]

                                else
                                    []
                               )
                    , setterMsg =
                        \newStr ->
                            ChangedConfigForm
                                logic.fieldName
                            <|
                                FloatField
                                    { data
                                        | str = newStr
                                        , val =
                                            case String.toFloat newStr of
                                                Just num ->
                                                    num

                                                Nothing ->
                                                    data.val
                                    }
                    }
                ]

        Just (ColorField data) ->
            let
                meta =
                    case data.meta of
                        ColorFieldMeta m ->
                            m
            in
            Html.td []
                [ if meta.isOpen then
                    ColorPicker.view
                        data.val
                        meta.state
                        |> Html.map
                            (\pickerMsg ->
                                let
                                    ( newPickerState, newColor ) =
                                        ColorPicker.update
                                            pickerMsg
                                            data.val
                                            meta.state
                                in
                                ChangedConfigForm logic.fieldName
                                    (ColorField
                                        { data
                                            | val = newColor |> Maybe.withDefault data.val
                                            , meta =
                                                ColorFieldMeta
                                                    { state = newPickerState
                                                    , isOpen = meta.isOpen
                                                    }
                                        }
                                    )
                            )

                  else
                    Html.div
                        (defaultAttrs
                            ++ [ style "background" (Color.toCssString data.val)
                               , style "width" "100%"
                               , style "border" "1px solid rgba(0,0,0,0.3)"
                               , style "border-radius" "3px"
                               , Html.Events.onMouseDown
                                    (ChangedConfigForm
                                        logic.fieldName
                                        (ColorField
                                            { data
                                                | meta =
                                                    ColorFieldMeta
                                                        { state = meta.state
                                                        , isOpen = True
                                                        }
                                            }
                                        )
                                    )
                               ]
                        )
                        []
                ]

        Just (SectionField str) ->
            Html.text ""

        Nothing ->
            Html.text ""


textInputHelper :
    { label : String
    , valStr : String
    , attrs : List (Html.Attribute (Msg config))
    , setterMsg : String -> Msg config
    }
    -> Html (Msg config)
textInputHelper { label, valStr, attrs, setterMsg } =
    Html.input
        ([ Html.Attributes.value valStr
         , Html.Events.onInput setterMsg
         , style "font-size" "inherit"
         , style "padding" "0px 8px"
         ]
            ++ attrs
        )
        []



-- VIEW OPTIONS


{-| Options for viewing the config form.
-}
type alias ViewOptions =
    { fontSize : Int
    , rowSpacing : Int
    , inputWidth : Int
    , inputHeight : Int
    , labelHighlightBgColor : Color
    , sectionSpacing : Int
    }


{-| Default options for viewing the config form.
-}
viewOptions : ViewOptions
viewOptions =
    { fontSize = 24
    , rowSpacing = 5
    , inputWidth = 200
    , inputHeight = 34
    , labelHighlightBgColor = Color.rgb 0.8 0.8 1
    , sectionSpacing = 20
    }


{-| Update the row spacing.
-}
withRowSpacing : Int -> ViewOptions -> ViewOptions
withRowSpacing val options =
    { options | rowSpacing = val }


{-| Update the row color when hovering field labels that are pointerlock-able.
-}
withLabelHighlightBgColor : Color -> ViewOptions -> ViewOptions
withLabelHighlightBgColor val options =
    { options | labelHighlightBgColor = val }


{-| Update the font size.
-}
withFontSize : Int -> ViewOptions -> ViewOptions
withFontSize val options =
    { options | fontSize = val }


{-| Update the width of inputs.
-}
withInputWidth : Int -> ViewOptions -> ViewOptions
withInputWidth val options =
    { options | inputWidth = val }


{-| Update the height of inputs.
-}
withInputHeight : Int -> ViewOptions -> ViewOptions
withInputHeight val options =
    { options | inputHeight = val }



-- MISC INTERNAL


px : Float -> String
px num =
    String.fromFloat num ++ "px"


pxInt : Int -> String
pxInt num =
    String.fromInt num ++ "px"
