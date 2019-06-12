#!/bin/bash

# Silently compiles and writes to src/Config.elm
# Only outputs error if there's a compilation error

elm make src/ConfigGenerator.elm --output tmp/gen-config.js > /dev/null
node tmp/gen-config.js > src/Config.elm 2>/dev/null
