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



-- FLAGS


type alias Flags =
    { localStorage : LocalStorage
    , configFile : JE.Value
    }


decodeFlags : JD.Decoder Flags
decodeFlags =
    JD.succeed Flags
        |> JDP.required "localStorage" decodeLocalStorage
        |> JDP.required "configFile" JD.value



-- LOCALSTORAGE


type alias LocalStorage =
    { config : JE.Value
    }


decodeLocalStorage : JD.Decoder LocalStorage
decodeLocalStorage =
    JD.succeed LocalStorage
        |> JDP.optional "config" JD.value (JE.object [])



-- INIT


init : JE.Value -> ( Model, Cmd Msg )
init jsonFlags =
    {-
          dev
          - adding fields
            - warn that LS is growing past file, better save if you don't wanna break the prod build!
          - just pulled master, new fields found
            - update LS with new fields, no worries
          prod
          - check file, must be immaculate

          file could also have version
          0.0
          0.x if value changed
          x.0 if field got added/removed

        I feed my config the file and localstorage

        if file is empty or malformed:
          start at 0.0
          try to use localstorage to populate form

        when i begin with empty

        variables:
        - dev or prod version? hard fail if prod
        - does LS have more fields than file?
        - does LS have less fields than file?
        - 3 truths: LS, File, and encoder/decoder

        -- maybe whenever i decode, i encode and decode again
        -- maybe whenever i encode, i decode and encode again

        -- what are my fears?
        - not encoding all fields correctly
        - not decoding all fields correctly
          - WARNING: config.json is out-of-date! Please _update_ it before commiting changes.
        - not adding all relevant fields to form
        - procrastinating saving to file
          - WARNING: config.json is out-of-date! Please _update_ it before commiting changes.

       -----
       okay so when i start in fresh browser,
       - file oughtta be there
       - LS won't, so just pull from file
    -}
    case JD.decodeValue decodeFlags jsonFlags of
        Ok flags ->
            ( { config = Config.new flags.localStorage.config
              }
            , Cmd.none
            )

        Err err ->
            Debug.todo (JD.errorToString err)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ConfigFormMsg configFormMsg ->
            let
                newConfig =
                    CF.update configFormMsg model.config

                newModel =
                    { model | config = newConfig }
            in
            ( newModel
            , saveToLocalStorageCmd newModel
            )


saveToLocalStorageCmd : Model -> Cmd Msg
saveToLocalStorageCmd model =
    performEffect <|
        JE.object
            [ ( "id", JE.string "SAVE" )
            , ( "value"
              , JE.object
                    [ ( "config"
                      , Config.encodeForLocalStorage model.config
                      )
                    ]
              )
            ]


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
