port module Main exposing (main)

import Browser
import Color exposing (Color)
import ColorPicker
import Config exposing (Config)
import ConfigForm as CF
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


type Msg
    = ConfigFormMsg (CF.Msg Config)


type alias Flags =
    { localStorage : LocalStorage
    , configFile : Config
    }


type alias LocalStorage =
    { config : Config
    }


init : JE.Value -> ( Model, Cmd Msg )
init jsonFlags =
    ( { config = Config.new
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ConfigFormMsg configFormMsg ->
            ( { model | config = CF.update configFormMsg model.config }
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
            , CF.view config Config.formFields
                |> E.map ConfigFormMsg
            ]
        )


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
