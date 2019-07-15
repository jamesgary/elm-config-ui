-- GENERATED CODE, DO NOT EDIT BY HAND!


module Config exposing (Config, empty, logics)

import Color exposing (Color)
import ConfigForm as ConfigForm


type alias Config =
    { viewportWidth : Int
    , viewportHeight : Int
    , skyColor : Color
    , groundColor : Color
    , groundHeight : Int
    , treeColor : Color
    , treeTrunkWidth : Int
    , treeTrunkHeight : Int
    , numBranches : Int
    , branchAngleRangeDegs : Float
    , branchLengthPerc : Float
    , branchWidthPerc : Float
    , branchRecursions : Int
    , maxBranches : Int
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
    , groundColor = defaults.color
    , groundHeight = defaults.int
    , treeColor = defaults.color
    , treeTrunkWidth = defaults.int
    , treeTrunkHeight = defaults.int
    , numBranches = defaults.int
    , branchAngleRangeDegs = defaults.float
    , branchLengthPerc = defaults.float
    , branchWidthPerc = defaults.float
    , branchRecursions = defaults.int
    , maxBranches = defaults.int
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
        "Tree"
    , ConfigForm.color
        "treeColor"
        "Tree color"
        .treeColor
        (\a c -> { c | treeColor = a })
    , ConfigForm.int
        "treeTrunkWidth"
        "Tree trunk width"
        .treeTrunkWidth
        (\a c -> { c | treeTrunkWidth = a })
    , ConfigForm.int
        "treeTrunkHeight"
        "Tree trunk height"
        .treeTrunkHeight
        (\a c -> { c | treeTrunkHeight = a })
    , ConfigForm.section
        "Branches"
    , ConfigForm.int
        "numBranches"
        "# of branches"
        .numBranches
        (\a c -> { c | numBranches = a })
    , ConfigForm.float
        "branchAngleRangeDegs"
        "Branch angle range (deg)"
        .branchAngleRangeDegs
        (\a c -> { c | branchAngleRangeDegs = a })
    , ConfigForm.float
        "branchLengthPerc"
        "Branch length %"
        .branchLengthPerc
        (\a c -> { c | branchLengthPerc = a })
    , ConfigForm.float
        "branchWidthPerc"
        "Branch width %"
        .branchWidthPerc
        (\a c -> { c | branchWidthPerc = a })
    , ConfigForm.int
        "branchRecursions"
        "Branch recursions"
        .branchRecursions
        (\a c -> { c | branchRecursions = a })
    , ConfigForm.int
        "maxBranches"
        "Max branches (keep low!)"
        .maxBranches
        (\a c -> { c | maxBranches = a })
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
