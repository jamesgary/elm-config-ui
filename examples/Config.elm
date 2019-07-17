-- GENERATED CODE, DO NOT EDIT BY HAND!


module Config exposing (Config, empty, logics)

import Color exposing (Color)
import ConfigForm as ConfigForm


type alias Config =
    { viewportWidth : Int
    , viewportHeight : Int
    , skyColor : Color
    , seed : Int
    , groundColor : Color
    , groundHeight : Int
    , cloudHeight : Float
    , cloudRad : Float
    , cloudCount : Int
    , growDist : Float
    , minDist : Float
    , maxDist : Float
    , cloudPointRad : Float
    , cloudPointColor : Color
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
    { viewportWidth = defaults.int
    , viewportHeight = defaults.int
    , skyColor = defaults.color
    , seed = defaults.int
    , groundColor = defaults.color
    , groundHeight = defaults.int
    , cloudHeight = defaults.float
    , cloudRad = defaults.float
    , cloudCount = defaults.int
    , growDist = defaults.float
    , minDist = defaults.float
    , maxDist = defaults.float
    , cloudPointRad = defaults.float
    , cloudPointColor = defaults.color
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
    , ConfigForm.color
        "skyColor"
        "Sky color"
        .skyColor
        (\a c -> { c | skyColor = a })
    , ConfigForm.int
        "seed"
        "Random Seed"
        .seed
        (\a c -> { c | seed = a })
    , ConfigForm.section
        "Ground"
    , ConfigForm.color
        "groundColor"
        "Ground color"
        .groundColor
        (\a c -> { c | groundColor = a })
    , ConfigForm.int
        "groundHeight"
        "Ground height (px)"
        .groundHeight
        (\a c -> { c | groundHeight = a })
    , ConfigForm.section
        "Tree logic"
    , ConfigForm.float
        "cloudHeight"
        "cloudHeight"
        .cloudHeight
        (\a c -> { c | cloudHeight = a })
    , ConfigForm.float
        "cloudRad"
        "cloudRad"
        .cloudRad
        (\a c -> { c | cloudRad = a })
    , ConfigForm.int
        "cloudCount"
        "cloudCount"
        .cloudCount
        (\a c -> { c | cloudCount = a })
    , ConfigForm.float
        "growDist"
        "growDist"
        .growDist
        (\a c -> { c | growDist = a })
    , ConfigForm.float
        "minDist"
        "minDist"
        .minDist
        (\a c -> { c | minDist = a })
    , ConfigForm.float
        "maxDist"
        "maxDist"
        .maxDist
        (\a c -> { c | maxDist = a })
    , ConfigForm.section
        "Tree visuals"
    , ConfigForm.float
        "cloudPointRad"
        "Cloud point radius"
        .cloudPointRad
        (\a c -> { c | cloudPointRad = a })
    , ConfigForm.color
        "cloudPointColor"
        "Cloud point color"
        .cloudPointColor
        (\a c -> { c | cloudPointColor = a })
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
