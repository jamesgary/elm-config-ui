module ConfigSchema exposing (main)

import ConfigFormGenerator exposing (Kind(..))
import Html exposing (Html)


myConfigFields : List ( String, Kind )
myConfigFields =
    [ ( "Header Font Size", IntKind "headerFontSize" )
    , ( "Body Font Size", IntKind "bodyFontSize" )
    , ( "Background Color", ColorKind "bgColor" )
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
