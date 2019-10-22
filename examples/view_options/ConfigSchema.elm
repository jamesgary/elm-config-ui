module ConfigSchema exposing (main)

import ConfigFormGenerator exposing (Kind(..))
import Html exposing (Html)


myConfigFields : List ( String, Kind )
myConfigFields =
    [ ( "Header size", IntKind "headerFontSize" )
    , ( "Config wrapper", SectionKind )
    , ( "Background color", ColorKind "configBgColor" )
    , ( "Padding X", IntKind "configPaddingX" )
    , ( "Padding Y", IntKind "configPaddingY" )
    , ( "Config view options", SectionKind )
    , ( "Font Size", IntKind "configFontSize" )
    , ( "Row Spacing", IntKind "configRowSpacing" )
    , ( "Input Width", IntKind "configInputWidth" )
    , ( "Input Spacing", FloatKind "configInputSpacing" )
    , ( "Label Highlight Bg", ColorKind "configLabelHighlightBgColor" )
    , ( "Section Spacing", IntKind "configSectionSpacing" )
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
