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
    , boidSight : Float
    , boidPersonalSpace : Float
    , alignmentFactor : Float
    , centerOfMassFactor : Float
    , avoidanceFactor : Float
    , momentumFactor : Float
    , maxSpeed : Float
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
    , boidSight = defaults.float
    , boidPersonalSpace = defaults.float
    , alignmentFactor = defaults.float
    , centerOfMassFactor = defaults.float
    , avoidanceFactor = defaults.float
    , momentumFactor = defaults.float
    , maxSpeed = defaults.float
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
        "boidSight"
        "Boid sight (px)"
        .boidSight
        (\a c -> { c | boidSight = a })
    , ConfigForm.float
        "boidPersonalSpace"
        "Boid personal space (px)"
        .boidPersonalSpace
        (\a c -> { c | boidPersonalSpace = a })
    , ConfigForm.float
        "alignmentFactor"
        "Alignment factor"
        .alignmentFactor
        (\a c -> { c | alignmentFactor = a })
    , ConfigForm.float
        "centerOfMassFactor"
        "Center of mass factor"
        .centerOfMassFactor
        (\a c -> { c | centerOfMassFactor = a })
    , ConfigForm.float
        "avoidanceFactor"
        "Avoidance factor"
        .avoidanceFactor
        (\a c -> { c | avoidanceFactor = a })
    , ConfigForm.float
        "momentumFactor"
        "Momentum factor"
        .momentumFactor
        (\a c -> { c | momentumFactor = a })
    , ConfigForm.float
        "maxSpeed"
        "Max speed"
        .maxSpeed
        (\a c -> { c | maxSpeed = a })
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
