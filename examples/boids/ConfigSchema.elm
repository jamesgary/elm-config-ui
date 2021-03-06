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
    , ( "Power", FloatKind "separationPower" )
    , ( "Personal space", FloatKind "separationRangeFactor" )

    -- rule 4: Mouse
    , ( "Rule 4: Mouse", SectionKind )
    , ( "Factor", FloatKind "mouseFactor" )

    -- visuals
    , ( "Boid Visuals", SectionKind )
    , ( "Sky color", ColorKind "skyColor" )

    -- config container
    , ( "Config container", SectionKind )
    , ( "BG color", ColorKind "configTableBgColor" )
    , ( "Border width", IntKind "configTableBorderWidth" )
    , ( "Border color", ColorKind "configTableBorderColor" )
    , ( "Padding", IntKind "configTablePadding" )
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
