#!/usr/bin/env coffee
# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

fs = require 'fs'
varname = process.argv[2]
filename = process.argv[3]
if /\.png$/.test filename
  mime = 'image/png'
else if /\.js$/.test filename
  mime = 'application/javascript'
else
  console.error "Can't determine mime type"
  process.exit 1

fs.readFile filename, (err,data) ->
  if err
    console.error err
    process.exit 1

  dataurl = varname + ' = \'data:' + mime + ';base64,'
  dataurl += data.toString( 'base64' )
  dataurl += '\''

  console.log dataurl

