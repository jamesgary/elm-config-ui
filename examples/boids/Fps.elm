module Fps exposing (Fps, defaultConfig, init, tick, view)

import Array exposing (Array)
import Color
import Html exposing (Html)
import Html.Attributes
import Svg
import Svg.Attributes


type alias Fps =
    { columns : Array Int
    , framesPassed : Int
    , msPassed : Float
    , config : Config
    }


type alias Config =
    { numColumns : Int
    , columnWidth : Int
    , columnHeight : Int
    , columnsPerSecond : Float
    }


defaultConfig : Config
defaultConfig =
    { numColumns = 40
    , columnWidth = 3
    , columnHeight = 60
    , columnsPerSecond = 6
    }


init : Config -> Fps
init config =
    { columns = Array.empty
    , framesPassed = 0
    , msPassed = 0
    , config = config
    }


tick : Float -> Fps -> Fps
tick delta fps =
    let
        framesPassed =
            fps.framesPassed + 1

        msPassed =
            fps.msPassed + delta

        shouldRefresh =
            msPassed > (1000 / fps.config.columnsPerSecond)
    in
    if shouldRefresh then
        { fps
            | columns =
                fps.columns
                    |> Array.push framesPassed
                    |> trim fps.config

            --|> Debug.log "trimmed"
            , framesPassed = 0
            , msPassed = 0
        }

    else
        { fps
            | framesPassed = framesPassed
            , msPassed = msPassed
        }


trim : Config -> Array Int -> Array Int
trim config cols =
    if Array.length cols >= config.numColumns then
        cols
            |> Array.slice 1 config.numColumns

    else
        cols


view : Fps -> Html msg
view fps =
    let
        width =
            fps.config.numColumns
                * fps.config.columnWidth

        widthStr =
            width
                |> String.fromInt

        heightStr =
            fps.config.columnHeight
                |> String.fromInt
    in
    Svg.svg
        [ Svg.Attributes.width widthStr
        , Svg.Attributes.height heightStr
        , Svg.Attributes.viewBox (String.join " " [ "0 0", widthStr, heightStr ])
        , Html.Attributes.style "background" <| Color.toCssString <| Color.rgba 0 0.5 0.5 0.8
        ]
        [ Svg.g []
            (fps.columns
                |> Array.toList
                |> List.reverse
                |> List.indexedMap
                    (\i col ->
                        let
                            perf =
                                perfOfCol col fps.config.columnsPerSecond

                            --|> Debug.log "PERF"
                            height =
                                perf * toFloat fps.config.columnHeight
                        in
                        Svg.rect
                            [ Svg.Attributes.x <| String.fromInt <| width - i * fps.config.columnWidth
                            , Svg.Attributes.y <| String.fromFloat <| toFloat fps.config.columnHeight - height
                            , Svg.Attributes.width <| String.fromInt <| fps.config.columnWidth
                            , Svg.Attributes.height <| String.fromFloat <| height
                            , Svg.Attributes.fill <| colColorStr perf
                            ]
                            []
                    )
            )
        ]


perfOfCol : Int -> Float -> Float
perfOfCol numFrames columnsPerSecond =
    let
        fps =
            toFloat numFrames * columnsPerSecond / 1000

        optimalFps =
            60 / 1000
    in
    fps / optimalFps



--|> Debug.log "perf"


colColorStr : Float -> String
colColorStr perf =
    let
        color =
            if perf >= 0.99 then
                Color.rgb 0 1 0

            else if perf >= 0.9 then
                Color.rgb 0.8 1 0

            else if perf >= 0.5 then
                Color.rgb 1 0.9 0

            else
                Color.rgb 1 0 0
    in
    Color.toCssString color
