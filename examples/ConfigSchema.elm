module ConfigSchema exposing (main)

import ConfigFormGenerator exposing (Kind(..))
import Html exposing (Html)


myConfigFields : List ( String, Kind )
myConfigFields =
    [ ( "Header font size", IntKind "headerFontSize" )
    , ( "Header string", StringKind "headerString" )
    , ( "Show subheaders", BoolKind "showSubheaders" )
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
            ConfigFormGenerator.toFile myConfigFields

        _ =
            Debug.log generatedElmCode ""
    in
    Html.text ""