-- GENERATED CODE, DO NOT EDIT BY HAND!


module Config exposing (Config, empty, logics)

import Color exposing (Color)
import ConfigForm as ConfigForm


type alias Config =
    { viewportWidth : Int
    , viewportHeight : Int
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
    , separationPower : Float
    , separationRangeFactor : Float
    , mouseFactor : Float
    , skyColor : Color
    , configTableBgColor : Color
    , configTableBorderWidth : Int
    , configTableBorderColor : Color
    , configTablePadding : Int
    }


empty : ConfigForm.Defaults -> Config
empty defaults =
    { viewportWidth = defaults.int
    , viewportHeight = defaults.int
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
    , separationPower = defaults.float
    , separationRangeFactor = defaults.float
    , mouseFactor = defaults.float
    , skyColor = defaults.color
    , configTableBgColor = defaults.color
    , configTableBorderWidth = defaults.int
    , configTableBorderColor = defaults.color
    , configTablePadding = defaults.int
    }


--logics : List (ConfigForm.Logic Config)
logics =
    [ ConfigForm.int
        "viewportWidth"
        "Viewport width (px)"
        .viewportWidth
        (\a c -> { c | viewportWidth = a })
    , ConfigForm.int
        "viewportHeight"
        "Viewport height (px)"
        .viewportHeight
        (\a c -> { c | viewportHeight = a })
    , ConfigForm.float
        "timeScale"
        "Time Scale"
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
        "separationPower"
        "Power"
        .separationPower
        (\a c -> { c | separationPower = a })
    , ConfigForm.float
        "separationRangeFactor"
        "Personal space"
        .separationRangeFactor
        (\a c -> { c | separationRangeFactor = a })
    , ConfigForm.section
        "Rule 4: Mouse"
    , ConfigForm.float
        "mouseFactor"
        "Factor"
        .mouseFactor
        (\a c -> { c | mouseFactor = a })
    , ConfigForm.section
        "Boid Visuals"
    , ConfigForm.color
        "skyColor"
        "Sky color"
        .skyColor
        (\a c -> { c | skyColor = a })
    , ConfigForm.section
        "Config container"
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
    ]


--: ""
