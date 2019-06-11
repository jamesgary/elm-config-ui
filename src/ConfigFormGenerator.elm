module ConfigFormGenerator exposing (Kind(..), toFile)

import Dict exposing (Dict)


type Kind
    = IntKind
    | FloatKind
    | StringKind
    | ColorKind


toFile : List ( String, ( String, Kind ) ) -> String
toFile data =
    [ header
    , typeAlias data
    , empty data
    , logics data
    , "--"
    ]
        |> String.join "\n\n\n"


header : String
header =
    """
module Config exposing (Config, empty, logics)

import Color exposing (Color)
import ConfigForm
"""
        |> String.trim


typeAlias : List ( String, ( String, Kind ) ) -> String
typeAlias data =
    let
        pre =
            "type alias Config = "

        middle =
            data
                |> List.indexedMap
                    (\i ( label, ( field, kind ) ) ->
                        let
                            pre_ =
                                if i == 0 then
                                    "    { "

                                else
                                    "    , "
                        in
                        pre_ ++ field ++ " : " ++ kindToType kind
                    )
                |> String.join "\n"

        post =
            "    }"
    in
    [ pre
    , middle
    , post
    ]
        |> String.join "\n"


empty : List ( String, ( String, Kind ) ) -> String
empty data =
    let
        pre =
            """
empty : ConfigForm.Defaults -> Config
empty defaults =
"""
                |> String.trim

        middle =
            data
                |> List.indexedMap
                    (\i ( label, ( field, kind ) ) ->
                        let
                            pre_ =
                                if i == 0 then
                                    "    { "

                                else
                                    "    , "
                        in
                        pre_ ++ field ++ " = " ++ kindToDefault kind
                    )
                |> String.join "\n"

        post =
            "    }"
    in
    [ pre
    , middle
    , post
    ]
        |> String.join "\n"


logics : List ( String, ( String, Kind ) ) -> String
logics data =
    let
        pre =
            """
logics : List (ConfigForm.Logic Config)
logics =
"""
                |> String.trim

        middle =
            data
                |> List.indexedMap
                    (\i ( label, ( field, kind ) ) ->
                        let
                            pre_ =
                                if i == 0 then
                                    "    [ " ++ kindToLogic kind

                                else
                                    "    , " ++ kindToLogic kind

                            fieldLine =
                                "        \"" ++ field ++ "\""

                            labelLine =
                                "        \"" ++ label ++ "\""

                            getter =
                                "        ." ++ field

                            setter =
                                "        (\\a c -> { c | " ++ field ++ " = a })"
                        in
                        [ pre_
                        , fieldLine
                        , labelLine
                        , getter
                        , setter
                        ]
                            |> String.join "\n"
                    )
                |> String.join "\n"

        post =
            "    ]"
    in
    [ pre
    , middle
    , post
    ]
        |> String.join "\n"


kindToType : Kind -> String
kindToType kind =
    case kind of
        IntKind ->
            "Int"

        FloatKind ->
            "Float"

        StringKind ->
            "String"

        ColorKind ->
            "Color"


kindToDefault : Kind -> String
kindToDefault kind =
    case kind of
        IntKind ->
            "defaults.int"

        FloatKind ->
            "defaults.float"

        StringKind ->
            "defaults.string"

        ColorKind ->
            "defaults.color"


kindToLogic : Kind -> String
kindToLogic kind =
    case kind of
        IntKind ->
            "ConfigForm.int"

        FloatKind ->
            "ConfigForm.float"

        StringKind ->
            "ConfigForm.string"

        ColorKind ->
            "ConfigForm.color"
