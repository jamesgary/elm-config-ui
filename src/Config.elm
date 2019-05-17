module Config exposing (Config, decoder, encodeForFile, encodeForLocalStorage, formFields, new)

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


decoder : JD.Decoder Config
decoder =
    let
        options =
            { defaultInt = 1
            , defaultFloat = 1
            , defaultString = "WWWWWWWWW"
            , defaultColor = Color.rgba 1 0 1 1 -- hot pink!
            }

        at =
            CF.at options
    in
    JD.succeed Config
        |> at "fooFontSize" CF.floatDecoder
        |> at "fooString" CF.stringDecoder
        |> at "barFontSize" CF.floatDecoder
        |> at "barString" CF.stringDecoder
        |> at "barColor" CF.colorDecoder
        |> at "someNum" CF.intDecoder



{-

   CF.new Config
     |> with "fooFontSize" CF.

-}
{-
   JD.succeed Config
       |> JDP.required "fooFontSize" CF.floatDecoder
       |> JDP.required "fooString" CF.stringDecoder
       |> JDP.required "barFontSize" CF.floatDecoder
       |> JDP.required "barString" CF.stringDecoder
       |> JDP.required "barColor" CF.colorDecoder
       |> JDP.required "someNum" CF.intDecoder
-}


encodeForLocalStorage : Config -> JE.Value
encodeForLocalStorage config =
    encode { withMeta = True } config


encodeForFile : Config -> JE.Value
encodeForFile config =
    encode { withMeta = False } config


encode : CF.EncodeOptions -> Config -> JE.Value
encode options config =
    CF.encode options
        [ ( "fooFontSize", CF.encodeFloat config.fooFontSize )
        , ( "fooString", CF.encodeString config.fooString )
        , ( "barFontSize", CF.encodeFloat config.barFontSize )
        , ( "barString", CF.encodeString config.barString )
        , ( "barColor", CF.encodeColor config.barColor )
        , ( "someNum", CF.encodeInt config.someNum )
        ]


new =
    { fooFontSize = CF.float 24
    , fooString = CF.string "hi im foo"
    , barFontSize = CF.float 36
    , barString = CF.string "hello im bar"
    , barColor = CF.color (Color.rgba 0 0.4 0.9 0.5)
    , someNum = CF.IntField 5
    }


formFields : List ( String, CF.FieldData Config )
formFields =
    [ ( "Foo font size", CF.Float .fooFontSize (\a c -> { c | fooFontSize = a }) )
    , ( "Foo string", CF.String .fooString (\a c -> { c | fooString = a }) )
    , ( "Bar font size", CF.Float .barFontSize (\a c -> { c | barFontSize = a }) )
    , ( "Bar string", CF.String .barString (\a c -> { c | barString = a }) )
    , ( "Bar color", CF.Color .barColor (\a c -> { c | barColor = a }) )
    , ( "Some num", CF.Int .someNum (\a c -> { c | someNum = a }) )
    ]
