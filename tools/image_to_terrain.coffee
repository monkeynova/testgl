#!/usr/bin/env coffee
# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

fs = require 'fs'
PNG = require( 'pngjs' ).PNG
vec = require './vec.coffee'

filename = process.argv[2]

white = [ 1, 1, 1, 1 ]
green = [ 0.25, 0.6, 0.04, 1 ]
brown = [ 0.30, -.20, 0.08, 1 ]

fs.readFile filename, (err,data) ->
  if err
    console.error err
    process.exit 1

  png = new PNG
  png.parse data, (err,data) ->
    if err
      console.error err
      process.exit 1

    width = png.width
    height = png.height

    heights = []

    for i in [ 0 .. width - 1 ]
      heights[i] = []
      for j in [ 0 .. height - 1 ]
        heights[i][j] = png.data[ 4 * (png.width * i + j) ] # Red component

    model = { name : "Terrain"; shininess : 0; vertices : []; colors : []; normals : []; triangles : [] }

    for i in [ 0 .. width - 1 ]
      for j in [ 0 .. height - 1 ]
        model.vertices.push [ i, heights[i][j], j ]

        prev_i = if i > 0 then i - 1 else i
        next_i = if i < width - 1 then i + 1 else i
        prev_j = if j > 0 then j - 1 else j
        next_j = if j < height - 1 then j + 1 else j

        vec_di = [ next_i - prev_i, heights[next_i][j] - heights[prev_i][j], 0 ]
        vec_dj = [ 0, heights[i][next_j] - heights[i][prev_j], -(next_j - prev_j) ]

        normal = vec.normalize vec.cross( vec_di, vec_dj )

        model.normals.push [ normal[0], normal[1], normal[2] ]

        if height > 10
          model.colors.push white
        else if height > 2
          model.colors.push brown
        else
          model.colors.push green

        if i < width - 1 && j < height - 1
          base = i * height + j
          model.triangles.push [ base, base + 1, base + height ]
          model.triangles.push [ base + height, base + 1, base + height + 1 ]

    console.log JSON.stringify model, null, 2
