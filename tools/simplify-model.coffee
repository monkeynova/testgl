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

fs.readFile in_filename, (err,data) ->
  die err if err

  complex = JSON.parse data

  simple = simplify complex

  fs.writeFile out_filename, JSON.stringify( simple, null, 2 ), (err) ->
    die err if err

simplify = (complex) ->
  queue = new pq (a,b) ->
    return a.error - b.error

  vec2tri = []

  for tri in complex.triangles
    vec2tri[ tri[0] ] = tri
    vec2tri[ tri[2] ] = tri
    vec2tri[ tri[3] ] = tri

  return complex
