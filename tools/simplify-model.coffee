#!/usr/bin/env coffee
# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

die = (str) ->
  console.error str
  process.exit 1

fs = require 'fs'
vec = require './vec.coffee'
pq = require( './priority-queue.coffee' ).PriorityQueue

in_filename = process.argv[2]
out_filename = process.argv[3]
target_triangles = process.argv[4]

die "usage: simplify-model.coffee <infile> <outfile> <target triangle count>" if ! target_triangles

console.log "Loading..."
fs.readFile in_filename, (err,data) ->
  die err if err

  console.log "Parsing..."
  model = JSON.parse data

  console.log "Simplifying..."
  simplify model, target_triangles

  console.log "Writing..."
  fs.writeFile out_filename, JSON.stringify( model, null, 2 ), (err) ->
    die err if err

simplify = (model,target_triangles) ->
  queue = new pq (a,b) ->
    return a.error - b.error

  edges = []
  v2t = []

  console.log "  Prepping..."

  for v, i in model.vertices
    v2t[ i ] = []
    edges[ i ] = {}

  edge_id = 0

  for t, i in model.triangles
    v2t[ t[0] ].push i
    v2t[ t[1] ].push i
    v2t[ t[2] ].push i

    for v_pair in [ [ 0, 1 ], [ 0, 2 ], [ 1, 2 ] ]
      v1 = t[ v_pair[0] ]
      v2 = t[ v_pair[1] ]

      if ! edges[ v1 ][ v2 ]
        edge_item = { v1 : v1, v2 : v2, id : edge_id++ }
        compute_removal_error model, edge_item
        edges[ v1 ][ v2 ] = edge_item
        edges[ v2 ][ v1 ] = edge_item
        queue.push edge_item

  triangle_count = model.triangles.length

  process.stdout.write "  Removing edges...#{triangle_count}/#{target_triangles}\r"

  while triangle_count > target_triangles
    process.stdout.write "  Removing edges...#{triangle_count}/#{target_triangles}           \r" if triangle_count % 277 == 0
    triangle_count -= collapse_next_edge model, queue, edges, v2t

  console.log "  Removing edges...done                     "

  console.log "  Removing vertices/triangles..."

  vertex_map = []
  newvertices = []
  for i, v of model.vertices
    if v?
      vertex_map[ i ] = newvertices.length
      newvertices.push v

  model.vertices = newvertices

  newtriangles = []
  for i, t of model.triangles
    if t?
      for j in [ 0 .. 2 ]
        new_vertex = vertex_map[ t[j] ]
        if new_vertex?
          t[j] = vertex_map[ t[j] ]
        else
          console.log "no mapping for #{t[j]}"

      newtriangles.push t

  model.triangles = newtriangles

compute_removal_error = (model,edge_item) ->
  edge_item.error = vec.size( vec.minus( model.vertices[ edge_item.v1 ], model.vertices[ edge_item.v2 ] ) )

collapse_next_edge = (model,queue,edges,v2t) ->
  next_edge = queue.pop()

  if ! next_edge
    console.error "ran out of edges. wtf?"
    return

  v1 = next_edge.v1
  v2 = next_edge.v2

  if next_edge.error > queue.peek().error
    console.error "removing edge #{v1}-#{v2} #{next_edge.error}>#{queue.peek().error}"

  # update vertices
  # replace v1 with 0.5 * (v1 + v2)
  # remove v2
  model.vertices[ v1 ] = vec.scale( vec.add( model.vertices[ v1 ], model.vertices[ v2 ] ), 0.5 )
  model.vertices[ v2 ] = null

  # update edges
  delete edges[ v1 ][ v2 ]
  delete edges[ v2 ][ v1 ]

  for vother of edges[ v2 ]
    edge_item = edges[ v2 ][ vother ]
    #console.log "updating #{vother} w.r.t #{v1}-#{v2}"
    #console.log edge_item

    delete edges[ vother ][ v2 ]
    delete edges[ v2 ][ vother ]

    if edges[ v1 ][ vother ]
      # collapsing onto an existing edge
      queue.removeItem edge_item
      #console.log "removed"
    else
      if edge_item.v1 == v2
        edge_item.v1 = v1
      else if edge_item.v2 == v2
        edge_item.v2 = v1
      else
        console.error "WTF! edge doesn't contain point"

      #console.log edge_item

      compute_removal_error model, edge_item
      queue.invalidateItem edge_item

      edges[ v1 ][ vother ] = edge_item
      edges[ vother ][ v1 ] = edge_item

  # update triangles
  hist = {}
  for ti in v2t[ v1 ].concat v2t[ v2 ]
    continue if ! model.triangles[ ti ]
    hist[ ti ] = 0 if ! hist[ ti ] 
    hist[ ti ]++

  #console.log hist

  triangles_removed = 0

  new_triangles = []
  for ti of hist
    if hist[ ti ] == 2
      #console.log "remove #{ti}"
      # triangle contains edge. we're collapsing
      # this triangle out of existence
      model.triangles[ ti ] = null
      triangles_removed++
    else
      #console.log "update #{ti}"
      # triangle contains one of the points update
      # to new one
      triangle = model.triangles[ ti ]
      new_triangles.push ti
      for v in [ 0 .. 2 ]
        if triangle[v] == v2
          triangle[v] = v1

  v2t[ v1 ] = new_triangles

  return triangles_removed
