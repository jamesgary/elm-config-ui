module Config exposing (Config, empty, logics)

import Color exposing (Color)
import ConfigForm


type alias Config =
    { headerFontSize : Int
    , headerString : String
    , subheaderFontSize : Int
    , subheaderString : String
    , subheaderColor : Color
    }


empty : ConfigForm.Defaults -> Config
empty defaults =
    { headerFontSize = defaults.int
    , headerString = defaults.string
    , subheaderFontSize = defaults.int
    , subheaderString = defaults.string
    , subheaderColor = defaults.color
    }



{- used for...
   encoding a config
   decoding a config
   viewing a config, with msgs that update a config
-}


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
    ]
