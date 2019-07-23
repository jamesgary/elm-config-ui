module Tree exposing (Options, Tree, generator, step, toSvg)

import Color exposing (Color)
import Dict exposing (Dict)
import Direction3d exposing (Direction3d)
import LineSegment2d exposing (LineSegment2d)
import LineSegment3d exposing (LineSegment3d)
import List.Extra
import Point2d exposing (Point2d)
import Point3d exposing (Point3d)
import Random
import SketchPlane3d exposing (SketchPlane3d)
import Svg exposing (Svg)
import Svg.Attributes
import Vector3d exposing (Vector3d)


type alias Tree =
    { branches : Dict Int Branch
    , cloudPoints : List Point3d
    , hasBranched : Bool
    , options : Options
    }


type alias Branch =
    -- TODO split type into done and in-process types
    { line : LineSegment3d
    , growDirs : List Direction3d
    }


type alias Options =
    { rootPos : Point3d
    , cloudCenter : Point3d
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
                            { line =
                                LineSegment3d.from
                                    options.rootPos
                                    (options.rootPos
                                        |> Point3d.translateIn
                                            Direction3d.positiveY
                                            options.growDist
                                    )
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


cloudPointsGenerator : Options -> Random.Generator (List Point3d)
cloudPointsGenerator options =
    Random.list options.cloudCount (cloudPointGenerator options)


cloudPointGenerator : Options -> Random.Generator Point3d
cloudPointGenerator options =
    let
        ( centerX, centerY, centerZ ) =
            options.cloudCenter
                |> Point3d.coordinates
    in
    Random.map3
        (\u v w ->
            let
                theta =
                    u * 2 * pi

                phi =
                    acos (2 * v - 1)

                r =
                    options.cloudRad * logBase 3 w

                sinTheta =
                    sin theta

                cosTheta =
                    cos theta

                sinPhi =
                    sin phi

                cosPhi =
                    cos phi

                x =
                    r * sinPhi * cosTheta

                y =
                    r * sinPhi * sinTheta

                z =
                    r * cosPhi
            in
            Point3d.fromCoordinates
                ( centerX + x
                , centerY + y
                , centerZ + z
                )
        )
        (Random.float 0 1)
        (Random.float 0 1)
        (Random.float 0 1)


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
            branch.line
                |> LineSegment3d.endPoint
                |> Point3d.yCoordinate

        highestBranch : Maybe Branch
        highestBranch =
            tree.branches
                |> Dict.values
                |> List.sortBy highPoint
                |> List.head
    in
    case highestBranch of
        Just branch ->
            let
                endPoint =
                    branch.line
                        |> LineSegment3d.endPoint
            in
            { tree
                | branches =
                    tree.branches
                        |> idInsert
                            -- assuming endPoint is top
                            { line =
                                LineSegment3d.from
                                    endPoint
                                    (endPoint
                                        |> Point3d.translateIn
                                            Direction3d.positiveY
                                            tree.options.growDist
                                    )
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
                            maybeClosestBranch : Maybe ( Int, Branch )
                            maybeClosestBranch =
                                branches
                                    |> Dict.toList
                                    |> List.Extra.minimumBy
                                        (\( id, branch ) ->
                                            branch.line
                                                |> LineSegment3d.endPoint
                                                |> Point3d.distanceFrom point
                                        )
                        in
                        case maybeClosestBranch of
                            Just ( id, branch ) ->
                                let
                                    dist =
                                        branch.line
                                            |> LineSegment3d.endPoint
                                            |> Point3d.distanceFrom point

                                    maybeDir : Maybe Direction3d
                                    maybeDir =
                                        branch.line
                                            |> LineSegment3d.endPoint
                                            |> Direction3d.from point
                                in
                                if dist < tree.options.minDist then
                                    -- too close, throw away point
                                    ( pointsToKeep
                                    , branches
                                    )

                                else
                                    case maybeDir of
                                        Just dir ->
                                            if dist < tree.options.maxDist then
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

                            Nothing ->
                                -- should never get here
                                ( pointsToKeep
                                , branches
                                )
                    )
                    ( [], tree.branches )

        newlyGrownBranches : List Branch
        newlyGrownBranches =
            branchesWithDirs
                |> Dict.values
                |> List.filterMap
                    (\branch ->
                        let
                            growthVec3d =
                                branch.growDirs
                                    |> List.map Direction3d.toVector
                                    |> List.foldl Vector3d.sum Vector3d.zero
                                    |> Vector3d.scaleBy (1 / toFloat (List.length branch.growDirs))
                                    -- ^ the average dir
                                    |> Vector3d.scaleBy tree.options.growDist

                            endPoint =
                                branch.line
                                    |> LineSegment3d.endPoint
                        in
                        if List.isEmpty branch.growDirs then
                            Nothing

                        else
                            Just
                                { line =
                                    LineSegment3d.from
                                        endPoint
                                        (endPoint
                                            |> Point3d.translateBy growthVec3d
                                        )
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



-- view stuff


toSvg : ViewOptions -> Tree -> Svg msg
toSvg options tree =
    Svg.g []
        [ drawCloudPoints options tree
        , drawBranches options tree
        ]


drawCloudPoints : ViewOptions -> Tree -> Svg msg
drawCloudPoints options tree =
    let
        points2d =
            tree.cloudPoints
                |> List.map (Point3d.projectInto SketchPlane3d.xy)
    in
    points2d
        |> List.map
            (\point ->
                [ Svg.circle
                    [ Svg.Attributes.cx <| pxFloat <| Point2d.xCoordinate point
                    , Svg.Attributes.cy <| pxFloat <| Point2d.yCoordinate point
                    , Svg.Attributes.r <| pxFloat <| options.cloudPointRad
                    , Svg.Attributes.fill (Color.toCssString options.cloudPointColor)
                    ]
                    []

                -- ranges
                --, Svg.circle
                --    [ Svg.Attributes.cx <| pxFloat <| Vec2.getX point
                --    , Svg.Attributes.cy <| pxFloat <| Vec2.getY point
                --    , Svg.Attributes.r <| pxFloat <| tree.options.minDist
                --    , Svg.Attributes.fill "transparent"
                --    , Svg.Attributes.stroke "#faa"
                --    ]
                --    []
                --, Svg.circle
                --    [ Svg.Attributes.cx <| pxFloat <| Vec2.getX point
                --    , Svg.Attributes.cy <| pxFloat <| Vec2.getY point
                --    , Svg.Attributes.r <| pxFloat <| tree.options.maxDist
                --    , Svg.Attributes.fill "transparent"
                --    , Svg.Attributes.stroke "#f33"
                --    ]
                --    []
                ]
            )
        |> List.concat
        |> Svg.g []


drawBranches : ViewOptions -> Tree -> Svg msg
drawBranches options tree =
    let
        lines2d =
            tree.branches
                |> Dict.values
                |> List.map .line
                |> List.map (LineSegment3d.projectInto SketchPlane3d.xy)
    in
    lines2d
        |> List.map
            (\line ->
                let
                    ( ( x1, y1 ), ( x2, y2 ) ) =
                        line
                            |> LineSegment2d.endpoints
                            |> Tuple.mapBoth Point2d.coordinates Point2d.coordinates
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
