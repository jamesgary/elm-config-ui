module Main exposing (main)

import Browser
import Color exposing (Color)
import ColorPicker
import Element as E exposing (Element)
import Element.Background as EBackground
import Element.Font as EFont
import Element.Input as EInput
import Html exposing (Html)


main : Program () Model Msg
main =
    Browser.sandbox
        { init = init
        , view = view
        , update = update
        }


type alias Model =
    { config : Config
    }


type alias Config =
    { fooFontSize : CFloat
    , fooString : CString
    , barFontSize : CFloat
    , barString : CString
    , barColor : CColor
    , someNum : CInt
    }


type alias CInt =
    { val : Int
    }


type alias CFloat =
    { val : Float
    }


type alias CString =
    { val : String
    }


type alias CColor =
    { val : Color
    , state : ColorPicker.State
    }


type Msg
    = ChangeConfig (Config -> Config)
    | NoOp


init : Model
init =
    { config =
        { fooFontSize = CFloat 24
        , fooString = CString "hi im foo"
        , barFontSize = CFloat 36
        , barString = CString "hello im bar"
        , barColor = CColor (Color.rgba 0 0.4 0.9 0.5) ColorPicker.empty
        , someNum = CInt 5
        }
    }


update : Msg -> Model -> Model
update msg model =
    case msg of
        NoOp ->
            model

        ChangeConfig updater ->
            { model | config = updater model.config }


view : Model -> Html Msg
view { config } =
    E.layout [ E.padding 20 ]
        (E.column []
            [ E.row
                [ EFont.size (round config.fooFontSize.val)
                ]
                [ E.text <| "Foo: " ++ config.fooString.val ]
            , E.row
                [ EFont.size (round config.barFontSize.val)
                , EBackground.color (colorForE config.barColor.val)
                ]
                [ E.text <| "Bar: " ++ config.barString.val ]
            , E.row [] [ E.text " " ]
            , E.row [] [ E.text "---" ]
            , E.row [] [ E.text " " ]
            , viewConfig config
            ]
        )


colorForE : Color -> E.Color
colorForE color =
    color
        |> Color.toRgba
        |> (\{ red, green, blue, alpha } ->
                E.rgba red green blue alpha
           )


px : Float -> String
px num =
    String.fromFloat num ++ "px"



--(List.map (viewConfigVal model.config) form)


type ConfigVal
    = String (Config -> CString) (CString -> Config -> Config)
    | Int (Config -> CInt) (CInt -> Config -> Config)
    | Float (Config -> CFloat) (CFloat -> Config -> Config)
    | Color (Config -> CColor) (CColor -> Config -> Config)


formList : List ( String, ConfigVal )
formList =
    [ ( "Foo font size", Float .fooFontSize (\a c -> { c | fooFontSize = a }) )
    , ( "Foo string", String .fooString (\a c -> { c | fooString = a }) )
    , ( "Bar font size", Float .barFontSize (\a c -> { c | barFontSize = a }) )
    , ( "Bar string", String .barString (\a c -> { c | barString = a }) )
    , ( "Bar color", Color .barColor (\a c -> { c | barColor = a }) )
    , ( "Some num", Int .someNum (\a c -> { c | someNum = a }) )
    ]


viewConfig : Config -> Element Msg
viewConfig config =
    E.table []
        { data = formList
        , columns =
            [ { header = E.none
              , width = E.fill
              , view =
                    \( label, configVal ) ->
                        E.text label
              }
            , { header = E.none
              , width = E.fill
              , view = viewChanger config
              }
            ]
        }


viewChanger : Config -> ( String, ConfigVal ) -> Element Msg
viewChanger config ( label, configVal ) =
    case configVal of
        String getter setter ->
            textInputHelper
                { label = label
                , valStr = (getter config).val
                , setterMsg = \newStr -> ChangeConfig (setter (CString newStr))
                }

        Int getter setter ->
            textInputHelper
                { label = label
                , valStr = String.fromInt (getter config).val
                , setterMsg =
                    \newStr ->
                        case String.toInt newStr of
                            Just newNum ->
                                ChangeConfig (setter (CInt newNum))

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
                                ChangeConfig (setter (CFloat newNum))

                            Nothing ->
                                ChangeConfig identity
                }

        Color getter setter ->
            ColorPicker.view
                (getter config).val
                (getter config).state
                |> E.html
                |> E.map
                    (\pickerMsg ->
                        let
                            ( newPickerState, newColor ) =
                                ColorPicker.update
                                    pickerMsg
                                    (getter config).val
                                    (getter config).state
                        in
                        ChangeConfig <|
                            setter
                                { val = newColor |> Maybe.withDefault (getter config).val
                                , state = newPickerState
                                }
                    )


textInputHelper : { label : String, valStr : String, setterMsg : String -> Msg } -> Element Msg
textInputHelper { label, valStr, setterMsg } =
    EInput.text []
        { label = EInput.labelHidden label
        , text = valStr
        , onChange = setterMsg
        , placeholder = Nothing
        }
