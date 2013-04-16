#!/usr/bin/env coffee
# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-
# 
add = (v1,v2) ->
  return [ v1[0] + v2[0], v1[1] + v2[1], v1[2] + v2[2] ]

dot = (v1, v2) ->
  return v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2]

scale = (v,s) ->
  return [ v[0] * s, v[1] * s, v[2] * s ]

normalize = (v) ->
  return scale v, 1 / Math.sqrt( dot v, v )

cross = (v1,v2) ->
  return [ v1[1] * v2[2] - v2[1] * v1[2], -(v1[0] * v2[2] - v1[2] * v2[0]), v1[0] * v2[1] - v1[1] * v2[0] ]

fs = require 'fs'
PNG = require( 'pngjs' ).PNG

filename = process.argv[2]

png = new PNG { filterType : 4 }
png.width = 64
png.height = 64
png.data = []

cos = Math.cos
sin = Math.sin

for y in [ 0 .. (png.height - 1) ]
  for x in [ 0 .. (png.width - 1) ]
    vec_coord = [ 2 * (x - png.width / 2) / png.width, 2 * (y - png.height / 2) / png.height, 0 ]
    r = Math.sqrt( dot vec_coord, vec_coord )
    normal = add [ 0, 0, 1 ], scale( vec_coord, sin( r * 2 * 2 * Math.PI ) )
    normal = normalize normal
    normal = scale( add( normal, [ 1, 1, 1 ] ), 0.5 )
    index = 4 * (y * png.width + x)
    png.data[ index + 0 ] = Math.round( normal[0] * 255 )
    png.data[ index + 1 ] = Math.round( normal[1] * 255 )
    png.data[ index + 2 ] = Math.round( normal[2] * 255 )
    png.data[ index + 3 ] = 255

png.pack().pipe( fs.createWriteStream( filename ) )
