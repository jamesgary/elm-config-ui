-- GENERATED CODE, DO NOT EDIT BY HAND!


module Config exposing (Config, empty, logics)

import Color exposing (Color)
import ConfigForm as ConfigForm


type alias Config =
    { viewportWidth : Float
    , viewportHeight : Float
    , timeScale : Float
    , numBoids : Int
    , boidRad : Float
    , visionRange : Float
    , showRanges : Bool
    , maxSpeed : Float
    , momentumFactor : Float
    , cohesionFactor : Float
    , alignmentFactor : Float
    , separationFactor : Float
    , separationRangeFactor : Float
    , mouseFactor : Float
    , mouseExponent : Float
    , showVels : Bool
    , arrowScale : Float
    , skyColor : Color
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
    , timeScale = defaults.float
    , numBoids = defaults.int
    , boidRad = defaults.float
    , visionRange = defaults.float
    , showRanges = defaults.bool
    , maxSpeed = defaults.float
    , momentumFactor = defaults.float
    , cohesionFactor = defaults.float
    , alignmentFactor = defaults.float
    , separationFactor = defaults.float
    , separationRangeFactor = defaults.float
    , mouseFactor = defaults.float
    , mouseExponent = defaults.float
    , showVels = defaults.bool
    , arrowScale = defaults.float
    , skyColor = defaults.color
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


--logics : List (ConfigForm.Logic Config)
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
    , ConfigForm.float
        "timeScale"
        "Time scale"
        .timeScale
        (\a c -> { c | timeScale = a })
    , ConfigForm.section
        "Boids"
    , ConfigForm.int
        "numBoids"
        "# of boids"
        .numBoids
        (\a c -> { c | numBoids = a })
    , ConfigForm.float
        "boidRad"
        "Boid radius"
        .boidRad
        (\a c -> { c | boidRad = a })
    , ConfigForm.float
        "visionRange"
        "Vision range"
        .visionRange
        (\a c -> { c | visionRange = a })
    , ConfigForm.bool
        "showRanges"
        "Show Ranges"
        .showRanges
        (\a c -> { c | showRanges = a })
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
    , ConfigForm.float
        "cohesionFactor"
        "Factor"
        .cohesionFactor
        (\a c -> { c | cohesionFactor = a })
    , ConfigForm.section
        "Rule 2: Alignment"
    , ConfigForm.float
        "alignmentFactor"
        "Factor"
        .alignmentFactor
        (\a c -> { c | alignmentFactor = a })
    , ConfigForm.section
        "Rule 3: Separation"
    , ConfigForm.float
        "separationFactor"
        "Factor"
        .separationFactor
        (\a c -> { c | separationFactor = a })
    , ConfigForm.float
        "separationRangeFactor"
        "Personal space factor"
        .separationRangeFactor
        (\a c -> { c | separationRangeFactor = a })
    , ConfigForm.section
        "Rule 4: Mouse"
    , ConfigForm.float
        "mouseFactor"
        "Factor"
        .mouseFactor
        (\a c -> { c | mouseFactor = a })
    , ConfigForm.float
        "mouseExponent"
        "Exponent"
        .mouseExponent
        (\a c -> { c | mouseExponent = a })
    , ConfigForm.section
        "Boid Visuals"
    , ConfigForm.bool
        "showVels"
        "Show vel arrows"
        .showVels
        (\a c -> { c | showVels = a })
    , ConfigForm.float
        "arrowScale"
        "Arrow scale"
        .arrowScale
        (\a c -> { c | arrowScale = a })
    , ConfigForm.color
        "skyColor"
        "Sky color"
        .skyColor
        (\a c -> { c | skyColor = a })
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
