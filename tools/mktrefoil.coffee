#!/usr/bin/env coffee
# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

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

lat_slices = 40
long_slices = 5

cos = Math.cos
sin = Math.sin

knot = { name : "Trefoil"; shininess : 20; vertices : []; normals : []; triangles : [] }

for lat in [ 0 .. (lat_slices - 1) ]
  phi = 2 * Math.PI * lat / lat_slices

  lat_index = lat * long_slices
  lat_next_index = ((lat + 1) % lat_slices) * long_slices

  center = [ sin( phi ) + 2 * sin( 2 * phi ), -sin( 3 * phi ), cos(  phi ) - 2 * cos( 2 * phi ) ]
  center = scale center, 1/3
  d_phi = [ cos( phi ) + 4 * cos( 2 * phi ), - 3 * cos( 3 * phi ), -sin( phi ) + 4 * sin( 2 * phi ) ]
  d_phi = normalize d_phi

  d_x = null
  for test_v in [ [ 1, 0, 0 ], [ 0, 0, 1 ] ]
    if Math.abs( dot( d_phi, test_v ) ) > 0.01
      d_x = add( test_v, scale( d_phi, -dot( test_v, d_phi ) ) ) # test_v - (d_phi . test_v) d_phi
      d_x = normalize d_x
      break

  if ! d_x
    console.error "no good vector for " + d_phi

  d_y = normalize cross( d_phi, d_x )

  for long in [ 0 .. (long_slices - 1) ]
    theta = 2 * Math.PI * long / long_slices

    center_delta = add( scale( d_x, cos( theta ) ), scale( d_y, sin( theta ) ) )

    knot.vertices.push add center, scale( center_delta, 0.2 )
    knot.normals.push center_delta

    long_next = (long + 1) % long_slices

    knot.triangles.push [ lat_index + long, lat_next_index + long, lat_index + long_next ]
    knot.triangles.push [ lat_index + long_next, lat_next_index + long, lat_next_index + long_next ]

console.log JSON.stringify knot, null, 2
