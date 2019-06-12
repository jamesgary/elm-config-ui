#!/bin/bash

elm make src/ConfigGenerator.elm --output tmp/tmp.js && node tmp/tmp.js > src/Config.elm
