module ConfigGenerator exposing (main)

import Html exposing (Html)


main : Html msg
main =
    let
        _ =
            Debug.log "oh ho ho." "ha ha"
    in
    Html.text ""



{-
   fooFontSize : CF.FloatField
   fooString : CF.StringField
   barFontSize : CF.FloatField
   barString : CF.StringField
   barColor : CF.ColorField
   configTableBgColor : CF.ColorField
   configTableSpacing : CF.IntField
   configTablePadding : CF.IntField
   configTableBorderWidth : CF.IntField
   configTableBorderColor : CF.ColorField
   configLabelHighlightBgColor : CF.ColorField







   traditional way:
   individual msgs, fields, encode, decoder, form fields
   not safe because:
   - may use a duplicate label, or mismatched json field

   smarter and still safe:
   one msg (Config -> Config)
   things that scale: record attributes, getters, setters, constructor, label, json field
   not safe because:
   - can still mistype json fields (duplicate)
   - still a lot of files to change

   hacky debug hack
   absolutely zero maintenance, except maybe purging old bad values
   not safe because:
   - your code has to run and use the new config variables, and will not remove old ones

   code generator
   very simple line
-}
