#!/usr/bin/env coffee
# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

die = (str) ->
  console.error str
  process.exit 1

fs = require 'fs'
build_atlas = require( './atlas.coffee' ).build_atlas

in_filename = process.argv[2]
out_filename = process.argv[3]

die "usage: #{process.argv[0]} <infile> <outfile>" if ! out_filename

console.log "Loading..."
fs.readFile in_filename, (err,data) ->
  die err if err

  console.log "Parsing..."
  model = JSON.parse data

  console.log "Building Atlas..."
  atlas = build_atlas model

  console.log "Atlas is built from #{atlas.charts.length} charts"

  console.log "Writing..."
  fs.writeFile out_filename, JSON.stringify( atlas, null, 2 ), (err) ->
    die err if err
