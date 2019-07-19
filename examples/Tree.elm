module Tree exposing (Options, Tree, generator, step, toSvg)

import Color exposing (Color)
import Dict exposing (Dict)
import List.Extra
import Math.Vector2 as Vec2 exposing (Vec2)
import Random
import Svg exposing (Svg)
import Svg.Attributes


type alias Tree =
    { branches : Dict Int Branch
    , cloudPoints : List Vec2
    , hasBranched : Bool
    , options : Options
    }


type alias Branch =
    -- TODO split type into done and in-process types
    { startPos : Vec2
    , endPos : Vec2
    , growDirs : List Vec2
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
    , treeColor : Color
    , branchThickness : Float
    }


generator : Options -> Random.Generator Tree
generator options =
    cloudPointsGenerator options
        |> Random.map
            (\cloudPoints ->
                { branches =
                    Dict.empty
                        |> idInsert
                            { startPos = options.rootPos
                            , endPos =
                                Vec2.vec2 0 -options.growDist
                                    |> Vec2.add options.rootPos
                            , growDirs = []
                            }
                , cloudPoints = cloudPoints
                , hasBranched = False
                , options = options
                }
            )


idInsert : v -> Dict Int v -> Dict Int v
idInsert v d =
    let
        id =
            Dict.size d + 1
    in
    Dict.insert id v d


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
    if List.isEmpty tree.cloudPoints then
        -- done!
        tree

    else if tree.hasBranched then
        -- in the middle of branching
        tryBranching tree
            |> Tuple.first

    else
        -- hasn't branched yet, may have to trunk
        let
            ( newTree, hasBranched ) =
                tryBranching tree
        in
        if hasBranched then
            newTree

        else
            growTrunk tree


growTrunk : Tree -> Tree
growTrunk tree =
    let
        highPoint branch =
            min (Vec2.getY branch.startPos)
                (Vec2.getY branch.endPos)

        highestBranch =
            tree.branches
                |> Dict.values
                |> List.sortBy highPoint
                |> List.head
    in
    case highestBranch of
        Just branch ->
            { tree
                | branches =
                    tree.branches
                        |> idInsert
                            -- assuming endPos is top
                            { startPos = branch.endPos
                            , endPos =
                                branch.endPos
                                    |> Vec2.add (Vec2.vec2 0 -tree.options.growDist)
                            , growDirs = []
                            }
            }

        Nothing ->
            tree


tryBranching : Tree -> ( Tree, Bool )
tryBranching tree =
    let
        ( remainingPoints, branchesWithDirs ) =
            tree.cloudPoints
                |> List.foldl
                    (\point ( pointsToKeep, branches ) ->
                        -- remove crowded points
                        -- add dirs to branches
                        let
                            maybeClosestBranch =
                                branches
                                    |> Dict.toList
                                    |> List.Extra.minimumBy
                                        (\( i, b ) ->
                                            b.endPos
                                                |> Vec2.distance point
                                        )
                        in
                        case maybeClosestBranch of
                            Just ( id, branch ) ->
                                let
                                    dist =
                                        Vec2.distance point branch.endPos

                                    dir =
                                        Vec2.direction point branch.endPos
                                in
                                if dist < tree.options.minDist then
                                    -- too close, throw away point
                                    ( pointsToKeep
                                    , branches
                                    )

                                else if dist < tree.options.maxDist then
                                    -- sweet spot, keep point and add dir
                                    ( point :: pointsToKeep
                                    , branches
                                        |> Dict.insert id
                                            { branch | growDirs = dir :: branch.growDirs }
                                    )

                                else
                                    -- too far, keep but ignore
                                    ( point :: pointsToKeep
                                    , branches
                                    )

                            Nothing ->
                                -- should never get here
                                ( pointsToKeep
                                , branches
                                )
                    )
                    ( [], tree.branches )

        newlyGrownBranches =
            branchesWithDirs
                |> Dict.values
                |> List.filterMap
                    (\branch ->
                        let
                            unnormalizedDir =
                                branch.growDirs
                                    |> List.map Vec2.normalize
                                    |> List.foldl Vec2.add (Vec2.vec2 0 0)
                        in
                        if unnormalizedDir == Vec2.vec2 0 0 then
                            Nothing

                        else
                            Just
                                { startPos = branch.endPos
                                , endPos =
                                    unnormalizedDir
                                        |> Vec2.normalize
                                        |> Vec2.scale tree.options.growDist
                                        |> Vec2.add branch.endPos
                                , growDirs = []
                                }
                    )
    in
    ( { tree
        | branches =
            newlyGrownBranches
                |> List.foldl
                    (\branch dict ->
                        idInsert branch dict
                    )
                    tree.branches
        , cloudPoints = remainingPoints
        , hasBranched = tree.hasBranched || (not <| List.isEmpty newlyGrownBranches)
      }
    , not <| List.isEmpty newlyGrownBranches
    )


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
        , drawBranches options tree
        ]


drawCloudPoints : ViewOptions -> Tree -> Svg msg
drawCloudPoints options tree =
    tree.cloudPoints
        |> List.map
            (\point ->
                [ Svg.circle
                    [ Svg.Attributes.cx <| pxFloat <| Vec2.getX point
                    , Svg.Attributes.cy <| pxFloat <| Vec2.getY point
                    , Svg.Attributes.r <| pxFloat <| options.cloudPointRad
                    , Svg.Attributes.fill (Color.toCssString options.cloudPointColor)
                    ]
                    []

                -- ranges
                , Svg.circle
                    [ Svg.Attributes.cx <| pxFloat <| Vec2.getX point
                    , Svg.Attributes.cy <| pxFloat <| Vec2.getY point
                    , Svg.Attributes.r <| pxFloat <| tree.options.minDist
                    , Svg.Attributes.fill "transparent"
                    , Svg.Attributes.stroke "#faa"
                    ]
                    []
                , Svg.circle
                    [ Svg.Attributes.cx <| pxFloat <| Vec2.getX point
                    , Svg.Attributes.cy <| pxFloat <| Vec2.getY point
                    , Svg.Attributes.r <| pxFloat <| tree.options.maxDist
                    , Svg.Attributes.fill "transparent"
                    , Svg.Attributes.stroke "#f33"
                    ]
                    []
                ]
            )
        |> List.concat
        |> Svg.g []


drawBranches : ViewOptions -> Tree -> Svg msg
drawBranches options tree =
    tree.branches
        |> Dict.values
        |> List.map
            (\branch ->
                let
                    ( x1, y1 ) =
                        vec2ToTuple branch.startPos

                    ( x2, y2 ) =
                        vec2ToTuple branch.endPos
                in
                Svg.line
                    [ Svg.Attributes.x1 <| pxFloat <| x1
                    , Svg.Attributes.y1 <| pxFloat <| y1
                    , Svg.Attributes.x2 <| pxFloat <| x2
                    , Svg.Attributes.y2 <| pxFloat <| y2
                    , Svg.Attributes.stroke (Color.toCssString options.treeColor)
                    , Svg.Attributes.strokeWidth <| pxFloat <| options.branchThickness
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
