module Tree exposing (Options, Tree, generator, step, toSvg)

import Color exposing (Color)
import Math.Vector2 as Vec2 exposing (Vec2)
import Random
import Svg exposing (Svg)
import Svg.Attributes


type alias Tree =
    { branches : Branch
    , cloudPoints : List Vec2
    }


type Branch
    = Branch BranchData


type alias BranchData =
    { pos : Vec2
    , dir : Float
    , children : List Branch
    }


type alias Options =
    { rootPos : Vec2
    , cloudCenter : Vec2
    , cloudRad : Float
    , cloudCount : Int
    , growDist : Float
    , minDist : Float
    , maxDist : Float
    }


type alias ViewOptions =
    { cloudPointRad : Float
    , cloudPointColor : Color
    }


generator : Options -> Random.Generator Tree
generator options =
    cloudPointsGenerator options
        |> Random.map
            (\cloudPoints ->
                { branches =
                    Branch
                        { pos = options.rootPos
                        , dir = pi / 2 -- up
                        , children = []
                        }
                , cloudPoints = cloudPoints
                }
            )


cloudPointsGenerator : Options -> Random.Generator (List Vec2)
cloudPointsGenerator options =
    Random.list options.cloudCount (cloudPointGenerator options)


cloudPointGenerator : Options -> Random.Generator Vec2
cloudPointGenerator options =
    let
        ( centerX, centerY ) =
            vec2ToTuple options.cloudCenter
    in
    Random.pair (Random.float 0 1) (Random.float 0 1)
        |> Random.map
            (\( rand1, rand2 ) ->
                let
                    theta =
                        rand1 * 2 * pi

                    r =
                        options.cloudRad * sqrt rand2
                in
                Vec2.vec2
                    (r * cos theta + centerX)
                    (r * sin theta + centerY)
            )


step : Tree -> Tree
step tree =
    tree


vec2ToTuple : Vec2 -> ( Float, Float )
vec2ToTuple v =
    v
        |> Vec2.toRecord
        |> (\{ x, y } ->
                ( x, y )
           )



-- view stuff


toSvg : ViewOptions -> Tree -> Svg msg
toSvg options tree =
    Svg.g []
        [ drawCloudPoints options tree
        ]


drawCloudPoints : ViewOptions -> Tree -> Svg msg
drawCloudPoints options tree =
    tree.cloudPoints
        |> List.map
            (\point ->
                Svg.circle
                    [ Svg.Attributes.cx <| pxFloat <| Vec2.getX point
                    , Svg.Attributes.cy <| pxFloat <| Vec2.getY point
                    , Svg.Attributes.r <| pxFloat <| options.cloudPointRad
                    , Svg.Attributes.fill (Color.toCssString options.cloudPointColor)
                    ]
                    []
            )
        |> Svg.g []


percFloat : Float -> String
percFloat val =
    String.fromFloat val ++ "%"


pxInt : Int -> String
pxInt val =
    String.fromInt val ++ "px"


pxFloat : Float -> String
pxFloat val =
    String.fromFloat val ++ "px"
