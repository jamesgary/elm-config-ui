-- GENERATED CODE, DO NOT EDIT BY HAND!


module Config exposing (Config, empty, logics)

import Color exposing (Color)
import ConfigForm as ConfigForm


type alias Config =
    { viewportWidth : Float
    , viewportHeight : Float
    , skyColor : Color
    , numBoids : Int
    , boidRad : Float
    , maxSpeed : Float
    , momentumFactor : Float
    , showCohesionVel : Bool
    , cohesionFactor : Float
    , cohesionRange : Float
    , showCohesionRange : Bool
    , showAlignmentVel : Bool
    , alignmentFactor : Float
    , alignmentRange : Float
    , showAlignmentRange : Bool
    , showSeparationVel : Bool
    , separationFactor : Float
    , separationRange : Float
    , showSeparationRange : Bool
    , showSight : Bool
    , showVels : Bool
    , configTableBgColor : Color
    , configTableBorderWidth : Int
    , configTableBorderColor : Color
    , configTablePadding : Int
    , configRowSpacing : Int
    , configLabelHighlightBgColor : Color
    , configFontSize : Int
    , configInputHeight : Int
    , configInputWidth : Int
    }


empty : ConfigForm.Defaults -> Config
empty defaults =
    { viewportWidth = defaults.float
    , viewportHeight = defaults.float
    , skyColor = defaults.color
    , numBoids = defaults.int
    , boidRad = defaults.float
    , maxSpeed = defaults.float
    , momentumFactor = defaults.float
    , showCohesionVel = defaults.bool
    , cohesionFactor = defaults.float
    , cohesionRange = defaults.float
    , showCohesionRange = defaults.bool
    , showAlignmentVel = defaults.bool
    , alignmentFactor = defaults.float
    , alignmentRange = defaults.float
    , showAlignmentRange = defaults.bool
    , showSeparationVel = defaults.bool
    , separationFactor = defaults.float
    , separationRange = defaults.float
    , showSeparationRange = defaults.bool
    , showSight = defaults.bool
    , showVels = defaults.bool
    , configTableBgColor = defaults.color
    , configTableBorderWidth = defaults.int
    , configTableBorderColor = defaults.color
    , configTablePadding = defaults.int
    , configRowSpacing = defaults.int
    , configLabelHighlightBgColor = defaults.color
    , configFontSize = defaults.int
    , configInputHeight = defaults.int
    , configInputWidth = defaults.int
    }


logics : List (ConfigForm.Logic Config)
logics =
    [ ConfigForm.float
        "viewportWidth"
        "Viewport width (px)"
        .viewportWidth
        (\a c -> { c | viewportWidth = a })
    , ConfigForm.float
        "viewportHeight"
        "Viewport height (px)"
        .viewportHeight
        (\a c -> { c | viewportHeight = a })
    , ConfigForm.color
        "skyColor"
        "Sky color"
        .skyColor
        (\a c -> { c | skyColor = a })
    , ConfigForm.int
        "numBoids"
        "# of boids"
        .numBoids
        (\a c -> { c | numBoids = a })
    , ConfigForm.float
        "boidRad"
        "Boid radius (px)"
        .boidRad
        (\a c -> { c | boidRad = a })
    , ConfigForm.float
        "maxSpeed"
        "Max speed"
        .maxSpeed
        (\a c -> { c | maxSpeed = a })
    , ConfigForm.section
        "Rule 0: Momentum"
    , ConfigForm.float
        "momentumFactor"
        "Factor"
        .momentumFactor
        (\a c -> { c | momentumFactor = a })
    , ConfigForm.section
        "Rule 1: Cohesion"
    , ConfigForm.bool
        "showCohesionVel"
        "Show vel"
        .showCohesionVel
        (\a c -> { c | showCohesionVel = a })
    , ConfigForm.float
        "cohesionFactor"
        "Factor"
        .cohesionFactor
        (\a c -> { c | cohesionFactor = a })
    , ConfigForm.float
        "cohesionRange"
        "Range"
        .cohesionRange
        (\a c -> { c | cohesionRange = a })
    , ConfigForm.bool
        "showCohesionRange"
        "Show range"
        .showCohesionRange
        (\a c -> { c | showCohesionRange = a })
    , ConfigForm.section
        "Rule 2: Alignment"
    , ConfigForm.bool
        "showAlignmentVel"
        "Show vel"
        .showAlignmentVel
        (\a c -> { c | showAlignmentVel = a })
    , ConfigForm.float
        "alignmentFactor"
        "Factor"
        .alignmentFactor
        (\a c -> { c | alignmentFactor = a })
    , ConfigForm.float
        "alignmentRange"
        "Range"
        .alignmentRange
        (\a c -> { c | alignmentRange = a })
    , ConfigForm.bool
        "showAlignmentRange"
        "Show range"
        .showAlignmentRange
        (\a c -> { c | showAlignmentRange = a })
    , ConfigForm.section
        "Rule 3: Separation"
    , ConfigForm.bool
        "showSeparationVel"
        "Show vel"
        .showSeparationVel
        (\a c -> { c | showSeparationVel = a })
    , ConfigForm.float
        "separationFactor"
        "Factor"
        .separationFactor
        (\a c -> { c | separationFactor = a })
    , ConfigForm.float
        "separationRange"
        "Range"
        .separationRange
        (\a c -> { c | separationRange = a })
    , ConfigForm.bool
        "showSeparationRange"
        "Show range"
        .showSeparationRange
        (\a c -> { c | showSeparationRange = a })
    , ConfigForm.section
        "Boid Visuals"
    , ConfigForm.bool
        "showSight"
        "Show sight"
        .showSight
        (\a c -> { c | showSight = a })
    , ConfigForm.bool
        "showVels"
        "Show vels"
        .showVels
        (\a c -> { c | showVels = a })
    , ConfigForm.section
        "Config table container"
    , ConfigForm.color
        "configTableBgColor"
        "BG color"
        .configTableBgColor
        (\a c -> { c | configTableBgColor = a })
    , ConfigForm.int
        "configTableBorderWidth"
        "Border width"
        .configTableBorderWidth
        (\a c -> { c | configTableBorderWidth = a })
    , ConfigForm.color
        "configTableBorderColor"
        "Border color"
        .configTableBorderColor
        (\a c -> { c | configTableBorderColor = a })
    , ConfigForm.int
        "configTablePadding"
        "Padding"
        .configTablePadding
        (\a c -> { c | configTablePadding = a })
    , ConfigForm.section
        "Config table"
    , ConfigForm.int
        "configRowSpacing"
        "Row spacing"
        .configRowSpacing
        (\a c -> { c | configRowSpacing = a })
    , ConfigForm.color
        "configLabelHighlightBgColor"
        "Label highlight BG color"
        .configLabelHighlightBgColor
        (\a c -> { c | configLabelHighlightBgColor = a })
    , ConfigForm.int
        "configFontSize"
        "Font size"
        .configFontSize
        (\a c -> { c | configFontSize = a })
    , ConfigForm.int
        "configInputHeight"
        "Input height"
        .configInputHeight
        (\a c -> { c | configInputHeight = a })
    , ConfigForm.int
        "configInputWidth"
        "Input width"
        .configInputWidth
        (\a c -> { c | configInputWidth = a })
    ]


--: ""
