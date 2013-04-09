#!/usr/bin/env coffee
# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

fs = require 'fs'
varname = process.argv[2]
filename = process.argv[3]
mime = 'image/png'

fs.readFile filename, (err,data) ->
  if err
    return console.log( err );

  dataurl = varname + ' = \'data:' + mime + ';base64,'
  dataurl += data.toString( 'base64' )
  dataurl += '\''

  console.log dataurl

