module Config exposing (Config, encode, ff, formFields, new, view)

import Color exposing (Color)
import ColorPicker
import ConfigForm as CF
import Element as E exposing (Element)
import Json.Decode as JD
import Json.Decode.Pipeline as JDP
import Json.Encode as JE


type alias Config =
    { fooFontSize : CF.FloatField
    , fooString : CF.StringField
    , barFontSize : CF.FloatField
    , barString : CF.StringField
    , barColor : CF.ColorField
    , configTableBgColor : CF.ColorField
    , configTableSpacing : CF.IntField
    , configTablePadding : CF.IntField
    , configTableBorderWidth : CF.IntField
    , configTableBorderColor : CF.ColorField
    , configLabelHighlightBgColor : CF.ColorField
    }


new : JE.Value -> Config
new jsonConfig =
    let
        options =
            { defaultInt = 1
            , defaultFloat = 1
            , defaultString = "SORRY IM NEW HERE"
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
        |> with "configTableBgColor" CF.color
        |> with "configTableSpacing" CF.int
        |> with "configTablePadding" CF.int
        |> with "configTableBorderWidth" CF.int
        |> with "configTableBorderColor" CF.color
        |> with "configLabelHighlightBgColor" CF.color


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
    , ( "configTableBgColor"
      , "Config: Table BG color"
      , CF.Color .configTableBgColor (\a c -> { c | configTableBgColor = a })
      )
    , ( "configTableSpacing"
      , "Config: Table spacing"
      , CF.Int .configTableSpacing (\a c -> { c | configTableSpacing = a })
      )
    , ( "configTablePadding"
      , "Config: Table padding"
      , CF.Int .configTablePadding (\a c -> { c | configTablePadding = a })
      )
    , ( "configTableBorderWidth"
      , "Config: Table border width"
      , CF.Int .configTableBorderWidth (\a c -> { c | configTableBorderWidth = a })
      )
    , ( "configTableBorderColor"
      , "Config: Table border color"
      , CF.Color .configTableBorderColor (\a c -> { c | configTableBorderColor = a })
      )
    , ( "configLabelHighlightBgColor"
      , "Config: Highlighted label BG color"
      , CF.Color .configLabelHighlightBgColor (\a c -> { c | configLabelHighlightBgColor = a })
      )
    ]


encode : Config -> JE.Value
encode config =
    CF.encode ff config


view : Config -> Element (CF.Msg Config)
view config =
    CF.view config
        formFields
        (CF.viewOptions
            |> CF.withTableBgColor config.configTableBgColor.val
            |> CF.withTableSpacing config.configTableSpacing.val
            |> CF.withTablePadding config.configTablePadding.val
            |> CF.withTableBorderWidth config.configTableBorderWidth.val
            |> CF.withTableBorderColor config.configTableBorderColor.val
            |> CF.withLabelHighlightBgColor config.configLabelHighlightBgColor.val
        )


formFields : List ( String, CF.FieldData Config )
formFields =
    ff
        |> List.map
            (\( key, label, fieldData ) ->
                ( label, fieldData )
            )
