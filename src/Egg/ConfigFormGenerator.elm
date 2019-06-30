module Egg.ConfigFormGenerator exposing (Kind(..), toFile)

import Dict exposing (Dict)


type Kind
    = IntKind String
    | FloatKind String
    | StringKind String
    | ColorKind String
    | SectionKind


foo =
    toFile [ ( "my section title", IntKind "mysectionkey" ) ]


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
                |> List.map Tuple.second
                |> List.filterMap typeAliasEntry
                |> List.indexedMap
                    (\i entry ->
                        let
                            pre_ =
                                if i == 0 then
                                    "    { "

                                else
                                    "    , "
                        in
                        pre_ ++ entry
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


typeAliasEntry : Kind -> Maybe String
typeAliasEntry kind =
    case ( kindToFieldName kind, kindToType kind ) of
        ( Just fieldName, Just type_ ) ->
            Just (fieldName ++ " : " ++ type_)

        _ ->
            Nothing


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
                |> List.map Tuple.second
                |> List.filterMap emptyEntry
                |> List.indexedMap
                    (\i entry ->
                        let
                            pre_ =
                                if i == 0 then
                                    "    { "

                                else
                                    "    , "
                        in
                        pre_ ++ entry
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


emptyEntry : Kind -> Maybe String
emptyEntry kind =
    case ( kindToFieldName kind, kindToDefault kind ) of
        ( Just fieldName, Just default ) ->
            Just (fieldName ++ " = " ++ default)

        _ ->
            Nothing


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

                            args =
                                kindToLogicArgs ( label, kind )
                                    |> List.map (\str -> "        " ++ str)
                        in
                        (pre_ :: args)
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


kindToType : Kind -> Maybe String
kindToType kind =
    case kind of
        IntKind _ ->
            Just "Int"

        FloatKind _ ->
            Just "Float"

        StringKind _ ->
            Just "String"

        ColorKind _ ->
            Just "Color"

        SectionKind ->
            Nothing


kindToDefault : Kind -> Maybe String
kindToDefault kind =
    case kind of
        IntKind _ ->
            Just "defaults.int"

        FloatKind _ ->
            Just "defaults.float"

        StringKind _ ->
            Just "defaults.string"

        ColorKind _ ->
            Just "defaults.color"

        SectionKind ->
            Nothing


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

        SectionKind ->
            "ConfigForm.section"


kindToLogicArgs : ( String, Kind ) -> List String
kindToLogicArgs ( label, kind ) =
    case kindToFieldName kind of
        Just fieldName ->
            -- need all args
            let
                fieldLine =
                    "\"" ++ fieldName ++ "\""

                labelLine =
                    "\"" ++ label ++ "\""

                getter =
                    "." ++ fieldName

                setter =
                    "(\\a c -> { c | " ++ fieldName ++ " = a })"
            in
            [ fieldLine
            , labelLine
            , getter
            , setter
            ]

        Nothing ->
            [ "\"" ++ label ++ "\""
            ]


kindToFieldName : Kind -> Maybe String
kindToFieldName kind =
    case kind of
        IntKind str ->
            Just str

        FloatKind str ->
            Just str

        StringKind str ->
            Just str

        ColorKind str ->
            Just str

        SectionKind ->
            Nothing
