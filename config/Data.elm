module Data exposing (main)

import ConfigGenerator
import Html exposing (Html)


sample =
    [ ( "fooFontSize", CF.FloatField )
    , ( "fooString", CF.StringField )
    , ( "barFontSize", CF.FloatField )
    , ( "barString", CF.StringField )
    , ( "barColor", CF.ColorField )
    , ( "configTableBgColor", CF.ColorField )
    , ( "configTableSpacing", CF.IntField )
    , ( "configTablePadding", CF.IntField )
    , ( "configTableBorderWidth", CF.IntField )
    , ( "configTableBorderColor", CF.ColorField )
    , ( "configLabelHighlightBgColor", CF.ColorField )
    ]


main : Html msg
main =
    let
        generatedElmCode =
            """
module Config exposing (Config)

import ConfigForm as CF


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
--"""

        _ =
            Debug.log generatedElmCode ""
    in
    Html.text ""
