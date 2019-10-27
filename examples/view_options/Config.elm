-- GENERATED CODE, DO NOT EDIT BY HAND!


module Config exposing (Config, empty, logics)

import Color exposing (Color)
import ConfigForm as ConfigForm


type alias Config =
    { headerFontSize : Int
    , configBgColor : Color
    , configPaddingX : Int
    , configPaddingY : Int
    , configFontSize : Int
    , configRowSpacing : Int
    , configInputWidth : Int
    , configInputSpacing : Float
    , configLabelHighlightBgColor : Color
    , configSectionSpacing : Int
    }


empty : ConfigForm.Defaults -> Config
empty defaults =
    { headerFontSize = defaults.int
    , configBgColor = defaults.color
    , configPaddingX = defaults.int
    , configPaddingY = defaults.int
    , configFontSize = defaults.int
    , configRowSpacing = defaults.int
    , configInputWidth = defaults.int
    , configInputSpacing = defaults.float
    , configLabelHighlightBgColor = defaults.color
    , configSectionSpacing = defaults.int
    }


--logics : List (ConfigForm.Logic Config)
logics =
    [ ConfigForm.int
        "headerFontSize"
        "Header size"
        .headerFontSize
        (\a c -> { c | headerFontSize = a })
    , ConfigForm.section
        "Config wrapper"
    , ConfigForm.color
        "configBgColor"
        "Background color"
        .configBgColor
        (\a c -> { c | configBgColor = a })
    , ConfigForm.int
        "configPaddingX"
        "Padding X"
        .configPaddingX
        (\a c -> { c | configPaddingX = a })
    , ConfigForm.int
        "configPaddingY"
        "Padding Y"
        .configPaddingY
        (\a c -> { c | configPaddingY = a })
    , ConfigForm.section
        "Config view options"
    , ConfigForm.int
        "configFontSize"
        "Font Size"
        .configFontSize
        (\a c -> { c | configFontSize = a })
    , ConfigForm.int
        "configRowSpacing"
        "Row Spacing"
        .configRowSpacing
        (\a c -> { c | configRowSpacing = a })
    , ConfigForm.int
        "configInputWidth"
        "Input Width"
        .configInputWidth
        (\a c -> { c | configInputWidth = a })
    , ConfigForm.float
        "configInputSpacing"
        "Input Spacing"
        .configInputSpacing
        (\a c -> { c | configInputSpacing = a })
    , ConfigForm.color
        "configLabelHighlightBgColor"
        "Label Highlight Bg"
        .configLabelHighlightBgColor
        (\a c -> { c | configLabelHighlightBgColor = a })
    , ConfigForm.int
        "configSectionSpacing"
        "Section Spacing"
        .configSectionSpacing
        (\a c -> { c | configSectionSpacing = a })
    ]


--: ""
