port module Main exposing (main)

import Browser
import Color exposing (Color)
import ColorPicker
import ConfigForm
import Element as E exposing (Element)
import Element.Background as EBackground
import Element.Events as EEvents
import Element.Font as EFont
import Element.Input as EInput
import Html exposing (Html)
import Json.Decode as JD
import Json.Decode.Pipeline as JDP
import Json.Encode as JE


port performEffect : JD.Value -> Cmd msg


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { config : Config
    }


type alias Config =
    { fooFontSize : ConfigForm.FloatField
    , fooString : ConfigForm.StringField
    , barFontSize : ConfigForm.FloatField
    , barString : ConfigForm.StringField
    , barColor : ConfigForm.ColorField
    , someNum : ConfigForm.IntField
    }


type Msg
    = ConfigFormMsg (ConfigForm.Msg Config)


type alias Flags =
    { localStorage : LocalStorage
    , configFile : Config
    }


type alias LocalStorage =
    { config : Config
    }


init : JE.Value -> ( Model, Cmd Msg )
init jsonFlags =
    ( { config =
            { fooFontSize = ConfigForm.FloatField 24
            , fooString = ConfigForm.StringField "hi im foo"
            , barFontSize = ConfigForm.FloatField 36
            , barString = ConfigForm.StringField "hello im bar"
            , barColor = ConfigForm.ColorField (Color.rgba 0 0.4 0.9 0.5) ColorPicker.empty False
            , someNum = ConfigForm.IntField 5
            }
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ConfigFormMsg configFormMsg ->
            ( { model | config = ConfigForm.update configFormMsg model.config }
            , Cmd.none
            )


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
            , ConfigForm.view config formList
                |> E.map ConfigFormMsg
            ]
        )


formList : List ( String, ConfigForm.FieldData Config )
formList =
    [ ( "Foo font size", ConfigForm.Float .fooFontSize (\a c -> { c | fooFontSize = a }) )
    , ( "Foo string", ConfigForm.String .fooString (\a c -> { c | fooString = a }) )
    , ( "Bar font size", ConfigForm.Float .barFontSize (\a c -> { c | barFontSize = a }) )
    , ( "Bar string", ConfigForm.String .barString (\a c -> { c | barString = a }) )
    , ( "Bar color", ConfigForm.Color .barColor (\a c -> { c | barColor = a }) )
    , ( "Some num", ConfigForm.Int .someNum (\a c -> { c | someNum = a }) )
    ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


colorForE : Color -> E.Color
colorForE color =
    color
        |> Color.toRgba
        |> (\{ red, green, blue, alpha } ->
                E.rgba red green blue alpha
           )
