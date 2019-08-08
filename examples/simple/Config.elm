-- GENERATED CODE, DO NOT EDIT BY HAND!


module Config exposing (Config, empty, logics)

import Color exposing (Color)
import ConfigForm as ConfigForm


type alias Config =
    { padding : Int
    , bgColor : Color
    , fontColor : Color
    , headerFontSize : Int
    , bodyFontSize : Int
    }


empty : ConfigForm.Defaults -> Config
empty defaults =
    { padding = defaults.int
    , bgColor = defaults.color
    , fontColor = defaults.color
    , headerFontSize = defaults.int
    , bodyFontSize = defaults.int
    }


logics : List (ConfigForm.Logic Config)
logics =
    [ ConfigForm.int
        "padding"
        "Padding"
        .padding
        (\a c -> { c | padding = a })
    , ConfigForm.color
        "bgColor"
        "Background color"
        .bgColor
        (\a c -> { c | bgColor = a })
    , ConfigForm.color
        "fontColor"
        "Font color"
        .fontColor
        (\a c -> { c | fontColor = a })
    , ConfigForm.int
        "headerFontSize"
        "Header Font Size"
        .headerFontSize
        (\a c -> { c | headerFontSize = a })
    , ConfigForm.int
        "bodyFontSize"
        "Body Font Size"
        .bodyFontSize
        (\a c -> { c | bodyFontSize = a })
    ]


--: ""
