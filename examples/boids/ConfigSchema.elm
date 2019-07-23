module ConfigSchema exposing (main)

import ConfigFormGenerator exposing (Kind(..))
import Html exposing (Html)


myConfigFields : List ( String, Kind )
myConfigFields =
    [ ( "Viewport width (px)", FloatKind "viewportWidth" )
    , ( "Viewport height (px)", FloatKind "viewportHeight" )
    , ( "Sky color", ColorKind "skyColor" )

    -- boids
    , ( "# of boids", IntKind "numBoids" )
    , ( "Boid radius (px)", FloatKind "boidRad" )
    , ( "Boid sight (px)", FloatKind "boidSight" )
    , ( "Boid personal space (px)", FloatKind "boidPersonalSpace" )
    , ( "Alignment factor", FloatKind "alignmentFactor" )
    , ( "Center of mass factor", FloatKind "centerOfMassFactor" )
    , ( "Avoidance factor", FloatKind "avoidanceFactor" )
    , ( "Momentum factor", FloatKind "momentumFactor" )
    , ( "Max speed", FloatKind "maxSpeed" )

    -- visuals
    , ( "Boid Visuals", SectionKind )
    , ( "Show sight", BoolKind "showSight" )
    , ( "Show vels", BoolKind "showVels" )

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
