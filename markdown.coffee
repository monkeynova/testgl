#!/usr/bin/env coffee
# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

fs = require 'fs'
ghm = require 'github-flavored-markdown'
filename = process.argv[2]

fs.readFile filename, (err,data) ->
  if err
    console.error err
    process.exit 1

  console.log ghm.parse data.toString( 'utf-8' )

