#!/bin/bash

CONFIG_SCHEMA_ELMFILE=ConfigSchema.elm
CONFIG_ELMFILE=Config.elm
TMP_JS=~/tmp/gen-config.js
MAIN_ELMFILE=Main.elm
SERVER_DIR=public/
MAIN_JS_OUTPUT=public/main.js

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
#elm-live $MAIN_ELMFILE --dir=$SERVER_DIR -- --optimize --output=$MAIN_JS_OUTPUT &
elm-live $MAIN_ELMFILE --dir=$SERVER_DIR -- --output=$MAIN_JS_OUTPUT &

wait
