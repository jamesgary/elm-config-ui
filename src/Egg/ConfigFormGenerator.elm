module Egg.ConfigFormGenerator exposing (Kind(..), toFile)

import Dict exposing (Dict)


type Kind
    = IntKind String
    | FloatKind String
    | StringKind String
    | ColorKind String


foo =
    toFile [ ( "my label", IntKind "mylabelkey" ) ]


toFile : List ( String, Kind ) -> String
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
-- GENERATED CODE, DO NOT EDIT BY HAND!


module Config exposing (Config, empty, logics)

import Color exposing (Color)
import Egg.ConfigForm as ConfigForm
"""
        |> String.trim


typeAlias : List ( String, Kind ) -> String
typeAlias data =
    let
        pre =
            "type alias Config ="

        middle =
            data
                |> List.indexedMap
                    (\i ( label, kind ) ->
                        let
                            pre_ =
                                if i == 0 then
                                    "    { "

                                else
                                    "    , "

                            fieldName =
                                kindToFieldName kind
                        in
                        pre_ ++ fieldName ++ " : " ++ kindToType kind
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


empty : List ( String, Kind ) -> String
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
                    (\i ( label, kind ) ->
                        let
                            pre_ =
                                if i == 0 then
                                    "    { "

                                else
                                    "    , "

                            fieldName =
                                kindToFieldName kind
                        in
                        pre_ ++ fieldName ++ " = " ++ kindToDefault kind
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


logics : List ( String, Kind ) -> String
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
                    (\i ( label, kind ) ->
                        let
                            pre_ =
                                if i == 0 then
                                    "    [ " ++ kindToLogic kind

                                else
                                    "    , " ++ kindToLogic kind

                            fieldName =
                                kindToFieldName kind

                            fieldLine =
                                "        \"" ++ fieldName ++ "\""

                            labelLine =
                                "        \"" ++ label ++ "\""

                            getter =
                                "        ." ++ fieldName

                            setter =
                                "        (\\a c -> { c | " ++ fieldName ++ " = a })"
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
        IntKind _ ->
            "Int"

        FloatKind _ ->
            "Float"

        StringKind _ ->
            "String"

        ColorKind _ ->
            "Color"


kindToDefault : Kind -> String
kindToDefault kind =
    case kind of
        IntKind _ ->
            "defaults.int"

        FloatKind _ ->
            "defaults.float"

        StringKind _ ->
            "defaults.string"

        ColorKind _ ->
            "defaults.color"


kindToLogic : Kind -> String
kindToLogic kind =
    case kind of
        IntKind _ ->
            "ConfigForm.int"

        FloatKind _ ->
            "ConfigForm.float"

        StringKind _ ->
            "ConfigForm.string"

        ColorKind _ ->
            "ConfigForm.color"


kindToFieldName : Kind -> String
kindToFieldName kind =
    case kind of
        IntKind str ->
            str

        FloatKind str ->
            str

        StringKind str ->
            str

        ColorKind str ->
            str
