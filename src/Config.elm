module Config exposing (Config, decode, encode)


formList : List ( String, Val )
formList =
    [ ( "Foo font size", Float .fooFontSize (\a c -> { c | fooFontSize = a }) )
    , ( "Foo string", String .fooString (\a c -> { c | fooString = a }) )
    , ( "Bar font size", Float .barFontSize (\a c -> { c | barFontSize = a }) )
    , ( "Bar string", String .barString (\a c -> { c | barString = a }) )
    , ( "Bar color", Color .barColor (\a c -> { c | barColor = a }) )
    , ( "Some num", Int .someNum (\a c -> { c | someNum = a }) )
    ]
