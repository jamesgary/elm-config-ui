module ConfigSchema exposing (main)

import ConfigFormGenerator exposing (Kind(..))
import Html exposing (Html)


myConfigFields : List ( String, Kind )
myConfigFields =
    [ ( "Viewport width (px)", IntKind "viewportWidth" )
    , ( "Viewport height (px)", IntKind "viewportHeight" )
    , ( "Sky color", ColorKind "skyColor" )
    , ( "Random Seed", IntKind "seed" )

    -- ground
    , ( "Ground", SectionKind )
    , ( "Ground color", ColorKind "groundColor" )
    , ( "Ground height (px)", IntKind "groundHeight" )

    -- tree
    , ( "Tree logic", SectionKind )
    , ( "cloudHeight", FloatKind "cloudHeight" )
    , ( "cloudRad", FloatKind "cloudRad" )
    , ( "cloudCount", IntKind "cloudCount" )
    , ( "growDist", FloatKind "growDist" )
    , ( "minDist", FloatKind "minDist" )
    , ( "maxDist", FloatKind "maxDist" )

    -- tree visuals
    , ( "Tree visuals", SectionKind )
    , ( "Cloud point radius", FloatKind "cloudPointRad" )
    , ( "Cloud point color", ColorKind "cloudPointColor" )
    , ( "Tree color", ColorKind "treeColor" )
    , ( "Branch thickness", FloatKind "branchThickness" )

    -- config table container
    , ( "Config table container", SectionKind )
    , ( "BG color", ColorKind "configTableBgColor" )
    , ( "Border width", IntKind "configTableBorderWidth" )
    , ( "Border color", ColorKind "configTableBorderColor" )
    , ( "Padding", IntKind "configTablePadding" )

    -- config table
    , ( "Config table", SectionKind )
    , ( "Row spacing", IntKind "configRowSpacing" )
    , ( "Label highlight BG color", ColorKind "configLabelHighlightBgColor" )
    , ( "Font size", IntKind "configFontSize" )
    , ( "Input height", IntKind "configInputHeight" )
    , ( "Input width", IntKind "configInputWidth" )
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
