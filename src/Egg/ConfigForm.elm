module Egg.ConfigForm exposing
    ( ConfigForm, init, InitOptions, Defaults, Logic
    , Field
    , int, float, string, color, element, section
    , Msg
    , update, updateFromJson
    , encode, encodeConfigForm
    , viewHtml, viewElement
    , viewOptions, withRowSpacing, withLabelHighlightBgColor, withInputHeight, withFontSize
    , ElementAttr
    )

{-|


# Main stuff

@docs ConfigForm, init, InitOptions, Defaults, Logic


# Field

@docs Field


# Field Types

@docs IntField, FloatField, StringField, ColorField


# Field functions

@docs int, float, string, color, element, section


# Msg

@docs Msg


# Update

@docs update, updateFromJson


# Encoding

@docs encode, encodeConfigForm


# View

@docs viewHtml, viewElement


# View options

@docs viewOptions, withRowSpacing, withLabelHighlightBgColor, withInputHeight, withFontSize, withScrollbars

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
    , undoStack : List ( String, Field )
    }


type Field
    = IntField IntFieldData
    | FloatField FloatFieldData
    | StringField StringFieldData
    | ColorField ColorFieldData
    | ElementField ElementFieldData
    | SectionField String


type alias IntFieldData =
    { val : Int
    , str : String
    }


type alias FloatFieldData =
    { val : Float
    , str : String
    }


type alias StringFieldData =
    { val : String
    }


type alias ColorFieldData =
    { val : Color
    , meta : ColorFieldMeta
    }



-- Element stuff


type alias ElementFieldData =
    { val : List ElementAttr

    --, meta : some form data probably
    }


type ElementAttr
    = AlignmentX AlignmentXData
    | AlignmentY AlignmentYData


type AlignmentXData
    = AlignLeft
    | CenterX
    | AlignRight


type AlignmentYData
    = AlignTop
    | CenterY
    | AlignBottom


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
    | ElementLogic (config -> List ElementAttr) (List ElementAttr -> config -> config)
    | SectionLogic


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


element : String -> String -> (config -> List ElementAttr) -> (List ElementAttr -> config -> config) -> Logic config
element fieldName label getter setter =
    { fieldName = fieldName
    , label = label
    , kind = ElementLogic getter setter
    }


section : String -> Logic config
section sectionStr =
    { fieldName = ""
    , label = sectionStr
    , kind = SectionLogic
    }


type Msg config
    = ChangedConfigForm String Field
    | ClickedPointerLockLabel String
    | SelectedElementAttr String ElementFieldData String
    | SelectedAlignmentX String ElementFieldData String


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

                    ColorLogic getter _ ->
                        Just
                            ( logic.fieldName
                            , getter config
                                |> encodeColor
                            )

                    ElementLogic getter _ ->
                        Just
                            ( logic.fieldName
                            , getter config
                                |> encodeElement
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


encodeElement : List ElementAttr -> JE.Value
encodeElement attrs =
    -- TODO
    JE.null


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


encodeField : Field -> Maybe JE.Value
encodeField field =
    case field of
        IntField data ->
            JE.int data.val
                |> Just

        FloatField data ->
            JE.float data.val
                |> Just

        StringField data ->
            JE.string data.val
                |> Just

        ColorField data ->
            encodeColor data.val
                |> Just

        ElementField data ->
            -- TODO
            Nothing

        SectionField _ ->
            Nothing


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

        SelectedElementAttr fieldName fieldData optionVal ->
            let
                maybeAttr =
                    case optionVal of
                        "alignX" ->
                            Just (AlignmentX AlignLeft)

                        "alignY" ->
                            Just (AlignmentY AlignTop)

                        _ ->
                            Nothing
            in
            ( config
            , case maybeAttr of
                Just attr ->
                    { configForm
                        | fields =
                            configForm.fields
                                |> OrderedDict.insert fieldName
                                    (ElementField
                                        { val = fieldData.val ++ [ attr ]
                                        }
                                    )
                    }

                Nothing ->
                    configForm
            , Nothing
            )

        SelectedAlignmentX fieldName fieldData optionVal ->
            let
                maybeAttr =
                    case optionVal of
                        "alignLeft" ->
                            Just (AlignmentX AlignLeft)

                        "centerX" ->
                            Just (AlignmentX CenterX)

                        "alignRight" ->
                            Just (AlignmentX AlignRight)

                        _ ->
                            Nothing
            in
            ( config
            , case maybeAttr of
                Just attr ->
                    { configForm
                        | fields =
                            configForm.fields
                                |> OrderedDict.insert fieldName
                                    (ElementField
                                        { val = fieldData.val ++ [ attr ]
                                        }
                                    )
                    }

                Nothing ->
                    configForm
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

                    ( Just (ElementField data), ElementLogic getter setter ) ->
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
                                                                Just
                                                                    (IntField
                                                                        { data
                                                                            | val = data.val + num
                                                                            , str = String.fromInt (data.val + num)
                                                                        }
                                                                    )

                                                            Just (FloatField data) ->
                                                                Just
                                                                    (FloatField
                                                                        { data
                                                                            | val = data.val + toFloat num
                                                                            , str = String.fromFloat (data.val + toFloat num)
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
                                    JD.at [ "fields", logic.fieldName ] JD.int

                                val =
                                    case JD.decodeValue decoder json of
                                        Ok v ->
                                            v

                                        Err err ->
                                            getter config
                            in
                            IntField
                                { val = val
                                , str = String.fromInt val
                                }

                        FloatLogic getter setter ->
                            let
                                decoder =
                                    JD.at [ "fields", logic.fieldName ] JD.float

                                val =
                                    case JD.decodeValue decoder json of
                                        Ok v ->
                                            v

                                        Err err ->
                                            getter config
                            in
                            FloatField
                                { val = val
                                , str = String.fromFloat val
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

                        ElementLogic getter setter ->
                            let
                                decoder =
                                    JD.at [ "fields", logic.fieldName ] elementValDecoder

                                val =
                                    case JD.decodeValue decoder json of
                                        Ok v ->
                                            v

                                        Err err ->
                                            getter config
                            in
                            ElementField
                                { val = val
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

                    ColorLogic getter setter ->
                        case JD.decodeValue (JD.field logic.fieldName colorValDecoder) configJson of
                            Ok col ->
                                setter col config

                            Err err ->
                                config

                    ElementLogic getter setter ->
                        case JD.decodeValue (JD.field logic.fieldName elementValDecoder) configJson of
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


elementValDecoder : JD.Decoder (List ElementAttr)
elementValDecoder =
    JD.succeed []



-- VIEW


viewElement : ViewOptions -> List (Logic config) -> ConfigForm config -> Element (Msg config)
viewElement options logics configForm =
    E.indexedTable
        [ E.spacingXY 0 options.rowSpacing
        , EFont.size options.fontSize
        ]
        { data = logics
        , columns =
            [ { header = E.none
              , width = E.shrink
              , view =
                    \i logic ->
                        let
                            defaultAttrs =
                                [ E.height E.fill
                                , E.paddingXY 10 2
                                , E.alignTop
                                ]

                            sectionAttrs =
                                [ EFont.bold
                                , E.paddingEach
                                    { top = 20
                                    , right = 0
                                    , bottom = 5
                                    , left = 10
                                    }
                                ]

                            resizeAttrs =
                                [ EEvents.onMouseDown (ClickedPointerLockLabel logic.fieldName)
                                , E.htmlAttribute (Html.Attributes.style "cursor" "ew-resize")
                                , E.mouseOver
                                    [ EBackground.color
                                        (colorForE options.labelHighlightBgColor)
                                    ]
                                ]

                            closeAttrs =
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
                                        [ E.inFront <|
                                            E.el
                                                [ E.width E.fill
                                                , E.padding 6
                                                ]
                                                (EInput.button
                                                    [ E.alignRight
                                                    , EBackground.color (E.rgba 1 1 1 0.9)
                                                    , EBorder.color (E.rgba 0 0 0 0.9)
                                                    , EBorder.width 1
                                                    , EBorder.rounded 4
                                                    , E.width (E.px (1.5 * toFloat options.fontSize |> round))
                                                    , E.height (E.px (1.5 * toFloat options.fontSize |> round))
                                                    , Html.Attributes.tabindex (1 + i) |> E.htmlAttribute
                                                    ]
                                                    { onPress = Just msg
                                                    , label =
                                                        E.el
                                                            [ E.centerX
                                                            , E.centerY
                                                            , E.paddingEach
                                                                { top = 3
                                                                , right = 0
                                                                , bottom = 0
                                                                , left = 2
                                                                }
                                                            ]
                                                            (E.text "❌")
                                                    }
                                                )
                                        ]

                                    Nothing ->
                                        []

                            attrs =
                                defaultAttrs
                                    ++ (case logic.kind of
                                            StringLogic getter setter ->
                                                []

                                            IntLogic getter setter ->
                                                resizeAttrs

                                            FloatLogic getter setter ->
                                                resizeAttrs

                                            ColorLogic getter setter ->
                                                closeAttrs

                                            ElementLogic getter setter ->
                                                []

                                            SectionLogic ->
                                                sectionAttrs
                                       )
                        in
                        E.el
                            attrs
                            (E.el
                                [ E.centerY ]
                                (E.text logic.label)
                            )
              }
            , { header = E.none
              , width = E.shrink
              , view = viewChanger options configForm
              }
            ]
        }


viewHtml : ViewOptions -> List (Logic config) -> ConfigForm config -> Html (Msg config)
viewHtml options logics configForm =
    viewElement options logics configForm
        |> E.layout []


viewChanger : ViewOptions -> ConfigForm config -> Int -> Logic config -> Element (Msg config)
viewChanger options configForm index logic =
    let
        defaultAttrs =
            [ E.height (E.px options.inputHeight)
            ]

        tabAttrs =
            [ Html.Attributes.tabindex (1 + index) |> E.htmlAttribute
            ]

        incrementalAttrs strToNum wrapper data =
            [ Html.Events.on "keydown"
                (JD.map
                    (\i ->
                        let
                            maybeNewNum =
                                case i of
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
                        , attrs = defaultAttrs ++ tabAttrs
                        , setterMsg =
                            \newStr ->
                                ChangedConfigForm
                                    logic.fieldName
                                    (StringField { data | val = newStr })
                        }

                IntField data ->
                    textInputHelper
                        { label = logic.label
                        , valStr = data.str
                        , attrs =
                            defaultAttrs
                                ++ tabAttrs
                                ++ incrementalAttrs String.fromInt IntField data
                                ++ (if String.toInt data.str == Nothing then
                                        [ EBackground.color (E.rgba 1 0 0 0.3) ]

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

                FloatField data ->
                    textInputHelper
                        { label = logic.label
                        , valStr = data.str
                        , attrs =
                            defaultAttrs
                                ++ tabAttrs
                                ++ incrementalAttrs String.fromFloat FloatField data
                                ++ (if String.toFloat data.str == Nothing then
                                        [ EBackground.color (E.rgba 1 0 0 0.3) ]

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

                ElementField data ->
                    E.column []
                        [ Html.select
                            [ Html.Attributes.style "font-size" (px options.fontSize)
                            , Html.Events.onInput (SelectedElementAttr logic.fieldName data)
                            ]
                            [ Html.option
                                [ Html.Attributes.disabled True
                                , Html.Attributes.selected True
                                ]
                                [ Html.text "Add element attribute"
                                ]
                            , Html.option
                                [ Html.Attributes.disabled False
                                , Html.Attributes.value "alignX"
                                ]
                                [ Html.text "Align X"
                                ]
                            , Html.option
                                [ Html.Attributes.disabled False
                                , Html.Attributes.value "alignY"
                                ]
                                [ Html.text "Align Y"
                                ]
                            ]
                            |> E.html
                        , E.column []
                            (data.val
                                |> List.map
                                    (\attr ->
                                        case attr of
                                            AlignmentX alignmentData ->
                                                E.row []
                                                    [ E.text "Alignment X"
                                                    , Html.select
                                                        [ Html.Attributes.style "font-size" (px options.fontSize)
                                                        , Html.Events.onInput (SelectedAlignmentX logic.fieldName data)
                                                        ]
                                                        [ Html.option
                                                            [ Html.Attributes.value "alignLeft"
                                                            ]
                                                            [ Html.text "Left"
                                                            ]
                                                        , Html.option
                                                            [ Html.Attributes.value "centerX"
                                                            ]
                                                            [ Html.text "Center"
                                                            ]
                                                        , Html.option
                                                            [ Html.Attributes.value "alignRight"
                                                            ]
                                                            [ Html.text "Right"
                                                            ]
                                                        ]
                                                        |> E.html
                                                    ]

                                            AlignmentY alignmentData ->
                                                E.text "Yin"
                                    )
                            )
                        ]

                SectionField str ->
                    E.el defaultAttrs E.none

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
    { fontSize : Int
    , rowSpacing : Int
    , inputHeight : Int
    , labelHighlightBgColor : Color
    , sectionSpacing : Int
    }


viewOptions : ViewOptions
viewOptions =
    { fontSize = 19
    , rowSpacing = 5
    , inputHeight = 34
    , labelHighlightBgColor = Color.rgba 0.2 0.2 1 0.3
    , sectionSpacing = 20
    }


withRowSpacing : Int -> ViewOptions -> ViewOptions
withRowSpacing val options =
    { options | rowSpacing = val }


withLabelHighlightBgColor : Color -> ViewOptions -> ViewOptions
withLabelHighlightBgColor val options =
    { options | labelHighlightBgColor = val }


withFontSize : Int -> ViewOptions -> ViewOptions
withFontSize val options =
    { options | fontSize = val }


withInputHeight : Int -> ViewOptions -> ViewOptions
withInputHeight val options =
    { options | inputHeight = val }


px : Int -> String
px num =
    String.fromInt num ++ "px"
