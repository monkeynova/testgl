#!/usr/bin/env coffee
# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

fs = require 'fs'
filename = process.argv[2]

if /\.jade$/.test filename
  re = /include\s+(.*)/
  htmlfile = filename.replace /\.jade$/, -> '.html'
  outfile = '$(OUT)/' + htmlfile
  commands = "\t@mkdir -p \$(@D)\n\tjade -p . < \$< > \$@.tmp\n\tmv \$@.tmp \$@\n" +
    'all: $(OUT)/' + htmlfile + "\n"
else if /\.coffee$/.test filename
  re = /\#=require <(.*?)>/
  jsfile = filename.replace /\.coffee$/, -> '.js'
  outfile = '$(GENERATED)/' + filename
  commands = "\t@mkdir -p \$(@D)\n\tcoffeescript-concat -I . -I .generated -o \$@.tmp \$<\n\tmv \$@.tmp \$@\n" +
    '$(OUT)/' + jsfile + ': $(GENERATED)/' + filename + "\n" +
    'all: $(OUT)/' + jsfile + "\n"
else
  process.stderr.write "don't know how to find dependencies in " + filename + "\n"
  process.exit 1

fs.readFile filename, (err,data) ->
  if err
    process.stderr.write err + "\n"
    process.exit 1

  build = outfile + ': ' + filename + ' $(GENERATED)/' + filename + '.d '

  for line in data.toString( 'utf-8' ).split "\n"
    match = re.exec line
    if match
      depfile = match[1]
      depfile = depfile.replace /.*\.dataurl\.coffee/, ($0) -> '$(GENERATED)/' + $0
      build += depfile + " "

  console.log build
  console.log commands
