all:
	elm-live src/Main.elm --dir=public/ -- --output=public/js/compiled/main.js
gen:
	elm make src/ConfigGenerator.elm --output tmp/tmp.js && node tmp/tmp.js > src/Config.elm
