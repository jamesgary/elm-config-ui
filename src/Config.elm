module Config exposing (Config, formFields, new)

import Color exposing (Color)
import ColorPicker
import ConfigForm as CF


type alias Config =
    { fooFontSize : CF.FloatField
    , fooString : CF.StringField
    , barFontSize : CF.FloatField
    , barString : CF.StringField
    , barColor : CF.ColorField
    , someNum : CF.IntField
    }


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
