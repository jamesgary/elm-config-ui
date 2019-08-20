-- GENERATED CODE, DO NOT EDIT BY HAND!


module Config exposing (Config, empty, logics)

import Color exposing (Color)
import ConfigForm as ConfigForm


type alias Config =
    { headerFontSize : Int
    , bodyFontSize : Int
    , bgColor : Color
    }


empty : ConfigForm.Defaults -> Config
empty defaults =
    { headerFontSize = defaults.int
    , bodyFontSize = defaults.int
    , bgColor = defaults.color
    }


logics : List (ConfigForm.Logic Config)
logics =
    [ ConfigForm.int
        "headerFontSize"
        "Header Font Size"
        .headerFontSize
        (\a c -> { c | headerFontSize = a })
    , ConfigForm.int
        "bodyFontSize"
        "Body Font Size"
        .bodyFontSize
        (\a c -> { c | bodyFontSize = a })
    , ConfigForm.color
        "bgColor"
        "Background Color"
        .bgColor
        (\a c -> { c | bgColor = a })
    ]


--: ""
