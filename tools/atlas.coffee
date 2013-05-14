# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

vec = require './vec.coffee'
pq = require( './priority-queue.coffee' ).PriorityQueue
Set = require( './set.coffee' ).Set

build_atlas = (model) ->
  atlas = { charts: [], vertices : [] }

  edges = []

  for i,v of model.vertices
    edges[i] = {}
    atlas.vertices.push v

  for t in model.triangles
    v1 = model.vertices[ t[0] ]
    v2 = model.vertices[ t[1] ]
    v3 = model.vertices[ t[2] ]
    normal = vec.normalize( vec.cross( vec.minus( v2, v1 ), vec.minus( v3, v1 ) ) )
    p = vec.scale( vec.add( vec.add( v1, v2 ), v3 ), 1/3 )
    chart = {
      triangles : [ t ],
      perimiter : [ t[0], t[1], t[2] ],
      plane : {
        normal : normal,
        point : p,
        weight : 1
      },
      id : atlas.charts.length,
      could : new Set
    }
    atlas.charts.push chart

    for vpair in [ [ t[0], t[1] ], [ t[1], t[2] ], [ t[2], t[0] ] ]
      if ! edges[ vpair[0] ][ vpair[1] ]
        edges[ vpair[0] ][ vpair[1] ] = [] 
        edges[ vpair[1] ][ vpair[0] ] = [] 
      edges[ vpair[0] ][ vpair[1] ].push chart
      edges[ vpair[1] ][ vpair[0] ].push chart

  queue = new pq (a,b) -> a.cost - b.cost

  max_id = atlas.charts.length

  queue_index = {}

  skipped_joins = 0
  for v1 of edges
    for v2 of edges[v1]
      continue if v2 < v1

      charts = edges[v1][v2]

      if charts.length > 2
        skipped_joins++
        continue

      if charts.length < 2
        throw new Error "#{v1}-#{v2} has #{charts.length} charts. WTF"

      cost = collapse_cost model.vertices, charts[0], charts[1]

      smaller_id = Math.min charts[0].id, charts[1].id
      larger_id = Math.max charts[0].id, charts[1].id

      id = larger_id * max_id + smaller_id
      if queue_index[id]?
        continue

      could = new Set charts[0].id, charts[1].id

      charts[0].could = charts[0].could.union could
      charts[1].could = charts[1].could.union could

      item = { cost : cost, a : charts[0], b : charts[1], id : id }
      queue.push item

      queue_index[item.id] = item

  console.log "Skipped #{skipped_joins}/#{queue.size()} edges with > 2 charts"

  while next = queue.pop()
    break if next.cost > 100

    delete queue_index[ next.id ]

    console.log "cost=#{next.cost}"

    a = next.a
    b = next.b

    console.log a.could.list()
    console.log b.could.list()

    start_could = a.could.union( b.could ).minus( new Set a.id, b.id )

    collapsed = collapse_charts atlas, a, b

    console.log "perimiter_size=#{collapsed.perimiter.length}"

    collapsed.id = a.id
    delete a[x] for x of a
    a[x] = collapsed[x] for x of collapsed 

    still_can = a.could
    now_cant = start_could.minus still_can

    update_hist = {}
    update_hist[ next.id ] = true
    for m1 in start_could.list()
      for m2 in start_could.list()
        continue if m1 == m2

        smaller_id = Math.min m1, m2
        larger_id = Math.max m1, m2

        id = larger_id * max_id + smaller_id
        continue if update_hist[id]

        update_hist[id] = true

        console.log "looking for #{smaller_id},#{larger_id}"

        find = queue_index[id]

        if ! find?
          throw new Error "can't find #{id} in queue_index"

        if still_can.contains m1 && still_can.contains m2
          console.log "invalidate"
          find.cost = collapse.cost atlas.vertices, atlas.charts[m1], atlas.charts[m2]
          queue.invalidateItem find
        else
          console.log "remove #{a.id},#{b.id} => #{m1},#{m2}"
          queue.removeItem find

  return atlas

collapse_charts = (atlas,a,b) ->
  collapsed = {}
  collapsed.triangles = a.triangles.concat b.triangles
  collapsed.plane = combine_planes a.plane, b.plane
  collapsed.perimiter = combine_perimiters a.perimiter, b.perimiter
  collapsed.could = a.could.union( b.could ).minus( new Set a.id, b.id )

  return collapsed

combine_planes = (a,b) ->
  asize = a.weight
  bsize = a.weight
  new_normal = vec.add(
    vec.scale( a.normal, asize ),
    vec.scale( b.normal, bsize )
  )
  if vec.size( new_normal ) < 0.001
    new_normal = if asize > bsize then a.normal else b.normal
  else
    new_normal = vec.normalize new_normal
  new_point = vec.scale(
    vec.add(
      vec.scale( a.point, asize ),
      vec.scale( b.point, bsize )
    ),
    1 / (asize + bsize)
  )
  return { normal : new_normal, point : new_point, weight : asize + bsize }

combine_perimiters = (a,b) ->
  hist = {}
  for i,v of b
    hist[v] = parseInt i

  found = false

  overlaps = []

  b_dir = 0

  for i,v of a
    i = parseInt i
    if hist[v]?
      # for some reason push [ i, i ] is storing strings?
      if overlaps.length > 0 && overlaps[overlaps.length - 1][1] == (i - 1)
        if b_dir == 0
          if ((hist[v] + b.length - 1) % b.length) == overlaps[overlaps.length - 1][3]
            b_dir = +1
          else if ((hist[v] + 1) % b.length) == overlaps[overlaps.length - 1][3]
            b_dir = -1
          else
            throw new Error "non-consecutive overlap #{hist[v]} #{overlaps[overlaps.length-1][3]}"
        else
          if (hist[v] + b.length - b_dir) % b.length != overlaps[overlaps.length - 1][3]
            throw new Error "overlap changed directions!"
  
        overlaps[overlaps.length - 1][1] = i
        overlaps[overlaps.length - 1][3] = hist[v]
      else
        overlaps.push [ i, i, hist[v], hist[v] ]

  if ! overlaps.length
    throw new Error "no overlap. WTF"

  if overlaps.length == 2 && overlaps[0][0] == 0 && overlaps[1][1] == a.length - 1
    # wrap-around
    if b_dir == 0
      if ((overlaps[0][2] + b.length - 1) % b.length) == overlaps[1][2]
        b_dir = +1
      else if ((overlaps[0][2] + 1) % b.length) == overlaps[1][2]
        b_dir = -1

    overlaps[0][0] = overlaps[1][0]
    overlaps[0][2] = overlaps[1][2]
    overlaps.pop()

  if overlaps.length > 1
    throw new Error "multiple disjoint overlaps"

  if overlaps[0][0] == overlaps[0][1]
    throw new Error "single point overlap"

  if b_dir == 0
    throw new Error "couldn't determine overlap order?"

  join_start_a = overlaps[0][0]
  join_end_a = overlaps[0][1]
  join_start_b = overlaps[0][2]
  join_end_b = overlaps[0][3]

  if join_start_a == 0 && join_end_a == a.length - 1
    # full overlap, but b could be bigger
    return b

  if b_dir < 0
    [ join_end_b, join_start_b ] = [ join_start_b, join_end_b ]

  if join_start_b == 0 && join_end_b == b.length - 1
    # full overlap, but a is larger
    return a

  a_part = []
  if join_start_a > join_end_a
    # wrap around
    a_part = ( a[i] for i in [ join_start_a .. join_end_a ] by -1 )
  else
    a_part = a_part.concat ( a[i] for i in [ join_end_a .. (a.length - 1) ] )
    a_part = a_part.concat ( a[i] for i in [ 0 .. join_start_a ] )

  b_part = []
  if join_start_b > join_end_b
    # wrap around
    if join_start_b > join_end_b + 1
      b_part = ( b[i] for i in [ (join_start_b - 1) .. (join_end_b + 1) ] by -1 )
  else
    if join_end_b < b.length - 1
      b_part = b_part.concat ( b[i] for i in [ (join_end_b + 1) .. (b.length - 1) ] )
    if join_start_b > 0
      b_part = b_part.concat ( b[i] for i in [ 0 .. (join_start_b - 1) ] )

  return a_part.concat b_part.reverse()

collapse_cost = (vertices, a, b) ->
  new_plane = combine_planes a.plane, b.plane
  
  planarity = 0 # how co-planar is charta U chartb

  hist = {}
  for t in a.triangles.concat b.triangles
    for vi in t
      continue if hist[vi]?
      hist[vi] = true

      v = vertices[vi]
      dist = vec.dot( vec.minus( v, new_plane.point ), new_plane.normal )
      planarity += Math.abs dist

  compactness = 0 # how disk-like. perimiter ** 2

  hist = {}
  for i, vi of a.perimiter
    vi1 = vi
    vi2 = a.perimiter[ (i+1) % a.perimiter.length ]
    hist[vi1] = {} if ! hist[vi1]
    hist[vi2] = {} if ! hist[vi2]
    hist[vi1][vi2] = true
    hist[vi2][vi1] = true
    v1 = vertices[vi1]
    v2 = vertices[vi2]
    compactness += vec.size( vec.minus( v1, v2 ) )

  for i, vi of b.perimiter
    vi1 = vi
    vi2 = b.perimiter[ (i+1) % b.perimiter.length ]
    if hist[vi1]? and hist[vi1][vi2]
      continue

    v1 = vertices[vi1]
    v2 = vertices[vi2]
    compactness += vec.size( vec.minus( v1, v2 ) )

  return planarity + compactness

exports.build_atlas = build_atlas
exports._fortest = { combine_perimiters : combine_perimiters, combine_planes : combine_planes }
