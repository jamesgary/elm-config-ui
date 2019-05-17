module Config exposing (Config, encodeForFile, encodeForLocalStorage, formFields, new)

import Color exposing (Color)
import ColorPicker
import ConfigForm as CF
import Json.Decode as JD
import Json.Decode.Pipeline as JDP
import Json.Encode as JE


type alias Config =
    { fooFontSize : CF.FloatField
    , fooString : CF.StringField
    , barFontSize : CF.FloatField
    , barString : CF.StringField
    , barColor : CF.ColorField
    , someNum : CF.IntField
    }


new : JE.Value -> Config
new jsonConfig =
    let
        options =
            { defaultInt = 1
            , defaultFloat = 1
            , defaultString = "SORRY I'M NEW HERE"
            , defaultColor = Color.rgba 1 0 1 1 -- hot pink!
            }

        with key fieldDecoder curriedConfig =
            curriedConfig (fieldDecoder options jsonConfig key)
    in
    Config
        |> with "fooFontSize" CF.float
        |> with "fooString" CF.string
        |> with "barFontSize" CF.float
        |> with "barString" CF.string
        |> with "barColor" CF.color
        |> with "someNum" CF.int


encodeForLocalStorage : Config -> JE.Value
encodeForLocalStorage config =
    encode { withMeta = True } config


encodeForFile : Config -> JE.Value
encodeForFile config =
    encode { withMeta = False } config


type alias ConfigFormData config =
    ( String, String, CF.FieldData config )


ff : List (ConfigFormData Config)
ff =
    [ ( "fooFontSize"
      , "Foo font size"
      , CF.Float .fooFontSize (\a c -> { c | fooFontSize = a })
      )
    , ( "fooString"
      , "Foo string"
      , CF.String .fooString (\a c -> { c | fooString = a })
      )
    , ( "barFontSize"
      , "Bar font size"
      , CF.Float .barFontSize (\a c -> { c | barFontSize = a })
      )
    , ( "barString"
      , "Bar string"
      , CF.String .barString (\a c -> { c | barString = a })
      )
    , ( "barColor"
      , "Bar color"
      , CF.Color .barColor (\a c -> { c | barColor = a })
      )
    , ( "someNum"
      , "Some num"
      , CF.Int .someNum (\a c -> { c | someNum = a })
      )
    ]


encode : CF.EncodeOptions -> Config -> JE.Value
encode options config =
    CF.encode options ff config


formFields : List ( String, CF.FieldData Config )
formFields =
    ff
        |> List.map
            (\( key, label, fieldData ) ->
                ( label, fieldData )
            )
