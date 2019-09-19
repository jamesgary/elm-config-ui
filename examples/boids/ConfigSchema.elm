module ConfigSchema exposing (main)

import ConfigFormGenerator exposing (Kind(..))
import Html exposing (Html)


myConfigFields : List ( String, Kind )
myConfigFields =
    [ ( "Viewport width (px)", IntKind "viewportWidth" )
    , ( "Viewport height (px)", IntKind "viewportHeight" )
    , ( "Time Scale", FloatKind "timeScale" )

    -- boids
    , ( "Boids", SectionKind )
    , ( "# of boids", IntKind "numBoids" )
    , ( "Boid radius", FloatKind "boidRad" )
    , ( "Vision range", FloatKind "visionRange" )
    , ( "Show Ranges", BoolKind "showRanges" )
    , ( "Max speed", FloatKind "maxSpeed" )

    -- rule 0: Momentum (how quick to change steering)
    , ( "Rule 0: Momentum", SectionKind )
    , ( "Color", ColorKind "momentumColor" )
    , ( "Factor", FloatKind "momentumFactor" )

    -- rule 1: Cohesion (Friendly gathering at center of mass)
    , ( "Rule 1: Cohesion", SectionKind )
    , ( "Color", ColorKind "cohesionColor" )
    , ( "Factor", FloatKind "cohesionFactor" )

    -- rule 2: Alignment (conformity)
    , ( "Rule 2: Alignment", SectionKind )
    , ( "Color", ColorKind "alignmentColor" )
    , ( "Factor", FloatKind "alignmentFactor" )

    -- rule 3: Separation (personal space)
    , ( "Rule 3: Separation", SectionKind )
    , ( "Factor", FloatKind "separationFactor" )
    , ( "Color", ColorKind "separationColor" )
    , ( "Personal space factor", FloatKind "separationRangeFactor" )

    -- rule 4: Mouse
    , ( "Rule 4: Mouse", SectionKind )
    , ( "Factor", FloatKind "mouseFactor" )
    , ( "Color", ColorKind "mouseColor" )

    -- visuals
    , ( "Boid Visuals", SectionKind )
    , ( "Show vel arrows", BoolKind "showVels" )
    , ( "Arrow scale", FloatKind "arrowScale" )
    , ( "Sky color", ColorKind "skyColor" )

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
