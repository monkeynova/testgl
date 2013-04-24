#!/usr/bin/env coffee
# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

lat_slices = 20
long_slices = 5

cos = Math.cos
sin = Math.sin

torus = { name : "Torus"; shininess : 20; vertices : []; normals : []; triangles : [] }

for lat in [ 0 .. (lat_slices - 1) ]
  phi = 2 * Math.PI * lat / lat_slices

  lat_index = lat * long_slices
  lat_next_index = ((lat + 1) % lat_slices) * long_slices

  for long in [ 0 .. (long_slices - 1) ]
    theta = 2 * Math.PI * long / long_slices
    torus.vertices.push [ (1 + 0.2 * cos( theta )) * cos( phi ),  0.2 * sin( theta ), (1 + 0.2 * cos( theta )) * sin( phi ) ]
    torus.normals.push [  cos( theta ) * cos( phi ),  sin( theta ), cos( theta ) * sin( phi ) ]

    long_next = (long + 1) % long_slices

    torus.triangles.push [ lat_index + long, lat_next_index + long, lat_index + long_next ]
    torus.triangles.push [ lat_index + long_next, lat_next_index + long, lat_next_index + long_next ]

console.log JSON.stringify torus, null, 2
