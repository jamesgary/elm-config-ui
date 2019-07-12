-- GENERATED CODE, DO NOT EDIT BY HAND!


module Config exposing (Config, empty, logics)

import Color exposing (Color)
import ConfigForm as ConfigForm


type alias Config =
    { skyColor : Color
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
    { skyColor = defaults.color
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
    [ ConfigForm.color
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
