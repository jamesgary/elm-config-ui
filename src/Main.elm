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
    { fooFontSize : Float
    , fooString : String
    , barFontSize : Float
    , barString : String
    , barColor : Color
    }


type Msg
    = ChangeConfig (Config -> Config)
    | NoOp


init : Model
init =
    { config =
        { fooFontSize = 24
        , fooString = "hi im foo"
        , barFontSize = 36
        , barString = "hello im bar"
        , barColor = Color.rgb 0 0.4 0.9
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
    = String (Config -> String) (String -> Config -> Config)
    | Int (Config -> Int) (Int -> Config -> Config)
    | Float (Config -> Float) (Float -> Config -> Config)
    | Color (Config -> Color) (Color -> Config -> Config)


formList : List ( String, ConfigVal )
formList =
    [ ( "Foo font size", Float .fooFontSize (\a c -> { c | fooFontSize = a }) )
    , ( "Foo string", String .fooString (\a c -> { c | fooString = a }) )
    , ( "Bar font size", Float .barFontSize (\a c -> { c | barFontSize = a }) )
    , ( "Bar string", String .barString (\a c -> { c | barString = a }) )
    , ( "Bar color", Color .barColor (\a c -> { c | barColor = a }) )
    ]


viewConfig : Config -> Element Msg
viewConfig config =
    E.column []
        (List.map (viewConfigRow config) formList)


viewConfigRow : Config -> ( String, ConfigVal ) -> Element Msg
viewConfigRow config ( label, configVal ) =
    case configVal of
        String getter setter ->
            textInputHelper
                { label = label
                , valStr = getter config
                , setterMsg = \newStr -> ChangeConfig (setter newStr)
                }

        Int getter setter ->
            textInputHelper
                { label = label
                , valStr = String.fromInt (getter config)
                , setterMsg =
                    \newStr ->
                        case String.toInt newStr of
                            Just newNum ->
                                ChangeConfig (setter newNum)

                            Nothing ->
                                ChangeConfig identity
                }

        Float getter setter ->
            textInputHelper
                { label = label
                , valStr = String.fromFloat (getter config)
                , setterMsg =
                    \newStr ->
                        case String.toFloat newStr of
                            Just newNum ->
                                ChangeConfig (setter newNum)

                            Nothing ->
                                ChangeConfig identity
                }

        Color _ _ ->
            Debug.todo ""



--ColorPicker.view model.colour model.colorPicker
--    |> Html.map ColorPickerMsg


textInputHelper : { label : String, valStr : String, setterMsg : String -> Msg } -> Element Msg
textInputHelper { label, valStr, setterMsg } =
    E.row []
        [ EInput.text []
            { label = EInput.labelLeft [] (E.text label)
            , text = valStr
            , onChange = setterMsg
            , placeholder = Nothing
            }
        ]
