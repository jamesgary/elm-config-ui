module Egg.ConfigForm exposing
    ( ConfigForm, init, InitOptions, Defaults, Logic
    , Field
    , int, float, string, color
    , Msg
    , update, updateFromJson
    , encode
    , view, viewOptions, withTableBgColor, withTableSpacing, withTablePadding, withTableBorderWidth, withTableBorderColor, withLabelHighlightBgColor, withInputHeight, withFontSize
    )

{-|


# Main stuff

@docs ConfigForm, init, InitOptions, Defaults, Logic


# Field

@docs Field


# Field Types

@docs IntField, FloatField, StringField, ColorField


# Field functions

@docs int, float, string, color


# Msg

@docs Msg


# Update

@docs update, updateFromJson


# Encoding

@docs encode


# View

@docs view, viewOptions, withTableBgColor, withTableSpacing, withTablePadding, withTableBorderWidth, withTableBorderColor, withLabelHighlightBgColor, withInputHeight, withFontSize

-}

import Color exposing (Color)
import ColorPicker
import Dict exposing (Dict)
import Element as E exposing (Element)
import Element.Background as EBackground
import Element.Border as EBorder
import Element.Events as EEvents
import Element.Font as EFont
import Element.Input as EInput
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Json.Decode as JD
import Json.Decode.Pipeline as JDP
import Json.Encode as JE
import OrderedDict exposing (OrderedDict)


type alias ConfigForm config =
    { file : config -- unused for now
    , fields : OrderedDict String Field
    , changingField : Maybe String
    , scrollTop : Int
    }


type Field
    = StringField StringFieldData
    | IntField IntFieldData
    | FloatField FloatFieldData
    | ColorField ColorFieldData


type alias IntFieldData =
    { val : Int
    }


type alias FloatFieldData =
    { val : Float
    }


type alias StringFieldData =
    { val : String
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


type alias Defaults =
    { int : Int
    , float : Float
    , string : String
    , color : Color
    }


type alias InitOptions config =
    { configJson : JE.Value
    , configFormJson : JE.Value
    , logics : List (Logic config)
    , emptyConfig : config
    }


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


int : String -> String -> (config -> Int) -> (Int -> config -> config) -> Logic config
int fieldName label getter setter =
    { fieldName = fieldName
    , label = label
    , kind = IntLogic getter setter
    }


float : String -> String -> (config -> Float) -> (Float -> config -> config) -> Logic config
float fieldName label getter setter =
    { fieldName = fieldName
    , label = label
    , kind = FloatLogic getter setter
    }


string : String -> String -> (config -> String) -> (String -> config -> config) -> Logic config
string fieldName label getter setter =
    { fieldName = fieldName
    , label = label
    , kind = StringLogic getter setter
    }


color : String -> String -> (config -> Color) -> (Color -> config -> config) -> Logic config
color fieldName label getter setter =
    { fieldName = fieldName
    , label = label
    , kind = ColorLogic getter setter
    }


type Msg config
    = ChangedConfigForm String Field
    | ClickedPointerLockLabel String


encode : List (Logic config) -> config -> JE.Value
encode logics config =
    logics
        |> List.map
            (\logic ->
                ( logic.fieldName
                , case logic.kind of
                    IntLogic getter _ ->
                        JE.int (getter config)

                    FloatLogic getter _ ->
                        JE.float (getter config)

                    StringLogic getter _ ->
                        JE.string (getter config)

                    ColorLogic getter _ ->
                        getter config
                            |> Color.toRgba
                            |> (\{ red, green, blue, alpha } ->
                                    JE.object
                                        [ ( "r", JE.float red )
                                        , ( "g", JE.float green )
                                        , ( "b", JE.float blue )
                                        , ( "a", JE.float alpha )
                                        ]
                               )
                )
            )
        |> JE.object


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

                    ( Just (ColorField data), ColorLogic getter setter ) ->
                        setter data.val newConfig

                    _ ->
                        newConfig
            )
            config


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
                                                                Just (IntField { data | val = data.val + num })

                                                            Just (FloatField data) ->
                                                                Just (FloatField { data | val = data.val + toFloat num })

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
                    Debug.log
                        "Could not decode incoming config port msg: "
                        (JD.errorToString err)
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
                                    JD.field logic.fieldName JD.int

                                val =
                                    case JD.decodeValue decoder json of
                                        Ok v ->
                                            v

                                        Err err ->
                                            getter config
                            in
                            IntField
                                { val = val
                                }

                        FloatLogic getter setter ->
                            let
                                decoder =
                                    JD.field logic.fieldName JD.float

                                val =
                                    case JD.decodeValue decoder json of
                                        Ok v ->
                                            v

                                        Err err ->
                                            getter config
                            in
                            FloatField
                                { val = val
                                }

                        StringLogic getter setter ->
                            let
                                decoder =
                                    JD.field logic.fieldName JD.string

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

                        ColorLogic getter setter ->
                            let
                                decoder =
                                    JD.field logic.fieldName colorValDecoder

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
    }


floatField : JE.Value -> String -> Result JD.Error FloatFieldData
floatField json key =
    let
        constructor num =
            { val = num
            }
    in
    JD.decodeValue
        (JD.field key JD.float
            |> JD.map constructor
        )
        json


stringField : JE.Value -> String -> Result JD.Error StringFieldData
stringField json key =
    let
        constructor str =
            { val = str
            }
    in
    JD.decodeValue
        (JD.field key JD.string
            |> JD.map
                (\str ->
                    constructor str
                )
        )
        json


colorField : JE.Value -> String -> Result JD.Error ColorFieldData
colorField json key =
    let
        constructor col =
            { val = col
            , meta =
                ColorFieldMeta
                    { state = ColorPicker.empty
                    , isOpen = False
                    }
            }
    in
    JD.decodeValue
        (JD.field key colorValDecoder
            |> JD.map constructor
        )
        json



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

                    _ ->
                        config
            )
            emptyConfig


intDecoder : JE.Value -> String -> Result JD.Error IntFieldData
intDecoder json key =
    let
        constructor num =
            { val = num
            }
    in
    JD.decodeValue
        (JD.field key JD.int
            |> JD.map constructor
        )
        json


floatDecoder : JE.Value -> String -> Result JD.Error FloatFieldData
floatDecoder json key =
    let
        constructor num =
            { val = num
            }
    in
    JD.decodeValue
        (JD.field key JD.float
            |> JD.map constructor
        )
        json


stringDecoder : JE.Value -> String -> Result JD.Error StringFieldData
stringDecoder json key =
    let
        constructor str =
            { val = str
            }
    in
    JD.decodeValue
        (JD.field key JD.string
            |> JD.map
                (\str ->
                    constructor str
                )
        )
        json


colorDecoder : JE.Value -> String -> Result JD.Error ColorFieldData
colorDecoder json key =
    let
        constructor col =
            { val = col
            , meta =
                ColorFieldMeta
                    { state = ColorPicker.empty
                    , isOpen = False
                    }
            }
    in
    JD.decodeValue
        (JD.field key colorValDecoder
            |> JD.map constructor
        )
        json


colorValDecoder : JD.Decoder Color
colorValDecoder =
    JD.map4 Color.rgba
        (JD.field "r" JD.float)
        (JD.field "g" JD.float)
        (JD.field "b" JD.float)
        (JD.field "a" JD.float)



-- VIEW


view : ViewOptions -> List (Logic config) -> ConfigForm config -> Html (Msg config)
view options logics configForm =
    E.indexedTable
        [ EBackground.color (colorForE options.tableBgColor)
        , E.spacing options.tableSpacing
        , E.padding options.tablePadding
        , EBorder.width options.tableBorderWidth
        , EBorder.color (colorForE options.tableBorderColor)
        , EFont.size options.fontSize
        ]
        { data = logics
        , columns =
            [ { header = E.none
              , width = E.fill
              , view =
                    \i logic ->
                        let
                            resizeAttrs getter setter =
                                [ EEvents.onMouseDown (ClickedPointerLockLabel logic.fieldName)
                                , E.htmlAttribute (Html.Attributes.style "cursor" "ew-resize")
                                ]

                            defaultAttrs getter setter =
                                [ E.mouseOver
                                    [ EBackground.color
                                        (colorForE options.labelHighlightBgColor)
                                    ]
                                ]

                            attrs =
                                case logic.kind of
                                    StringLogic getter setter ->
                                        defaultAttrs getter setter

                                    IntLogic getter setter ->
                                        defaultAttrs getter setter
                                            ++ resizeAttrs getter setter

                                    FloatLogic getter setter ->
                                        defaultAttrs getter setter
                                            ++ resizeAttrs getter setter

                                    ColorLogic getter setter ->
                                        defaultAttrs getter setter
                        in
                        E.el
                            (attrs
                                ++ [ E.width E.fill
                                   , E.height E.fill
                                   ]
                            )
                            (E.el
                                [ E.centerY ]
                                (E.text logic.label)
                            )
              }
            , { header = E.none
              , width = E.fill
              , view = viewChanger options configForm
              }
            ]
        }
        |> E.layoutWith
            { options = [ E.noStaticStyleSheet ] }
            []


viewChanger : ViewOptions -> ConfigForm config -> Int -> Logic config -> Element (Msg config)
viewChanger options configForm index logic =
    let
        defaultAttrs =
            [ Html.Attributes.tabindex (1 + index) |> E.htmlAttribute
            , E.height (E.px options.inputHeight)
            ]

        incrementalAttrs wrapper data =
            [ Html.Events.on "keydown"
                (JD.map
                    (\i ->
                        let
                            amt =
                                case i of
                                    38 ->
                                        1

                                    40 ->
                                        -1

                                    _ ->
                                        0
                        in
                        ChangedConfigForm logic.fieldName (wrapper { data | val = data.val + amt })
                    )
                    Html.Events.keyCode
                )
                |> E.htmlAttribute
            ]

        maybeField =
            OrderedDict.get logic.fieldName configForm.fields
    in
    case maybeField of
        Just field ->
            case field of
                StringField data ->
                    textInputHelper
                        { label = logic.label
                        , valStr = data.val
                        , attrs = defaultAttrs
                        , setterMsg =
                            \newStr ->
                                ChangedConfigForm
                                    logic.fieldName
                                    (StringField { data | val = newStr })
                        }

                IntField data ->
                    textInputHelper
                        { label = logic.label
                        , valStr = String.fromInt data.val
                        , attrs = defaultAttrs ++ incrementalAttrs IntField data
                        , setterMsg =
                            \newStr ->
                                case String.toInt newStr of
                                    Just newNum ->
                                        ChangedConfigForm
                                            logic.fieldName
                                            (IntField { data | val = newNum })

                                    Nothing ->
                                        ChangedConfigForm
                                            logic.fieldName
                                            field
                        }

                FloatField data ->
                    textInputHelper
                        { label = logic.label
                        , valStr = String.fromFloat data.val
                        , attrs = defaultAttrs ++ incrementalAttrs FloatField data
                        , setterMsg =
                            \newStr ->
                                case String.toFloat newStr of
                                    Just newNum ->
                                        ChangedConfigForm
                                            logic.fieldName
                                            (FloatField { data | val = newNum })

                                    Nothing ->
                                        ChangedConfigForm
                                            logic.fieldName
                                            field
                        }

                ColorField data ->
                    let
                        meta =
                            case data.meta of
                                ColorFieldMeta m ->
                                    m
                    in
                    if meta.isOpen then
                        ColorPicker.view
                            data.val
                            meta.state
                            |> E.html
                            |> E.map
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
                        E.el
                            (defaultAttrs
                                ++ [ EBackground.color (colorForE data.val)
                                   , E.width E.fill
                                   , EBorder.color (E.rgba 0 0 0 0.3)
                                   , EBorder.width 1
                                   , EBorder.rounded 3
                                   , EEvents.onMouseDown
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
                            E.none

        Nothing ->
            E.none


textInputHelper :
    { label : String
    , valStr : String
    , attrs : List (E.Attribute (Msg config))
    , setterMsg : String -> Msg config
    }
    -> Element (Msg config)
textInputHelper { label, valStr, attrs, setterMsg } =
    EInput.text attrs
        { label = EInput.labelHidden label
        , text = valStr
        , onChange = setterMsg
        , placeholder = Nothing
        }


colorForE : Color -> E.Color
colorForE col =
    col
        |> Color.toRgba
        |> (\{ red, green, blue, alpha } ->
                E.rgba red green blue alpha
           )



-- VIEW OPTIONS


type alias ViewOptions =
    { tableBgColor : Color
    , tableSpacing : Int
    , tablePadding : Int
    , tableBorderWidth : Int
    , tableBorderColor : Color
    , labelHighlightBgColor : Color
    , fontSize : Int
    , inputHeight : Int
    }


viewOptions : ViewOptions
viewOptions =
    { tableBgColor = Color.rgba 1 1 1 0
    , tableSpacing = 5
    , tablePadding = 5
    , tableBorderWidth = 1
    , tableBorderColor = Color.rgb 0 0 0
    , labelHighlightBgColor = Color.rgba 0.2 0.2 1 0.3
    , fontSize = 28
    , inputHeight = 40
    }


withTableBgColor : Color -> ViewOptions -> ViewOptions
withTableBgColor val options =
    { options | tableBgColor = val }


withTableSpacing : Int -> ViewOptions -> ViewOptions
withTableSpacing val options =
    { options | tableSpacing = val }


withTablePadding : Int -> ViewOptions -> ViewOptions
withTablePadding val options =
    { options | tablePadding = val }


withTableBorderWidth : Int -> ViewOptions -> ViewOptions
withTableBorderWidth val options =
    { options | tableBorderWidth = val }


withTableBorderColor : Color -> ViewOptions -> ViewOptions
withTableBorderColor val options =
    { options | tableBorderColor = val }


withLabelHighlightBgColor : Color -> ViewOptions -> ViewOptions
withLabelHighlightBgColor val options =
    { options | labelHighlightBgColor = val }


withFontSize : Int -> ViewOptions -> ViewOptions
withFontSize val options =
    { options | fontSize = val }


withInputHeight : Int -> ViewOptions -> ViewOptions
withInputHeight val options =
    { options | inputHeight = val }