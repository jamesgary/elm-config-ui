module ConfigSchema exposing (main)

import ConfigFormGenerator exposing (Kind(..))
import Html exposing (Html)


myConfigFields : List ( String, Kind )
myConfigFields =
    [ ( "Padding", IntKind "padding" )
    , ( "Background color", ColorKind "bgColor" )
    , ( "Font color", ColorKind "fontColor" )
    , ( "Header Font Size", IntKind "headerFontSize" )
    , ( "Body Font Size", IntKind "bodyFontSize" )
    ]


main : Html msg
main =
    let
        generatedElmCode =
            ConfigFormGenerator.toFile myConfigFields

        _ =
            Debug.log generatedElmCode ""
    in
    Html.text ""
