#!/usr/bin/env coffee
# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

fs = require 'fs'
ply = require './ply.coffee'

filename = process.argv[2]
name = filename.replace /\.[^\.]+$/, -> ''

die = (str) ->
  console.error str
  process.exit 1

fs.readFile filename, (err,data) ->
  die err if err

  parsed = null

  try
    parsed = ply.parseBuffer data
    json = ply_to_json name, parsed
    console.log JSON.stringify( json, null, 2 )
  catch err
    die err.stack

ply_to_json = (name, ply) ->
  json = { name : name, shininess : 0, vertices : [], normals : [], triangles : [] }

  for ply_v in ply.vertex
    json.vertices.push [ ply_v.x, ply_v.y, ply_v.z ]

  for ply_face in ply.face
    if ply_face.vertex_indices.length != 3
      throw new Error "non triangles not supported"

    json.triangles.push ply_face.vertex_indices

  return json

