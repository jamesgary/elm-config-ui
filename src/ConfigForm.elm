module ConfigForm exposing
    ( ColorField
    , EncodeOptions
    , FieldData(..)
    , FloatField
    , IntField
    , Msg
    , StringField
    , ViewOptions
    , color
    , encode
    , float
    , int
    , portMsg
    , string
    , update
    , view
    , viewOptions
    , withBgColor
    )

import Color exposing (Color)
import ColorPicker
import Element as E exposing (Element)
import Element.Background as EBackground
import Element.Events as EEvents
import Element.Font as EFont
import Element.Input as EInput
import Json.Decode as JD
import Json.Decode.Pipeline as JDP
import Json.Encode as JE


type alias ConfigForm config =
    { file : JE.Value
    , config : config
    }


type alias Flags config =
    { file : JE.Value
    , localStorage : JE.Value
    , decoder : JD.Decoder config
    }


type alias IntField =
    { val : Int
    , isChanging : Bool
    }


type alias FloatField =
    { val : Float
    , isChanging : Bool
    }


type alias StringField =
    { val : String }


type alias ColorField =
    { val : Color
    , meta : ColorFieldMeta
    }


type ColorFieldMeta
    = ColorFieldMeta
        { state : ColorPicker.State
        , isOpen : Bool
        }


type FieldData config
    = String (config -> StringField) (StringField -> config -> config)
    | Int (config -> IntField) (IntField -> config -> config)
    | Float (config -> FloatField) (FloatField -> config -> config)
    | Color (config -> ColorField) (ColorField -> config -> config)


type Msg config
    = ChangeConfig (config -> config)
    | PointerLock (config -> config)
    | FromPort JE.Value


portMsg : JE.Value -> Msg config
portMsg json =
    FromPort json


type alias ConfigFormData config =
    ( String, String, FieldData config )


update : List (ConfigFormData config) -> Msg config -> config -> ( config, Maybe JE.Value )
update rows msg config =
    case msg of
        ChangeConfig updater ->
            ( updater config, Nothing )

        PointerLock updater ->
            ( updater config, Just (JE.string "LOCK_POINTER") )

        FromPort json ->
            case JD.decodeValue JD.float json of
                Ok num ->
                    ( rows
                        |> List.foldl
                            (\(( _, _, field ) as row) c ->
                                case field of
                                    Int getter setter ->
                                        let
                                            oldField =
                                                getter config

                                            newField =
                                                if oldField.isChanging then
                                                    { oldField
                                                        | val =
                                                            oldField.val + round num
                                                    }

                                                else
                                                    oldField
                                        in
                                        setter newField c

                                    Float getter setter ->
                                        let
                                            oldField =
                                                getter config

                                            newField =
                                                if oldField.isChanging then
                                                    { oldField
                                                        | val =
                                                            oldField.val + num
                                                    }

                                                else
                                                    oldField
                                        in
                                        setter newField c

                                    String getter setter ->
                                        c

                                    Color getter setter ->
                                        c
                            )
                            config
                    , Nothing
                    )

                Err err ->
                    let
                        _ =
                            Debug.log
                                "Could not decode incoming config port msg: "
                                (JD.errorToString err)
                    in
                    ( config, Nothing )



-- VIEW


type alias ViewOptions =
    { bgColor : Color
    }


viewOptions : ViewOptions
viewOptions =
    { bgColor = Color.rgba 0 0 0 0 }


withBgColor : Color -> ViewOptions -> ViewOptions
withBgColor col options =
    { options | bgColor = col }


view : config -> List ( String, FieldData config ) -> ViewOptions -> Element (Msg config)
view config formList options =
    E.table
        [ EBackground.color (colorForE options.bgColor)
        ]
        { data = formList
        , columns =
            [ { header = E.none
              , width = E.fill
              , view =
                    \( label, val ) ->
                        case val of
                            String _ _ ->
                                E.text label

                            Int getter setter ->
                                let
                                    field =
                                        getter config
                                in
                                E.el
                                    [ EEvents.onMouseDown (PointerLock (setter { field | isChanging = True }))
                                    ]
                                    (E.text label)

                            Float getter setter ->
                                let
                                    field =
                                        getter config
                                in
                                E.el
                                    [ EEvents.onMouseDown (PointerLock (setter { field | isChanging = True }))
                                    ]
                                    (E.text label)

                            Color _ _ ->
                                E.text label
              }
            , { header = E.none
              , width = E.fill
              , view = viewChanger config
              }
            ]
        }


viewChanger : config -> ( String, FieldData config ) -> Element (Msg config)
viewChanger config ( label, val ) =
    case val of
        String getter setter ->
            textInputHelper
                { label = label
                , valStr = (getter config).val
                , setterMsg = \newStr -> ChangeConfig (setter (StringField newStr))
                }

        Int getter setter ->
            let
                field =
                    getter config
            in
            textInputHelper
                { label = label
                , valStr = String.fromInt field.val
                , setterMsg =
                    \newStr ->
                        case String.toInt newStr of
                            Just newNum ->
                                ChangeConfig (setter { field | val = newNum })

                            Nothing ->
                                ChangeConfig identity
                }

        Float getter setter ->
            let
                field =
                    getter config
            in
            textInputHelper
                { label = label
                , valStr = String.fromFloat (getter config).val
                , setterMsg =
                    \newStr ->
                        case String.toFloat newStr of
                            Just newNum ->
                                ChangeConfig (setter { field | val = newNum })

                            Nothing ->
                                ChangeConfig identity
                }

        Color getter setter ->
            let
                colorVal =
                    (getter config).val

                meta =
                    case (getter config).meta of
                        ColorFieldMeta m ->
                            m
            in
            if meta.isOpen then
                ColorPicker.view
                    colorVal
                    meta.state
                    |> E.html
                    |> E.map
                        (\pickerMsg ->
                            let
                                ( newPickerState, newColor ) =
                                    ColorPicker.update
                                        pickerMsg
                                        colorVal
                                        meta.state
                            in
                            ChangeConfig <|
                                setter
                                    { val = newColor |> Maybe.withDefault colorVal
                                    , meta =
                                        ColorFieldMeta
                                            { state = newPickerState
                                            , isOpen = meta.isOpen
                                            }
                                    }
                        )

            else
                EInput.text
                    [ EBackground.color (colorForE colorVal)
                    , EEvents.onMouseDown
                        (ChangeConfig <|
                            setter
                                { val = colorVal
                                , meta =
                                    ColorFieldMeta
                                        { state = meta.state
                                        , isOpen = True
                                        }
                                }
                        )
                    ]
                    { label = EInput.labelHidden label
                    , text = ""
                    , onChange = always <| ChangeConfig identity
                    , placeholder = Nothing
                    }


textInputHelper : { label : String, valStr : String, setterMsg : String -> Msg config } -> Element (Msg config)
textInputHelper { label, valStr, setterMsg } =
    EInput.text []
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



-- JSON


type alias EncodeOptions =
    { withMeta : Bool
    }


encode : List ( String, String, FieldData config ) -> config -> JE.Value
encode list config =
    list
        |> List.map
            (\( key, _, fieldData ) ->
                ( key
                , case fieldData of
                    Int getter _ ->
                        JE.int (getter config).val

                    Float getter _ ->
                        JE.float (getter config).val

                    String getter _ ->
                        JE.string (getter config).val

                    Color getter _ ->
                        (getter config).val
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


type alias DecoderOptions =
    { defaultInt : Int
    , defaultFloat : Float
    , defaultString : String
    , defaultColor : Color
    }


int : DecoderOptions -> JE.Value -> String -> IntField
int options json key =
    let
        constructor num =
            { val = num
            , isChanging = False
            }
    in
    JD.decodeValue
        (JD.field key JD.int
            |> JD.map constructor
        )
        json
        |> Result.withDefault (constructor options.defaultInt)


float : DecoderOptions -> JE.Value -> String -> FloatField
float options json key =
    let
        constructor num =
            { val = num
            , isChanging = False
            }
    in
    JD.decodeValue
        (JD.field key JD.float
            |> JD.map constructor
        )
        json
        |> Result.withDefault (constructor options.defaultFloat)


string : DecoderOptions -> JE.Value -> String -> StringField
string options json key =
    JD.decodeValue
        (JD.field key JD.string
            |> JD.map
                (\str ->
                    { val = str }
                )
        )
        json
        |> Result.withDefault { val = options.defaultString }


colorValDecoder : JD.Decoder Color
colorValDecoder =
    JD.map4 Color.rgba
        (JD.field "r" JD.float)
        (JD.field "g" JD.float)
        (JD.field "b" JD.float)
        (JD.field "a" JD.float)


color : DecoderOptions -> JE.Value -> String -> ColorField
color options json key =
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
        |> Result.withDefault (constructor options.defaultColor)
