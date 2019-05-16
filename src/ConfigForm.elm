module ConfigForm exposing (ColorField, FieldData(..), FloatField, IntField, Msg, StringField, color, float, int, string, update, view)

import Color exposing (Color)
import ColorPicker
import Element as E exposing (Element)
import Element.Background as EBackground
import Element.Events as EEvents
import Element.Font as EFont
import Element.Input as EInput


type alias IntField =
    { val : Int }


type alias FloatField =
    { val : Float }


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


int : Int -> IntField
int num =
    { val = num }


float : Float -> FloatField
float num =
    { val = num }


string : String -> StringField
string str =
    { val = str }


color : Color -> ColorField
color col =
    { val = col
    , meta =
        ColorFieldMeta
            { state = ColorPicker.empty
            , isOpen = False
            }
    }


type FieldData config
    = String (config -> StringField) (StringField -> config -> config)
    | Int (config -> IntField) (IntField -> config -> config)
    | Float (config -> FloatField) (FloatField -> config -> config)
    | Color (config -> ColorField) (ColorField -> config -> config)


type Msg config
    = ChangeConfig (config -> config)


type alias ConfigForm config =
    List ( String, FieldData config )


update : Msg config -> config -> config
update msg config =
    case msg of
        ChangeConfig updater ->
            updater config


view : config -> ConfigForm config -> Element (Msg config)
view config formList =
    E.table []
        { data = formList
        , columns =
            [ { header = E.none
              , width = E.fill
              , view =
                    \( label, val ) ->
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
            textInputHelper
                { label = label
                , valStr = String.fromInt (getter config).val
                , setterMsg =
                    \newStr ->
                        case String.toInt newStr of
                            Just newNum ->
                                ChangeConfig (setter (IntField newNum))

                            Nothing ->
                                ChangeConfig identity
                }

        Float getter setter ->
            textInputHelper
                { label = label
                , valStr = String.fromFloat (getter config).val
                , setterMsg =
                    \newStr ->
                        case String.toFloat newStr of
                            Just newNum ->
                                ChangeConfig (setter (FloatField newNum))

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
