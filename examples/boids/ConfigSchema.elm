module ConfigSchema exposing (main)

import ConfigFormGenerator exposing (Kind(..))
import Html exposing (Html)


myConfigFields : List ( String, Kind )
myConfigFields =
    [ ( "Viewport width (px)", FloatKind "viewportWidth" )
    , ( "Viewport height (px)", FloatKind "viewportHeight" )

    -- boids
    , ( "Boids", SectionKind )
    , ( "# of boids", IntKind "numBoids" )
    , ( "Boid radius", FloatKind "boidRad" )
    , ( "Vision range", FloatKind "visionRange" )
    , ( "Show Ranges", BoolKind "showRanges" )
    , ( "Max speed", FloatKind "maxSpeed" )

    -- rule 0: Momentum (how quick to change steering)
    , ( "Rule 0: Momentum", SectionKind )
    , ( "Factor", FloatKind "momentumFactor" )

    -- rule 1: Cohesion (Friendly gathering at center of mass)
    , ( "Rule 1: Cohesion", SectionKind )
    , ( "Factor", FloatKind "cohesionFactor" )

    -- rule 2: Alignment (conformity)
    , ( "Rule 2: Alignment", SectionKind )
    , ( "Factor", FloatKind "alignmentFactor" )

    -- rule 3: Separation (personal space)
    , ( "Rule 3: Separation", SectionKind )
    , ( "Factor", FloatKind "separationFactor" )
    , ( "Personal space factor", FloatKind "separationRangeFactor" )

    -- rule 4: Mouse
    , ( "Rule 4: Mouse", SectionKind )
    , ( "Factor", FloatKind "mouseFactor" )

    -- visuals
    , ( "Boid Visuals", SectionKind )
    , ( "Sky color", ColorKind "skyColor" )
    , ( "Show debug vel arrows", BoolKind "showVels" )
    , ( "Arrow scale", FloatKind "arrowScale" )
    , ( "Momentum Color", ColorKind "momentumColor" )
    , ( "Cohesion Color", ColorKind "cohesionColor" )
    , ( "Alignment Color", ColorKind "alignmentColor" )
    , ( "Separation Color", ColorKind "separationColor" )
    , ( "Mouse Color", ColorKind "mouseColor" )

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
