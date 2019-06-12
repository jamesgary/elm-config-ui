#!/bin/bash

elm-live src/Main.elm --dir=public/ -- --output=public/js/compiled/main.js &
chokidar "config/Data.elm" -c "elm make config/Data.elm --output tmp/gen-config.js > /dev/null && node tmp/gen-config.js > src/Config.elm 2>/dev/null" &

wait
