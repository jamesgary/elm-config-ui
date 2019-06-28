module Main exposing (main)

import Dict exposing (Dict)
import Egg.ConfigFormGenerator exposing (Kind(..), toFile)
import Html exposing (Html)


sample : List ( String, Kind )
sample =
    [ ( "Header font size", IntKind "headerFontSize" )
    , ( "Header string", StringKind "headerString" )
    , ( "Subheader font size", IntKind "subheaderFontSize" )
    , ( "Subheader string", StringKind "subheaderString" )
    , ( "Subheader color", ColorKind "subheaderColor" )
    , ( "Subheader padding", IntKind "subheaderPadding" )
    , ( "Num of subheaders", IntKind "subheaderNum" )
    , ( "Config table BG color", ColorKind "configTableBgColor" )
    , ( "Config table border width", IntKind "configTableBorderWidth" )
    , ( "Config table border color", ColorKind "configTableBorderColor" )
    , ( "Config table padding", IntKind "configTablePadding" )
    , ( "Config table spacing", IntKind "configTableSpacing" )
    , ( "Config label highlight BG color", ColorKind "configLabelHighlightBgColor" )
    , ( "Config font size", IntKind "configFontSize" )
    , ( "Config input height", IntKind "configInputHeight" )
    ]


main : Html msg
main =
    let
        generatedElmCode =
            toFile sample

        _ =
            Debug.log generatedElmCode ""
    in
    Html.text ""
