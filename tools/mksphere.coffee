#!/usr/bin/env coffee
# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

long_slices = 10
lat_slices = 10

sphere = { name : "Sphere"; shininess : 20; vertices : []; normals : []; triangles : [] }

sphere.vertices = [ [ 0, -1, 0 ], [ 0, 1, 0 ] ] # Poles

south_pole_index = 0
north_pole_index = 1

vertices = []

vertices[0] = []
vertices[lat_slices] = []
for long in [ 0 .. long_slices ]
  vertices[0][long] = south_pole_index
  vertices[lat_slices][long] = north_pole_index

for lat in [ 1 .. (lat_slices - 1) ]
  phi = Math.PI * lat / lat_slices - Math.PI / 2
  vertices[lat] = []

  for long in [ 0 .. (long_slices - 1) ]
    theta = 2 * Math.PI * long / long_slices
    sphere.vertices.push [ Math.cos( theta ) * Math.cos( phi ), Math.sin( phi ), Math.sin( theta ) * Math.cos( phi ) ]
    vertices[lat][long] = sphere.vertices.length - 1 

  vertices[lat][long_slices] = vertices[lat][0]

for lat in [ 0 .. (lat_slices - 1) ]
  for long in [ 0 .. (long_slices - 1) ]
    sphere.triangles.push [ vertices[lat][long], vertices[lat][long+1], vertices[lat+1][long] ]
    sphere.triangles.push [ vertices[lat+1][long], vertices[lat][long+1], vertices[lat+1][long+1] ]

for v in sphere.vertices
  sphere.normals.push v

console.log JSON.stringify sphere, null, 2
