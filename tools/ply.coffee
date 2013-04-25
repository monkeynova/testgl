# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

exports.parseBuffer = (buffer,cb) ->
  end_marker = "\nend_header\n"
  parts = buffer.toString( 'binary' ).split end_marker
  header_string = parts[0]

  if header_string.substr( 0, 4 ) != "ply\n"
    throw new Error "file doesn't start pny"

  if parts.length != 2
    throw new Error "can't find end_header"

  body_buffer = buffer.slice( header_string.length + end_marker.length )

  header_parsed = parse_header header_string

  body_parsed = parse_body header_parsed, body_buffer

  return body_parsed

parse_header = (header_string) ->
  header = { format : null, elements : [] }
  current_element = null

  for line in header_string.split "\n"
    words = line.split " "
    switch words[0]
      when "comment", "ply" then # ignore
      when "format"
        switch words[1]
          when "binary_big_endian", "binary_little_endian", "ascii"
            header.format = words[1]
          else
            throw new Error "unexpected format #{words[1]}"
        if words[2] != "1.0"
          throw new Error "unexpected version #{words[2]}"
      when "obj_info"
        header.obj_info = {} if ! header.obj_info
        header.obj_info[words[1]] = words[2..].join( " " )
      when "element"
        current_element = { name : words[1], count : words[2], properties : [] }
        header.elements.push current_element
      when "property"
        if words[1] == "list"
          current_element.properties.push { isList : true, size_type : words[2], type : words[3], name : words[4] }
        else
          current_element.properties.push { isList : false, type : words[1], name : words[2] }
      else
        console.error "unexpected command #{words[0]}"

  if ! header.format
    throw new Error "no format specified"

  if header.format != "binary_big_endian" && header.format != "ascii"
    throw new Error "format #{format} isn't supported"

  return header

parse_body = (header,body_buffer) ->
  reader = { offset: 0, buffer : body_buffer }

  if header.format == "binary_big_endian"
    return parse_body_binary_big_endian header, reader
  if header.format == "ascii"
    return parse_body_ascii header, reader

parse_body_ascii = (header,reader) ->
  words = reader.buffer.toString( 'utf-8' ).split /\s+/

  words.pop() # trailing '\n'

  body = {}

  for element in header.elements
    body[ element.name ] = [] if ! body[ element.name ]

    for i in [ 1 .. element.count ]
      cur_store = {}
      body[ element.name ].push cur_store

      for property in element.properties
        if property.isList
          size = words.shift()
          build = []
          for j in [ 1 .. size ]
            build.push words.shift()
          cur_store[ property.name ] = build  
        else
          cur_store[ property.name ] = words.shift()

  if words.length != 0
    throw new Error "buffer not fully consumed #{words.length} != 0"

  return body

parse_body_binary_big_endian = (header,reader) ->
  body = {}

  for element in header.elements
    body[ element.name ] = [] if ! body[ element.name ]

    for i in [ 1 .. element.count ]
      cur_store = {}
      body[ element.name ].push cur_store

      for property in element.properties
        if property.isList
          size = read_typeBE reader, property.size_type
          build = []
          for j in [ 1 .. size ]
            build.push read_typeBE reader, property.type
          cur_store[ property.name ] = build  
        else
          cur_store[ property.name ] = read_typeBE reader, property.type
  
  if reader.offset < reader.buffer.length
    throw new Error "buffer not fully consumed #{reader.offset} < #{reader.buffer.length}"

  return body

read_typeBE = (reader,type) ->
  val = 0
  size = 0
  switch type
    when "char"
      val = reader.buffer.readInt8( reader.offset )
      size = 1
    when "uchar"
      val = reader.buffer.readUInt8( reader.offset )
      size = 1
    when "short"
      val = reader.buffer.readInt16BE( reader.offset )
      size = 2
    when "ushort"
      val = reader.buffer.readUInt16BE( reader.offset )
      size = 2
    when "int"
      val = reader.buffer.readInt32BE( reader.offset )
      size = 4
    when "uint"
      val = reader.buffer.readUInt32BE( reader.offset )
      size = 4
    when "float"
      val = reader.buffer.readFloatBE( reader.offset )
      size = 4
    when "double"
      val = reader.buffer.readDoubleBE( reader.offset )
      size = 8

  reader.offset += size

  if reader.offset > reader.buffer.length
    throw new Error "read past end of buffer"

  return val
  
