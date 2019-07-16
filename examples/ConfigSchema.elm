module ConfigSchema exposing (main)

import ConfigFormGenerator exposing (Kind(..))
import Html exposing (Html)


myConfigFields : List ( String, Kind )
myConfigFields =
    [ ( "Viewport width (px)", IntKind "viewportWidth" )
    , ( "Viewport height (px)", IntKind "viewportHeight" )
    , ( "Sky color", ColorKind "skyColor" )
    , ( "Random Seed", IntKind "seed" )

    -- randomness
    , ( "Direction (deg) randomness", FloatKind "directionRand" )
    , ( "Length % growth min", FloatKind "lengthGrowthMin" )
    , ( "Length % growth max", FloatKind "lengthGrowthMax" )

    -- ground
    , ( "Ground", SectionKind )
    , ( "Ground color", ColorKind "groundColor" )
    , ( "Ground height (px)", IntKind "groundHeight" )

    -- tree
    , ( "Tree", SectionKind )
    , ( "Tree color", ColorKind "treeColor" )
    , ( "Tree trunk width", IntKind "treeTrunkWidth" )
    , ( "Tree height factor", IntKind "treeHeightFactor" )

    -- branches
    , ( "Branches", SectionKind )
    , ( "# of branches", IntKind "numBranches" )
    , ( "Branch angle range (deg)", FloatKind "branchAngleRangeDegs" )
    , ( "Branch length %", FloatKind "branchLengthPerc" )
    , ( "Branch width %", FloatKind "branchWidthPerc" )
    , ( "Branch recursions", IntKind "branchRecursions" )
    , ( "Max branches (keep low!)", IntKind "maxBranches" )

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
