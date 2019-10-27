port module Main exposing (main)

import Array exposing (Array)
import Array.Extra
import Browser
import Browser.Events
import Color exposing (Color)
import Config exposing (Config)
import ConfigForm as ConfigForm exposing (ConfigForm)
import Dict exposing (Dict)
import Direction2d exposing (Direction2d)
import Game.TwoD
import Game.TwoD.Camera
import Game.TwoD.Render
import Html exposing (Html)
import Html.Attributes exposing (style)
import Html.Events
import Html.Events.Extra.Pointer as Pointer
import Json.Decode as JD
import Json.Decode.Pipeline as JDP
import Json.Encode as JE
import List.Extra
import Point2d exposing (Point2d)
import Random
import Random.Array
import Round
import Svg exposing (Svg)
import Svg.Attributes
import Vector2d exposing (Vector2d)


port sendToPort : JD.Value -> Cmd msg


main =
    Browser.element
        { init = init
        , view = view
        , update = updateResult
        , subscriptions = subscriptions
        }


type alias ModelResult =
    Result String Model


type alias Model =
    { config : Config
    , configForm : ConfigForm
    , boids : Array Boid
    , seed : Random.Seed
    , mousePos : Maybe Point2d
    , selectedBoidIndex : Maybe Int
    }


type alias Boid =
    { pos : Point2d
    , vel : Vector2d
    , velForCohesion : Vector2d
    , velForAlignment : Vector2d
    , velForSeparation : Vector2d
    , velForMouse : Vector2d
    , velForMomentum : Vector2d
    , color : Color
    }


type Msg
    = ConfigFormMsg (ConfigForm.Msg Config)
    | Tick Float
    | MouseMoved Point2d
    | MouseClicked Point2d
    | MouseLeft



-- FLAGS


type alias Flags =
    { elmConfigUiData : JE.Value
    , timestamp : Int
    }


decodeFlags : JD.Decoder Flags
decodeFlags =
    JD.succeed Flags
        |> JDP.required "elmConfigUiData" JD.value
        |> JDP.required "timestamp" JD.int



-- INIT


init : JE.Value -> ( ModelResult, Cmd Msg )
init jsonFlags =
    case JD.decodeValue decodeFlags jsonFlags of
        Ok flags ->
            let
                ( config, configForm ) =
                    ConfigForm.init
                        { flags = flags.elmConfigUiData
                        , logics = Config.logics
                        , emptyConfig =
                            Config.empty
                                { int = 1
                                , float = 1
                                , string = "SORRY IM NEW HERE"
                                , bool = True
                                , color = Color.rgba 1 0 1 1 -- hot pink!
                                }
                        }

                ( boids, seed ) =
                    Random.step
                        (Random.Array.array config.numBoids (boidGenerator config))
                        (Random.initialSeed flags.timestamp)
            in
            ( Ok
                { config = config
                , configForm = configForm
                , boids = boids
                , seed = seed
                , mousePos = Nothing
                , selectedBoidIndex = Just 0
                }
            , Cmd.none
            )

        Err err ->
            ( Err (JD.errorToString err)
            , Cmd.none
            )


boidGenerator : Config -> Random.Generator Boid
boidGenerator config =
    Random.map4
        (\x y angle color ->
            { pos = Point2d.fromCoordinates ( x, y )
            , vel =
                ( config.maxSpeed, angle )
                    |> fromPolar
                    |> Vector2d.fromComponents
            , velForCohesion = Vector2d.zero
            , velForAlignment = Vector2d.zero
            , velForSeparation = Vector2d.zero
            , velForMouse = Vector2d.zero
            , velForMomentum = Vector2d.zero
            , color = color
            }
        )
        (Random.float 0 (toFloat config.viewportWidth))
        (Random.float 0 (toFloat config.viewportHeight))
        (Random.float 0 (2 * pi))
        colorGenerator


updateResult : Msg -> ModelResult -> ( ModelResult, Cmd Msg )
updateResult msg modelResult =
    case modelResult of
        Ok model ->
            update msg model
                |> Tuple.mapFirst Ok

        Err _ ->
            ( modelResult, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick deltaInMilliseconds ->
            ( { model
                | boids = moveBoids model deltaInMilliseconds
              }
            , Cmd.none
            )

        ConfigFormMsg configFormMsg ->
            let
                ( newConfig, newConfigForm ) =
                    ConfigForm.update
                        Config.logics
                        model.config
                        model.configForm
                        configFormMsg

                newModel =
                    { model
                        | config = newConfig
                        , configForm = newConfigForm
                    }
            in
            ( newModel
                |> updateBoidCount
            , Cmd.none
            )

        MouseMoved pos ->
            ( { model
                | mousePos =
                    pos
                        |> Point2d.coordinates
                        |> (\( x, y ) -> ( x, toFloat model.config.viewportHeight - y ))
                        |> Point2d.fromCoordinates
                        |> Just
              }
            , Cmd.none
            )

        MouseClicked pos ->
            ( { model
                | selectedBoidIndex =
                    getBoidAt pos model
              }
            , Cmd.none
            )

        MouseLeft ->
            ( { model | mousePos = Nothing }
            , Cmd.none
            )


updateBoidCount : Model -> Model
updateBoidCount model =
    let
        boidDiff =
            model.config.numBoids - Array.length model.boids
    in
    if boidDiff > 0 then
        -- add more
        let
            ( newBoids, seed ) =
                Random.step
                    (Random.Array.array boidDiff (boidGenerator model.config))
                    model.seed
        in
        { model
            | boids = Array.append model.boids newBoids
            , seed = seed
        }

    else if boidDiff < 0 then
        let
            ( decreasedBoids, newSelectedIndex ) =
                case model.selectedBoidIndex of
                    Just index ->
                        if index <= model.config.numBoids then
                            case Array.get index model.boids of
                                Just selectedBoid ->
                                    ( model.boids
                                        |> Array.slice 0 (model.config.numBoids - 1)
                                        |> Array.append (Array.fromList [ selectedBoid ])
                                    , Just 0
                                    )

                                Nothing ->
                                    ( model.boids
                                        |> Array.slice 0 model.config.numBoids
                                      -- should never happen, so reset selectedIndex
                                    , Nothing
                                    )

                        else
                            ( model.boids
                                |> Array.slice 0 model.config.numBoids
                            , Just index
                            )

                    Nothing ->
                        ( model.boids
                            |> Array.slice 0 model.config.numBoids
                        , Nothing
                        )
        in
        { model
            | boids = decreasedBoids
            , selectedBoidIndex = newSelectedIndex
        }

    else
        model


getBoidAt : Point2d -> Model -> Maybe Int
getBoidAt pos model =
    -- TODO torus
    model.boids
        |> Array.toIndexedList
        |> List.Extra.find
            (\( i, boid ) ->
                (boid.pos
                    |> Point2d.squaredDistanceFrom pos
                )
                    <= (model.config.boidRad ^ 2)
            )
        |> Maybe.map Tuple.first


getHoveredBoidIndex : Model -> Maybe Int
getHoveredBoidIndex model =
    -- TODO torus
    case model.mousePos of
        Just mousePos ->
            model.boids
                |> Array.toIndexedList
                |> List.Extra.find
                    (\( i, boid ) ->
                        (boid.pos
                            |> Point2d.squaredDistanceFrom mousePos
                        )
                            <= (model.config.boidRad ^ 2)
                    )
                |> Maybe.map Tuple.first

        Nothing ->
            Nothing


moveBoids : Model -> Float -> Array Boid
moveBoids model delta =
    model.boids
        |> mapOthers
            (moveBoid
                model.config
                model.mousePos
                delta
            )


mapOthers : (List a -> a -> b) -> Array a -> Array b
mapOthers func array =
    -- apply a func to an item and all OTHER items in the list
    array
        |> Array.indexedMap
            (\i val ->
                let
                    otherVals =
                        array
                            |> Array.Extra.removeAt i
                            |> Array.toList
                in
                func otherVals val
            )


moveBoid : Config -> Maybe Point2d -> Float -> List Boid -> Boid -> Boid
moveBoid config maybeMousePos delta otherBoids boid =
    let
        velFromRule : Point2d -> Float -> (List Boid -> Vector2d) -> Vector2d
        velFromRule pos range ruleFunc =
            boidsInRange
                ( toFloat config.viewportWidth
                , toFloat config.viewportHeight
                )
                range
                otherBoids
                pos
                |> ruleFunc

        -- cohesion (center of mass)
        velForCohesion =
            velFromRule
                boid.pos
                config.visionRange
                (\nearbyBoids ->
                    let
                        centerOfMass =
                            nearbyBoids
                                |> List.map .pos
                                |> Point2d.centroid
                    in
                    case centerOfMass of
                        Just center ->
                            center
                                |> Vector2d.from boid.pos
                                |> Vector2d.normalize
                                |> Vector2d.scaleBy
                                    (config.cohesionFactor
                                        / toFloat (List.length nearbyBoids)
                                    )

                        Nothing ->
                            Vector2d.zero
                )

        -- alignment
        velForAlignment =
            velFromRule
                boid.pos
                config.visionRange
                (\nearbyBoids ->
                    if List.isEmpty nearbyBoids then
                        Vector2d.zero

                    else
                        nearbyBoids
                            |> List.map .vel
                            |> List.foldl Vector2d.sum Vector2d.zero
                            |> Vector2d.scaleBy
                                (config.alignmentFactor
                                    / toFloat (List.length nearbyBoids)
                                )
                )

        -- separation
        velForSeparation =
            velFromRule
                boid.pos
                (personalSpaceRange config)
                (\nearbyBoids ->
                    -- OLD ALG
                    --let
                    --    centerOfMassOfTooCloseBoids =
                    --        nearbyBoids
                    --            |> List.map .pos
                    --            |> Point2d.centroid
                    --in
                    --case centerOfMassOfTooCloseBoids of
                    --    Just center ->
                    --        center
                    --            |> Vector2d.from boid.pos
                    --            --|> Vector2d.normalize
                    --            |> Vector2d.scaleBy
                    --                (-config.separationFactor
                    --                    / toFloat (List.length nearbyBoids)
                    --                )
                    --    Nothing ->
                    --        Vector2d.zero
                    -- CLASSIC ALG
                    List.foldl
                        (\nearbyBoid tmpVec ->
                            let
                                dist =
                                    Vector2d.from nearbyBoid.pos boid.pos

                                scale =
                                    -- 1 to Inf
                                    -- 1 : furthest away
                                    -- Inf : right on top
                                    (personalSpaceRange config / Vector2d.length dist) ^ config.separationPower
                            in
                            --Vector2d.from nearbyBoid.pos boid.pos
                            dist
                                |> Vector2d.normalize
                                |> Vector2d.scaleBy scale
                                |> Vector2d.sum tmpVec
                        )
                        Vector2d.zero
                        nearbyBoids
                        |> Vector2d.scaleBy config.separationFactor
                )

        -- mouse
        velForMouse =
            case ( maybeMousePos, config.mouseFactor /= 0 ) of
                ( Just mousePos, True ) ->
                    let
                        distSq =
                            Point2d.squaredDistanceFrom boid.pos mousePos
                    in
                    if distSq <= config.visionRange ^ 2 then
                        boid.pos
                            |> Vector2d.from mousePos
                            |> Vector2d.normalize
                            --|> Vector2d.scaleBy (config.mouseFactor / logBase config.mouseLogBase (sqrt distSq / config.visionRange))
                            --|> Vector2d.scaleBy (-1 * config.mouseFactor ^ config.mouseExponent)
                            |> Vector2d.scaleBy (-1 * config.mouseFactor)

                    else
                        Vector2d.zero

                _ ->
                    Vector2d.zero

        -- momentum
        velForMomentum =
            boid.vel
                |> Vector2d.scaleBy config.momentumFactor

        -- wrap it all up
        allVels =
            [ velForCohesion
            , velForSeparation
            , velForAlignment
            , velForMouse
            , velForMomentum
            ]

        newVel =
            allVels
                |> List.foldl Vector2d.sum Vector2d.zero
                --|> Vector2d.scaleBy (1 / toFloat (List.length allVels))
                |> (\v ->
                        if Vector2d.length v > config.maxSpeed then
                            v
                                |> Vector2d.direction
                                |> Maybe.map Direction2d.toVector
                                |> Maybe.withDefault Vector2d.zero
                                |> Vector2d.scaleBy config.maxSpeed

                        else
                            v
                   )

        ( w, h ) =
            ( toFloat config.viewportWidth
            , toFloat config.viewportHeight
            )

        newPos =
            boid.pos
                |> Point2d.translateBy (Vector2d.scaleBy (delta / 1000) newVel)
                |> Point2d.coordinates
                |> (\( x, y ) ->
                        ( if x < 0 then
                            w - abs x

                          else if x > w then
                            x - w

                          else
                            x
                        , if y < 0 then
                            h - abs y

                          else if y > h then
                            y - h

                          else
                            y
                        )
                   )
                |> Point2d.fromCoordinates
    in
    { boid
        | pos = newPos
        , vel = newVel
        , velForCohesion = velForCohesion
        , velForAlignment = velForAlignment
        , velForSeparation = velForSeparation
        , velForMouse = velForMouse
        , velForMomentum = velForMomentum
    }


wrappedPoses : ( Float, Float ) -> Point2d -> List Point2d
wrappedPoses ( width, height ) pos =
    let
        ( x, y ) =
            pos
                |> Point2d.coordinates

        --wrapped values ought to sometimes be closer than original pos
        wrappedX =
            if x > (width / 2) then
                x - width

            else
                x + width

        wrappedY =
            if y > (height / 2) then
                y - height

            else
                y + height
    in
    [ pos
    , Point2d.fromCoordinates ( x, wrappedY )
    , Point2d.fromCoordinates ( wrappedX, y )
    , Point2d.fromCoordinates ( wrappedX, wrappedY )
    ]


boidsInRange : ( Float, Float ) -> Float -> List Boid -> Point2d -> List Boid
boidsInRange viewport range boids boidPos =
    boids
        |> List.filterMap
            (\otherBoid ->
                let
                    -- TODO perf
                    closestPos =
                        wrappedPoses viewport otherBoid.pos
                            |> List.Extra.minimumBy
                                (Point2d.squaredDistanceFrom boidPos)
                            |> Maybe.withDefault otherBoid.pos
                in
                if Point2d.squaredDistanceFrom boidPos closestPos <= range ^ 2 then
                    Just { otherBoid | pos = closestPos }

                else
                    Nothing
            )


vector2dToStr : Vector2d -> String
vector2dToStr v =
    v
        |> Vector2d.components
        |> (\( x, y ) ->
                [ "("
                , Round.round 2 x
                , " , "
                , Round.round 2 y
                , ")"
                ]
                    |> String.concat
           )


type ReceiveMsg
    = ConfigFormPortMsg JE.Value


fromPortDecoder : JD.Decoder ReceiveMsg
fromPortDecoder =
    JD.field "id" JD.string
        |> JD.andThen
            (\id ->
                case id of
                    "CONFIG" ->
                        JD.field "val" JD.value
                            |> JD.map ConfigFormPortMsg

                    str ->
                        JD.fail ("Bad id to receiveFromPort: " ++ str)
            )


view : ModelResult -> Html Msg
view modelResult =
    case modelResult of
        Ok model ->
            Html.div
                [ style "width" "100%"
                , style "height" "100%"
                , style "padding" "20px"
                , style "font-family" "sans-serif"
                , style "box-sizing" "border-box"
                ]
                [ viewBoidsWebGL model
                , viewConfig model
                ]

        Err err ->
            Html.text err


viewConfig : Model -> Html Msg
viewConfig ({ config } as model) =
    Html.div
        [ style "right" "20px"
        , style "top" "20px"
        , style "position" "absolute"
        , style "height" "calc(100% - 80px)"
        , style "font-size" "22px"
        ]
        [ Html.div
            [ style "padding" (pxInt config.configTablePadding)
            , style "overflow-y" "auto"
            , style "background" (Color.toCssString config.configTableBgColor)
            , style "border" ("1px solid " ++ Color.toCssString config.configTableBorderColor)
            , style "height" "100%"
            ]
            [ ConfigForm.view
                ConfigForm.viewOptions
                Config.logics
                model.configForm
                |> Html.map ConfigFormMsg
            , Html.textarea
                [ Html.Attributes.value
                    (ConfigForm.encode
                        model.configForm
                        |> JE.encode 2
                    )
                ]
                []
            ]
        ]


viewBoidsWebGL : Model -> Html Msg
viewBoidsWebGL model =
    let
        boidDiameter =
            2 * model.config.boidRad

        ( w, h ) =
            ( toFloat model.config.viewportWidth
            , toFloat model.config.viewportHeight
            )

        boidRenderables =
            model.boids
                |> Array.map (viewBoidWebGL model.config)
                |> Array.toList

        rangeRenderables =
            if model.config.showRanges then
                model.boids
                    |> Array.map (viewRangeWebGL model.config)
                    |> Array.toList

            else
                []
    in
    Game.TwoD.renderWithOptions
        [ style "width" (pxFloat w)
        , style "height" (pxFloat h)
        , style "background" (Color.toCssString model.config.skyColor)
        , style "border" "1px solid black"
        , Pointer.onMove (relativePos >> MouseMoved)
        , Pointer.onDown (relativePos >> MouseClicked)
        , Pointer.onLeave (\_ -> MouseLeft)
        ]
        { time = 0
        , size = ( round w, round h )
        , camera =
            Game.TwoD.Camera.fixedArea ((w - boidDiameter) * (h - boidDiameter)) ( w, h )
                |> Game.TwoD.Camera.moveTo ( w / 2, h / 2 )
        }
        (boidRenderables ++ rangeRenderables)


viewBoidWebGL : Config -> Boid -> Game.TwoD.Render.Renderable
viewBoidWebGL config boid =
    Game.TwoD.Render.shape
        Game.TwoD.Render.circle
        { color = boid.color
        , position = Point2d.coordinates boid.pos
        , size = ( config.boidRad, config.boidRad )
        }


viewRangeWebGL : Config -> Boid -> Game.TwoD.Render.Renderable
viewRangeWebGL config boid =
    let
        rad =
            config.visionRange
    in
    Game.TwoD.Render.shape
        Game.TwoD.Render.ring
        { color = boid.color
        , position =
            Point2d.coordinates boid.pos
                |> (\( x, y ) ->
                        ( x - rad + (config.boidRad / 2)
                        , y - rad + (config.boidRad / 2)
                        )
                   )
        , size = ( 2 * rad, 2 * rad )
        }


toOpacity : Color -> Float
toOpacity color =
    color
        |> Color.toRgba
        |> .alpha


toOpacityString : Color -> String
toOpacityString color =
    color
        |> Color.toRgba
        |> .alpha
        |> String.fromFloat


relativePos : Pointer.Event -> Point2d
relativePos event =
    event.pointer.offsetPos
        |> Point2d.fromCoordinates


personalSpaceRange : Config -> Float
personalSpaceRange config =
    config.boidRad * config.separationRangeFactor


percFloat : Float -> String
percFloat val =
    String.fromFloat val ++ "%"


pxInt : Int -> String
pxInt val =
    String.fromInt val ++ "px"


pxFloat : Float -> String
pxFloat val =
    String.fromFloat val ++ "px"


subscriptions : ModelResult -> Sub Msg
subscriptions modelResult =
    case modelResult of
        Ok model ->
            Sub.batch
                [ Browser.Events.onAnimationFrameDelta Tick
                ]

        Err _ ->
            Sub.none


colorGenerator : Random.Generator Color
colorGenerator =
    -- Colors from https://www.schemecolor.com/multi-color.php
    Random.uniform
        (Color.rgb255 235 102 98)
        [ Color.rgb255 247 177 114
        , Color.rgb255 247 211 126
        , Color.rgb255 130 200 129
        , Color.rgb255 29 143 148
        , Color.rgb255 32 61 133
        ]
