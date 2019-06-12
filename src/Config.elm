-- GENERATED CODE, DO NOT EDIT BY HAND!


module Config exposing (Config, empty, logics)

import Color exposing (Color)
import Egg.ConfigForm as ConfigForm


type alias Config =
    { headerFontSize : Int
    , headerString : String
    , subheaderFontSize : Int
    , subheaderString : String
    , subheaderColor : Color
    , subheaderPadding : Int
    , configTableBgColor : Color
    , configTableSpacing : Int
    , configTablePadding : Int
    , configTableBorderWidth : Int
    , configTableBorderColor : Color
    , configLabelHighlightBgColor : Color
    , configFontSize : Int
    , configInputHeight : Int
    }


empty : ConfigForm.Defaults -> Config
empty defaults =
    { headerFontSize = defaults.int
    , headerString = defaults.string
    , subheaderFontSize = defaults.int
    , subheaderString = defaults.string
    , subheaderColor = defaults.color
    , subheaderPadding = defaults.int
    , configTableBgColor = defaults.color
    , configTableSpacing = defaults.int
    , configTablePadding = defaults.int
    , configTableBorderWidth = defaults.int
    , configTableBorderColor = defaults.color
    , configLabelHighlightBgColor = defaults.color
    , configFontSize = defaults.int
    , configInputHeight = defaults.int
    }


logics : List (ConfigForm.Logic Config)
logics =
    [ ConfigForm.int
        "headerFontSize"
        "Header font size"
        .headerFontSize
        (\a c -> { c | headerFontSize = a })
    , ConfigForm.string
        "headerString"
        "Header string"
        .headerString
        (\a c -> { c | headerString = a })
    , ConfigForm.int
        "subheaderFontSize"
        "Subheader font size"
        .subheaderFontSize
        (\a c -> { c | subheaderFontSize = a })
    , ConfigForm.string
        "subheaderString"
        "Subheader string"
        .subheaderString
        (\a c -> { c | subheaderString = a })
    , ConfigForm.color
        "subheaderColor"
        "Subheader color"
        .subheaderColor
        (\a c -> { c | subheaderColor = a })
    , ConfigForm.int
        "subheaderPadding"
        "Subheader padding"
        .subheaderPadding
        (\a c -> { c | subheaderPadding = a })
    , ConfigForm.color
        "configTableBgColor"
        "Config table BG color"
        .configTableBgColor
        (\a c -> { c | configTableBgColor = a })
    , ConfigForm.int
        "configTableSpacing"
        "Config table spacing"
        .configTableSpacing
        (\a c -> { c | configTableSpacing = a })
    , ConfigForm.int
        "configTablePadding"
        "Config table padding"
        .configTablePadding
        (\a c -> { c | configTablePadding = a })
    , ConfigForm.int
        "configTableBorderWidth"
        "Config table border width"
        .configTableBorderWidth
        (\a c -> { c | configTableBorderWidth = a })
    , ConfigForm.color
        "configTableBorderColor"
        "Config table border color"
        .configTableBorderColor
        (\a c -> { c | configTableBorderColor = a })
    , ConfigForm.color
        "configLabelHighlightBgColor"
        "Config table label highlight BG color"
        .configLabelHighlightBgColor
        (\a c -> { c | configLabelHighlightBgColor = a })
    , ConfigForm.int
        "configFontSize"
        "Config font size"
        .configFontSize
        (\a c -> { c | configFontSize = a })
    , ConfigForm.int
        "configInputHeight"
        "Config input height"
        .configInputHeight
        (\a c -> { c | configInputHeight = a })
    ]


--: ""
