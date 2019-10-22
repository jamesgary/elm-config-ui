module ConfigForm exposing
    ( ConfigForm, init, InitOptions, Defaults
    , Msg
    , update, resetToDefault
    , encode
    , view
    , viewOptions, withFontSize, withRowSpacing, withInputWidth, withInputSpacing, withLabelHighlightBgColor, withSectionSpacing
    , int, float, string, bool, color, section
    )

{-| Note: The `config` in the following type signatures is a record of all your config values, like...

    type alias Config =
        { headerFontSize : Int
        , bodyFontSize : Int
        , backgroundColor : Color
        }

Also, `Value` is shorthand for `Json.Encode.Value`.

@docs ConfigForm, init, InitOptions, Defaults


# Msg

@docs Msg


# Update

@docs update, resetToDefault


# Encoding

@docs encode


# View

@docs view


# View options

@docs viewOptions, withFontSize, withRowSpacing, withInputWidth, withInputSpacing, withLabelHighlightBgColor, withSectionSpacing


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
import Json.Encode as JE
import OrderedDict exposing (OrderedDict)
import Round


{-| ConfigForm is the state of the config form. Keep it in your model along with the `config` record.
-}
type ConfigForm
    = ConfigForm
        { fields : OrderedDict String Field
        , fileFields : Dict String Field
        , activeField : Maybe ( FieldState, String )
        }


type FieldState
    = Hovering
    | Dragging


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


{-| If a particular value isn't found from localStorage or file, then it fallbacks to these values. It might be a good idea to use wild values that are easy to spot so you can quickly replace them with real values.

    defaults =
        { int = -9999
        , float = -9999
        , string = "PLEASE REPLACE ME"
        , bool = True
        , color = Color.rgb 1 0 1 -- hot pink!
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

`Config` is your generated module that was made using [ ConfigFormGenerator](ConfigFormGenerator).

-}
type alias InitOptions config =
    { flags : JE.Value
    , logics : List (Logic config)
    , emptyConfig : config
    }


type alias Flags =
    { file : JE.Value
    , localStorage : JE.Value
    }


{-| `init` will create both a valid `Config` and `ConfigForm`.
-}
init : InitOptions config -> ( config, ConfigForm )
init options =
    let
        { file, localStorage } =
            decodeFlags
                options.flags

        fileFields =
            decodeFields
                options.logics
                file

        localStorageFields =
            decodeFields
                options.logics
                localStorage

        mergedFields =
            options.logics
                |> List.map
                    (\logic ->
                        ( logic.fieldName
                        , Dict.get logic.fieldName localStorageFields
                            |> Maybe.withDefault
                                (Dict.get logic.fieldName fileFields
                                    |> Maybe.withDefault
                                        (emptyField logic options.emptyConfig)
                                )
                        )
                    )
                |> OrderedDict.fromList

        --config =
        --    decodeConfig
        --        options.logics
        --        options.emptyConfig
        --        flags
        --configForm =
        --    decodeConfigForm
        --        options.logics
        --        config
        --        flags
        --        |> Debug.log "FIUNAL"
        --configFormRecord =
        --    case configForm of
        --        ConfigForm record ->
        --            record
    in
    ( --configFromConfigForm options.logics configFormRecord.fields config
      configFromFields options.logics mergedFields options.emptyConfig
    , ConfigForm
        { fields = mergedFields
        , fileFields = fileFields
        , activeField = Nothing
        }
    )


emptyField : Logic config -> config -> Field
emptyField logic emptyConfig =
    case logic.kind of
        IntLogic getter setter ->
            IntField
                { val = getter emptyConfig
                , str = getter emptyConfig |> String.fromInt
                , power = 0
                }

        FloatLogic getter setter ->
            FloatField
                { val = getter emptyConfig
                , str = getter emptyConfig |> String.fromFloat
                , power = 0
                }

        StringLogic getter setter ->
            StringField
                { val = getter emptyConfig
                }

        BoolLogic getter setter ->
            BoolField
                { val = getter emptyConfig
                }

        ColorLogic getter setter ->
            ColorField
                { val = getter emptyConfig
                , meta =
                    ColorFieldMeta
                        { state = ColorPicker.empty
                        , isOpen = False
                        }
                }

        SectionLogic ->
            SectionField logic.fieldName



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
    | HoveredLabel String Bool
    | MouseMove Int
    | MouseUp


{-| Encodes the current Config (with some metadata) in your ConfigForm. Usually used for both localStorage and as a .json file.
-}



--encode : List (Logic config) -> config -> ConfigForm -> JE.Value
--encode logics config (ConfigForm configForm) =


encode : ConfigForm -> JE.Value
encode (ConfigForm configForm) =
    --logics
    --    |> List.filterMap
    --        (\logic ->
    --            case logic.kind of
    --                IntLogic getter _ ->
    --                    Just
    --                        ( logic.fieldName
    --                        , JE.int (getter config)
    --                        )
    --                FloatLogic getter _ ->
    --                    Just
    --                        ( logic.fieldName
    --                        , JE.float (getter config)
    --                        )
    --                StringLogic getter _ ->
    --                    Just
    --                        ( logic.fieldName
    --                        , JE.string (getter config)
    --                        )
    --                BoolLogic getter _ ->
    --                    Just
    --                        ( logic.fieldName
    --                        , JE.bool (getter config)
    --                        )
    --                ColorLogic getter _ ->
    --                    Just
    --                        ( logic.fieldName
    --                        , getter config
    --                            |> encodeColor
    --                        )
    --                SectionLogic ->
    --                    Nothing
    --        )
    --    |> JE.object
    JE.object
        [ ( "fields", encodeFields configForm.fields )
        ]


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



--encodeConfigForm : ConfigForm -> JE.Value
--encodeConfigForm (ConfigForm configForm) =
--    {-
--       do i even need a config at all?
--       does configform even need config?
--       only need it for view...
--    -}
--    JE.object
--        [ ( "fields", encodeFields configForm.fields )
--        ]


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
            ( data.val, data.power )
                |> tuple2Encoder JE.int JE.int
                |> Just

        FloatField data ->
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
update : List (Logic config) -> config -> ConfigForm -> Msg config -> ( config, ConfigForm )
update logics config (ConfigForm configForm) msg =
    case msg of
        ChangedConfigForm fieldName field ->
            let
                newConfigForm =
                    configForm.fields
                        |> OrderedDict.insert fieldName field

                newConfig =
                    configFromFields logics newConfigForm config
            in
            ( newConfig
            , ConfigForm { configForm | fields = newConfigForm }
            )

        ClickedPointerLockLabel fieldName ->
            ( config
            , ConfigForm { configForm | activeField = Just ( Dragging, fieldName ) }
            )

        HoveredLabel fieldName didEnter ->
            ( config
            , ConfigForm
                { configForm
                    | activeField =
                        -- chrome triggers a mouseleave when entering pointerlock,
                        -- so check if you're dragging first, and don't change anything if so
                        case configForm.activeField of
                            Just ( Dragging, _ ) ->
                                configForm.activeField

                            _ ->
                                if didEnter then
                                    Just ( Hovering, fieldName )

                                else
                                    Nothing
                }
            )

        MouseMove num ->
            let
                newConfigForm =
                    case configForm.activeField of
                        Just ( state, fieldName ) ->
                            { configForm
                                | fields =
                                    configForm.fields
                                        |> OrderedDict.update fieldName
                                            (\maybeField ->
                                                case maybeField of
                                                    Just (IntField data) ->
                                                        let
                                                            newVal =
                                                                data.val
                                                                    + (num * (10 ^ data.power))
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
                                                                data.val
                                                                    + toFloat (num * (10 ^ data.power))
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

                newConfig =
                    configFromFields
                        logics
                        newConfigForm.fields
                        config
            in
            ( newConfig
            , ConfigForm newConfigForm
            )

        MouseUp ->
            ( config
            , ConfigForm
                { configForm
                    | activeField =
                        case configForm.activeField of
                            Just ( state, fieldName ) ->
                                Just ( Hovering, fieldName )

                            Nothing ->
                                Nothing
                }
            )


configFromFields : List (Logic config) -> OrderedDict String Field -> config -> config
configFromFields logics configForm config =
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



--decodeConfigForm : List (Logic config) -> config -> Flags -> ConfigForm
--decodeConfigForm logics emptyConfig ({ file, localStorage } as flags) =


decodeFields : List (Logic config) -> JE.Value -> Dict String Field
decodeFields logics json =
    logics
        |> List.filterMap
            (\logic ->
                decodeField logic json
                    |> Maybe.map
                        (\field ->
                            ( logic.fieldName, field )
                        )
            )
        |> Dict.fromList


decodeField : Logic config -> JE.Value -> Maybe Field
decodeField logic json =
    case logic.kind of
        IntLogic getter setter ->
            let
                decoder =
                    JD.at [ "fields", logic.fieldName ]
                        (JD.map2
                            Tuple.pair
                            (JD.index 0 JD.int)
                            (JD.index 1 JD.int)
                        )
            in
            case JD.decodeValue decoder json of
                Ok ( val, power ) ->
                    { val = val
                    , str = formatPoweredInt power val
                    , power = power
                    }
                        |> IntField
                        |> Just

                Err err ->
                    Nothing

        FloatLogic getter setter ->
            let
                decoder =
                    JD.at [ "fields", logic.fieldName ]
                        (JD.map2 Tuple.pair
                            (JD.index 0 JD.float)
                            (JD.index 1 JD.int)
                        )
            in
            case JD.decodeValue decoder json of
                Ok ( val, power ) ->
                    { val = val
                    , str = formatPoweredFloat power val
                    , power = power
                    }
                        |> FloatField
                        |> Just

                Err err ->
                    Nothing

        StringLogic getter setter ->
            let
                decoder =
                    JD.at [ "fields", logic.fieldName ] JD.string
            in
            case JD.decodeValue decoder json of
                Ok val ->
                    { val = val
                    }
                        |> StringField
                        |> Just

                Err err ->
                    Nothing

        BoolLogic getter setter ->
            let
                decoder =
                    JD.at [ "fields", logic.fieldName ] JD.bool
            in
            case JD.decodeValue decoder json of
                Ok val ->
                    { val = val
                    }
                        |> BoolField
                        |> Just

                Err err ->
                    Nothing

        ColorLogic getter setter ->
            let
                decoder =
                    JD.at [ "fields", logic.fieldName ] colorValDecoder
            in
            case JD.decodeValue decoder json of
                Ok val ->
                    { val = val
                    , meta =
                        ColorFieldMeta
                            { state = ColorPicker.empty
                            , isOpen = False
                            }
                    }
                        |> ColorField
                        |> Just

                Err err ->
                    Nothing

        SectionLogic ->
            logic.fieldName
                |> SectionField
                |> Just



-- JSON encode/decoder stuff


decodeFlags : JE.Value -> Flags
decodeFlags json =
    let
        decoder =
            JD.map2 Flags
                (JD.field "file" JD.value)
                (JD.field "localStorage" JD.value)
    in
    JD.decodeValue decoder json
        |> Result.withDefault
            { file = JE.object []
            , localStorage = JE.object []
            }


decodeConfig : List (Logic config) -> config -> Flags -> config
decodeConfig logics emptyConfig { file, localStorage } =
    let
        buildConfig json tmpConfig =
            logics
                |> List.foldl
                    (\logic config ->
                        case logic.kind of
                            IntLogic getter setter ->
                                case JD.decodeValue (JD.field logic.fieldName JD.int) json of
                                    Ok intVal ->
                                        setter intVal config

                                    Err err ->
                                        config

                            FloatLogic getter setter ->
                                case JD.decodeValue (JD.field logic.fieldName JD.float) json of
                                    Ok floatVal ->
                                        setter floatVal config

                                    Err err ->
                                        config

                            StringLogic getter setter ->
                                case JD.decodeValue (JD.field logic.fieldName JD.string) json of
                                    Ok str ->
                                        setter str config

                                    Err err ->
                                        config

                            BoolLogic getter setter ->
                                case JD.decodeValue (JD.field logic.fieldName JD.bool) json of
                                    Ok str ->
                                        setter str config

                                    Err err ->
                                        config

                            ColorLogic getter setter ->
                                case JD.decodeValue (JD.field logic.fieldName colorValDecoder) json of
                                    Ok col ->
                                        setter col config

                                    Err err ->
                                        config

                            SectionLogic ->
                                config
                    )
                    tmpConfig
    in
    emptyConfig
        |> buildConfig file
        |> buildConfig localStorage


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
view : ViewOptions -> List (Logic config) -> ConfigForm -> Html (Msg config)
view options logics ((ConfigForm configForm) as configFormType) =
    Html.div [ style "font-size" (pxInt options.fontSize) ]
        [ Html.table
            [ style "border-spacing" ("0 " ++ pxInt options.rowSpacing)
            ]
            (logics
                |> List.indexedMap
                    (\i logic ->
                        Html.tr
                            (case configForm.activeField of
                                Just ( state, fieldName ) ->
                                    if fieldName == logic.fieldName then
                                        [ style
                                            "background"
                                            (Color.toCssString options.labelHighlightBgColor)
                                        ]

                                    else
                                        []

                                Nothing ->
                                    []
                            )
                            [ viewLabel options configFormType i logic
                            , viewChanger options configFormType i logic
                            ]
                    )
            )
        , Html.div [ Html.Attributes.id "elm-config-ui-pointerlock" ] []
        , Html.node "elm-config-ui-json"
            [ Html.Attributes.attribute
                "data-encoded-config"
                (configForm
                    |> ConfigForm
                    |> encode
                    |> JE.encode 2
                )
            ]
            []
        ]


slider : List (Html (Msg config)) -> Html (Msg config)
slider children =
    Html.node "elm-config-ui-slider"
        [ Html.Events.on "pl"
            (JD.at [ "detail", "x" ] JD.int
                |> JD.map MouseMove
            )
        ]
        children


viewLabel : ViewOptions -> ConfigForm -> Int -> Logic config -> Html (Msg config)
viewLabel options configForm i logic =
    case logic.kind of
        StringLogic getter setter ->
            Html.td
                []
                [ Html.text logic.label ]

        IntLogic getter setter ->
            Html.td
                (resizeAttrs options configForm logic)
                [ slider [ Html.text logic.label ]
                , powerEl options configForm logic
                ]

        FloatLogic getter setter ->
            Html.td
                (resizeAttrs options configForm logic)
                [ slider [ Html.text logic.label ]
                , powerEl options configForm logic
                ]

        BoolLogic getter setter ->
            Html.td
                []
                [ Html.text logic.label ]

        ColorLogic getter setter ->
            Html.td
                []
                [ Html.text logic.label
                , closeEl options configForm i logic
                ]

        SectionLogic ->
            Html.td
                [ style "font-weight" "bold"
                , style "padding" (pxInt options.sectionSpacing ++ " 0 5px 0")
                , Html.Attributes.colspan 2
                ]
                [ Html.text logic.label ]


closeEl : ViewOptions -> ConfigForm -> Int -> Logic config -> Html (Msg config)
closeEl options (ConfigForm configForm) i logic =
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
            Html.button
                [ style "background" "rgba(255,255,255,0.9)"
                , style "border" "1px solid rgba(0,0,0,0.9)"
                , style "border-radius" "4px"
                , style "width" (px (1.5 * toFloat options.fontSize))
                , style "height" (px (1.5 * toFloat options.fontSize))
                , Html.Attributes.tabindex (1 + i)
                , Html.Events.onClick msg
                ]
                [ Html.div
                    [ style "padding" "3px 0 0 2px" ]
                    [ Html.text "❌" ]
                ]

        Nothing ->
            Html.text ""


formattedPower : Int -> String
formattedPower power =
    let
        numStr =
            if power >= 0 then
                String.fromInt (10 ^ power)

            else
                "0." ++ String.repeat (-1 - power) "0" ++ "1"
    in
    "x" ++ numStr


powerEl : ViewOptions -> ConfigForm -> Logic config -> Html (Msg config)
powerEl options (ConfigForm configForm) logic =
    let
        makePowerEl power newIncField newDecField isDownDisabled =
            Html.div
                [ style "position" "absolute"
                , style "top" "0px"
                , style "right" "0"
                , style "height" "100%"
                , style "box-sizing" "border-box"
                , style "display" "flex"
                , style "align-items" "center"
                , style "padding-left" (px (0.45 * inputFieldVertPadding options))
                , style "font-size" (px (0.8 * toFloat options.fontSize))
                , style "background" (Color.toCssString options.labelHighlightBgColor)
                , style "background"
                    ([ "linear-gradient(to right,"
                     , "transparent,"
                     , Color.toCssString options.labelHighlightBgColor ++ " 10%,"
                     , Color.toCssString options.labelHighlightBgColor
                     ]
                        |> String.join " "
                    )
                ]
                [ Html.span
                    [ style "padding" "5px 0"
                    ]
                    -- label
                    [ Html.text (formattedPower power) ]
                , Html.span
                    [ style "font-size" (0.8 * toFloat options.fontSize |> px)
                    , style "top" "1px"
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
                    [ style "font-size" (0.8 * toFloat options.fontSize |> px)
                    , style "top" "1px"
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

        el =
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
    case configForm.activeField of
        Just ( state, fieldName ) ->
            if fieldName == logic.fieldName then
                el

            else
                Html.text ""

        Nothing ->
            Html.text ""


resizeAttrs : ViewOptions -> ConfigForm -> Logic config -> List (Html.Attribute (Msg config))
resizeAttrs options configForm logic =
    [ Html.Events.onMouseEnter (HoveredLabel logic.fieldName True)
    , Html.Events.onMouseLeave (HoveredLabel logic.fieldName False)

    --, Html.Events.onMouseDown (ClickedPointerLockLabel logic.fieldName)
    , style "cursor" "ew-resize"
    , style "height" "100%"
    , style "position" "relative"
    ]


inputFieldVertPadding : ViewOptions -> Float
inputFieldVertPadding options =
    --3
    toFloat options.fontSize * options.inputSpacing


viewChanger : ViewOptions -> ConfigForm -> Int -> Logic config -> Html (Msg config)
viewChanger options (ConfigForm configForm) i logic =
    let
        defaultAttrs =
            [ style "width" (pxInt options.inputWidth)

            --, style "height" (pxInt (options.fontSize + (4 + inputFieldVertPadding * 2)))
            , style "height" (px (inputFieldVertPadding options))
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
            , style "font-variant-numeric" "tabular-nums"
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
                    options
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
                    options
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
                    options
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
                               , style "box-sizing" "border-box"

                               --, style "height" (pxInt (19 + options.fontSize))
                               --, style "height" (px (toFloat options.fontSize + inputFieldVertPadding options))
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
    ViewOptions
    ->
        { label : String
        , valStr : String
        , attrs : List (Html.Attribute (Msg config))
        , setterMsg : String -> Msg config
        }
    -> Html (Msg config)
textInputHelper options { label, valStr, attrs, setterMsg } =
    Html.input
        ([ Html.Attributes.value valStr
         , Html.Events.onInput setterMsg
         , style "font-size" "inherit"

         --, style "padding" ("3px " ++ px (0.25 * inputFieldVertPadding options))
         , style "height" "200px"
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
    , inputSpacing : Float
    , labelHighlightBgColor : Color
    , sectionSpacing : Int
    }


{-| Default options for viewing the config form.
-}
viewOptions : ViewOptions
viewOptions =
    { fontSize = 18
    , rowSpacing = 2
    , inputWidth = 80
    , inputSpacing = 1.4
    , labelHighlightBgColor = Color.rgb 0.8 0.8 1
    , sectionSpacing = 10
    }


{-| Update the font size in px. Default is 18.
-}
withFontSize : Int -> ViewOptions -> ViewOptions
withFontSize val options =
    { options | fontSize = val }


{-| Update the row spacing in px. Default is 2.
-}
withRowSpacing : Int -> ViewOptions -> ViewOptions
withRowSpacing val options =
    { options | rowSpacing = val }


{-| Update the width of inputs in px. Default is 80.
-}
withInputWidth : Int -> ViewOptions -> ViewOptions
withInputWidth val options =
    { options | inputWidth = val }


{-| Update the inner spacing of inputs by a ratio of its font size. Default is 1.40.
-}
withInputSpacing : Float -> ViewOptions -> ViewOptions
withInputSpacing val options =
    { options | inputSpacing = val }


{-| Update the row color when hovering field labels that are pointerlock-able. Default is yellow: (0.8, 0.8, 1).
-}
withLabelHighlightBgColor : Color -> ViewOptions -> ViewOptions
withLabelHighlightBgColor val options =
    { options | labelHighlightBgColor = val }


{-| Update the extra top spacing for sections in px. Default is 20.
-}
withSectionSpacing : Int -> ViewOptions -> ViewOptions
withSectionSpacing val options =
    { options | sectionSpacing = val }



-- MISC INTERNAL


px : Float -> String
px num =
    String.fromFloat num ++ "px"


pxInt : Int -> String
pxInt num =
    String.fromInt num ++ "px"



-- NEW/EXPERIMENTAL


{-| Resets your `config` and `ConfigForm` to their default state. This is equivalent to clearing your cache and relying on just your .json file.
-}
resetToDefault : List (Logic config) -> config -> ConfigForm -> ( config, ConfigForm )
resetToDefault logics config (ConfigForm configForm) =
    --let
    --    newConfig =
    --        decodeConfig logics config configForm.fileJson
    --in
    --( newConfig
    --, dzzecodeConfigForm
    --    logics
    --    newConfig
    --    (JE.object [])
    --    configForm.fileJson
    --)
    ( config, ConfigForm configForm )
