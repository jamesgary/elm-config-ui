#!/bin/bash

elm-live src/Main.elm --dir=public/ --before-build=./bin/gen-config.sh -- --output=public/js/compiled/main.js
