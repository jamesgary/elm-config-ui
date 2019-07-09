module Main exposing (main)

import Dict exposing (Dict)
import Egg.ConfigFormGenerator exposing (Kind(..), toFile)
import Html exposing (Html)


sample : List ( String, Kind )
sample =
    [ ( "Header font size", IntKind "headerFontSize" )
    , ( "Header element", ElementKind "headerElement" )
    , ( "Header string", StringKind "headerString" )
    , ( "Subheader font size", IntKind "subheaderFontSize" )
    , ( "Subheader string", StringKind "subheaderString" )
    , ( "Subheader color", ColorKind "subheaderColor" )
    , ( "Subheader padding", IntKind "subheaderPadding" )
    , ( "Num of subheaders", IntKind "subheaderNum" )
    , ( "Config table container", SectionKind )
    , ( "BG color", ColorKind "configTableBgColor" )
    , ( "Border width", IntKind "configTableBorderWidth" )
    , ( "Border color", ColorKind "configTableBorderColor" )
    , ( "Padding", IntKind "configTablePadding" )
    , ( "Config", SectionKind )
    , ( "Row spacing", IntKind "configRowSpacing" )
    , ( "Label highlight BG color", ColorKind "configLabelHighlightBgColor" )
    , ( "Font size", IntKind "configFontSize" )
    , ( "Input height", IntKind "configInputHeight" )
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
