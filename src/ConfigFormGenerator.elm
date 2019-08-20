module ConfigFormGenerator exposing
    ( Kind(..)
    , toFile
    )

{-| Imagine being able to add a field to the config form with just one line! It can be done if you use code generation.

Use `ConfigFormGenerator` in your `ConfigSchema.elm` to make a `Config.elm` file (it can be excluded from your `src/` directory if you want, since it won't be compiled directly with your other elm files):

    -- ConfigSchema.elm


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

When compiled, it makes an elm app whose sole purpose is to `console.log` the elm code needed for a `Config.elm` file. To generate it, run something like this:

```shell
# Compile schema file to tmp js:
elm make ConfigSchema.elm --output=~/tmp/tmp.js > /dev/null

# Run compiled js with node, which logs out generated elm code, and save to Config.elm:
node ~/tmp/tmp.js > Config.elm 2>/dev/null
```


# How to automate with a watcher script

```shell
#!/bin/bash

CONFIG_SCHEMA_ELMFILE=ConfigSchema.elm
CONFIG_ELMFILE=Config.elm
TMP_JS=~/tmp/gen-config.js
MAIN_ELMFILE=Main.elm
SERVER_DIR=public/
MAIN_JS_OUTPUT=public/js/main.js

GENERATE_ARGS="$CONFIG_SCHEMA_ELMFILE $TMP_JS $CONFIG_ELMFILE"

# Command for generating Config.elm from ConfigSchema.elm
generate_config () {
  CONFIG_SCHEMA_ELMFILE=$1
  TMP_JS=$2
  CONFIG_ELMFILE=$3

  # Use `elm make` to make an elm app that console.logs the generated Config.elm code
  elm make $CONFIG_SCHEMA_ELMFILE --output=$TMP_JS > /dev/null && \
    # Run it with `node` to print the output and write to Config.elm
    node $TMP_JS > $CONFIG_ELMFILE 2>/dev/null
}
export -f generate_config

# Generate the config initially, just in case it doesn't exist
generate_config $GENERATE_ARGS

# Watch for config changes
chokidar $CONFIG_SCHEMA_ELMFILE --command "generate_config $GENERATE_ARGS" &

# Watch for elm changes
elm-live $MAIN_ELMFILE --dir=$SERVER_DIR -- --output=$MAIN_JS_OUTPUT &

wait
```

This will watch for changes to `ConfigSchema.elm` and generate a `Config.elm` file. Make sure you have the following installed, too:

```shell
# (use --save-dev instead of --global if you only need it locally for one project)
npm install --global elm elm-live@next chokidir
```

@docs Kind
@docs toFile

-}

import Dict exposing (Dict)


{-| Use these to define what kind of value your field is. For all values except `SectionKind`, the `String` is the field's camelCase variable name for both your `Config` record and its JSON representation, such as "headerFontSize".

`SectionKind` is just for visually organizing your fields.

-}
type Kind
    = IntKind String
    | FloatKind String
    | StringKind String
    | BoolKind String
    | ColorKind String
    | SectionKind


{-| Generates the elm code for your Config module given a list of labels and field kinds.
-}
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
import ConfigForm as ConfigForm
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
--logics : List (ConfigForm.Logic Config)
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

        BoolKind _ ->
            Just "Bool"

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

        BoolKind _ ->
            Just "defaults.bool"

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

        BoolKind _ ->
            "ConfigForm.bool"

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

        BoolKind str ->
            Just str

        ColorKind str ->
            Just str

        SectionKind ->
            Nothing
