# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

getJSONMaybeDataURL = (model_url,fn) ->
  match = /^data:.*?;base64,(.*)/.exec model_url
  if match
    json_data = $.base64.decode( match[1] )
    fn( $.parseJSON( json_data ) )
  else
    $.getJSON model_url, (data) -> fn( data )


class Shape
  constructor: (gl,center) ->
    @center = center
    @initialized = true
    @shininess = 0
    @shouldDrawNormals = true

  position: (m) ->
    mat4.translate m, @center
    mat4.rotate m, @angle, @axis if @axis

  update: (elapsed) ->
    @angle += @angle_speed * elapsed

  animate: (rotations_per_second ,axis) ->
    @angle = 0
    @angle_speed = 2 * Math.PI * rotations_per_second
    @axis = axis

  flatten: (vec_array) -> $.map vec_array, (n) -> n

  buildBuffer: (gl,js) ->
    buffer = gl.createBuffer()
    buffer.itemSize = js[0].length
    buffer.numItems = js.length
    buffer.js = @flatten js
    gl.bindBuffer gl.ARRAY_BUFFER, buffer
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array( buffer.js ), gl.STATIC_DRAW

    return buffer

  buildElementBuffer: (gl,js) ->
    buffer = gl.createBuffer()
    buffer.itemSize = 1
    buffer.js = @flatten js
    buffer.numItems = buffer.js.length
    gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, buffer
    gl.bufferData gl.ELEMENT_ARRAY_BUFFER, new Uint16Array( buffer.js ), gl.STATIC_DRAW

    return buffer

  initTexture: (gl) ->
    gl.bindTexture gl.TEXTURE_2D, @texture
    gl.pixelStorei gl.UNPACK_FLIP_Y_WEBGL, true
    gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, @texture.image
    gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST
    gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST
    gl.bindTexture gl.TEXTURE_2D, null
    @texture.loaded = true

  drawSolid: (gl,pMatrix,mvMatrix,vertex_lighting_shader,pixel_lighting_shader) ->
    return if ! @initialized

    @position mvMatrix

    shader = null
    if @shininess != 0
      shader = pixel_lighting_shader
    else
      shader = vertex_lighting_shader

    gl.useProgram shader

    if @texture
      gl.uniform1i shader.uniforms["uUseTexture"], 1

      if @texture.loaded
        gl.activeTexture gl.TEXTURE0
        gl.bindTexture gl.TEXTURE_2D, @texture
        gl.uniform1i shader.uniforms["uSampler"], 0

    else
      gl.uniform1i shader.uniforms["uUseTexture"], 0

    gl.uniform1f shader.uniforms["uMaterialShininess"], @shininess

    if not @texture_coord
      @texture_coord = gl.createBuffer()
      gl.bindBuffer gl.ARRAY_BUFFER, @texture_coord
      @texture_coord.js = []
      @texture_coord.js.push( 0 ) for [ 1 .. 2 * @vertices.numItems ]
      gl.bufferData gl.ARRAY_BUFFER, new Float32Array( @texture_coord.js ), gl.STATIC_DRAW
      @texture_coord.itemSize = 2
      @texture_coord.numItems = @texture_coord.js.length / @texture_coord.itemSize
      
    gl.bindBuffer gl.ARRAY_BUFFER, @texture_coord
    gl.vertexAttribPointer shader.attributes["aTextureCoord"], @texture_coord.itemSize, gl.FLOAT, false, 0, 0

    gl.bindBuffer gl.ARRAY_BUFFER, @colors
    gl.vertexAttribPointer shader.attributes["aVertexColor"], @colors.itemSize, gl.FLOAT, false, 0, 0

    gl.bindBuffer gl.ARRAY_BUFFER, @vertices
    gl.vertexAttribPointer shader.attributes["aVertexPosition"], @vertices.itemSize, gl.FLOAT, false, 0, 0

    gl.bindBuffer gl.ARRAY_BUFFER, @normals
    gl.vertexAttribPointer shader.attributes["aVertexNormal"], @normals.itemSize, gl.FLOAT, false, 0, 0

    gl.uniformMatrix4fv shader.uniforms["uPMatrix"], false, pMatrix
    gl.uniformMatrix4fv shader.uniforms["uMVMatrix"], false, mvMatrix

    normalMatrix = mat3.create()
    mat4.toInverseMat3 mvMatrix, normalMatrix
    mat3.transpose normalMatrix

    gl.uniformMatrix3fv shader.uniforms["uNMatrix"], false, normalMatrix

    if @index
      gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, @index
      gl.drawElements @drawtype, @index.numItems, gl.UNSIGNED_SHORT, 0
    else
      gl.drawArrays @drawtype, 0, @vertices.numItems

  drawWire: (gl,pMatrix,mvMatrix,shader) ->
    return if ! @initialized

    @drawNormals gl, pMatrix, mvMatrix, shader if @shouldDrawNormals

  drawNormals: (gl,pMatrix,mvMatrix,shader) ->
      if ! @normal_points
        @normal_points = gl.createBuffer()
        @normal_points.js = []
        for i in [ 0 .. @vertices.numItems ]
          @normal_points.js.push @vertices.js[3*i]
          @normal_points.js.push @vertices.js[3*i+1]
          @normal_points.js.push @vertices.js[3*i+2]
          @normal_points.js.push @vertices.js[3*i]   + @normals.js[3*i] * 0.1
          @normal_points.js.push @vertices.js[3*i+1] + @normals.js[3*i+1] * 0.1
          @normal_points.js.push @vertices.js[3*i+2] + @normals.js[3*i+2] * 0.1
        gl.bindBuffer gl.ARRAY_BUFFER, @normal_points
        gl.bufferData gl.ARRAY_BUFFER, new Float32Array( @normal_points.js ), gl.STATIC_DRAW
        @normal_points.itemSize = 3
        @normal_points.numItems = @normal_points.js.length / @normal_points.itemSize

      gl.useProgram shader

      gl.uniform4f shader.uniforms["uAmbientColor"], 1, 1, 1, 1

      gl.bindBuffer gl.ARRAY_BUFFER, @normal_points
      gl.vertexAttribPointer shader.attributes["aVertexPosition"], @normal_points.itemSize, gl.FLOAT, false, 0, 0

      gl.uniformMatrix4fv shader.uniforms["uPMatrix"], false, pMatrix
      gl.uniformMatrix4fv shader.uniforms["uMVMatrix"], false, mvMatrix

      gl.drawArrays gl.LINES, 0, @normal_points.numItems


class Triangle extends Shape        
  constructor: (gl,center) ->
    super gl, center
    @vertices = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, @vertices
    @vertices.js =
      [
         0, 1, 0,
         -1, -1, 0,
         1, -1, 0,
      ]
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array( @vertices.js ), gl.STATIC_DRAW
    @vertices.itemSize = 3
    @vertices.numItems = @vertices.js.length / @vertices.itemSize
  
    @colors = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, @colors
    @colors.js =
      [
        1, 0, 0, 1,
        0, 1, 0, 1,
        0, 0, 1, 1,
      ]
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array( @colors.js ), gl.STATIC_DRAW
    @colors.itemSize = 4
    @colors.numItems = @colors.js.length / @colors.itemSize

    @drawtype = gl.TRIANGLES

class Square extends Shape        
  constructor: (gl,center) ->
    super gl, center
    @vertices = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, @vertices
    @vertices.js =
      [
        1, 1, 0,
        -1, 1, 0,
        1, -1, 0,
        -1, -1, 0,
      ]
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array( @vertices.js ), gl.STATIC_DRAW
    @vertices.itemSize = 3
    @vertices.numItems = @vertices.js.length / @vertices.itemSize
  
    @colors = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, @colors
    @colors.js =
      [
        1, 0.5, 1, 1,
        1, 0.5, 1, 1,
        1, 0.5, 1, 1,
        1, 0.5, 1, 1,
      ]
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array( @colors.js ), gl.STATIC_DRAW
    @colors.itemSize = 4
    @colors.numItems = @colors.js.length / @colors.itemSize

    @drawtype = gl.TRIANGLE_STRIP

class JSONModel extends Shape
  constructor: (gl,center,model_url) ->
    super gl, center

    shape = this

    @initialized = false

    getJSONMaybeDataURL model_url, (data) -> shape.initData gl, data

  validateData: (date) -> true

  initData: (gl, data) ->
      if ! @validateData( data )
        console.log "invalid data: " + data
        return

      @model = data

      @shininess = if @model.shininess then @model.shininess else 0

      @vertices = @buildBuffer gl, @model.vertices

      if ! @model.colors
        @model.colors = []
        for v in @model.vertices
          @model.colors.push [ 1, 1, 1, 1 ]

      @colors = @buildBuffer gl, @model.colors

      if ! @model.triangles
        @model.triangles = []
        for v in [ 0 .. @model.vertices.length / 3 ]
          @model.triangles.push [ 3 * v, 3 * v + 1, 3 * v + 2 ]

      @index = @buildElementBuffer gl, @model.triangles

      if ! @model.normals
        @model.normals = []
        for t in @model.triangles
          v1 = vec3.create @model.vertices[ t[1] ]
          v2 = vec3.create @model.vertices[ t[2] ]
          vec3.subtract v1, @model.vertices[ t[0] ]
          vec3.subtract v2, @model.vertices[ t[0] ]

          normal = vec3.create()
          vec3.cross v1, v2, normal
          vec3.normalize normal

          # Normal for each vertex
          @model.normals.push [ normal[0], normal[1], normal[2] ]
          @model.normals.push [ normal[0], normal[1], normal[2] ]
          @model.normals.push [ normal[0], normal[1], normal[2] ]

      @normals = @buildBuffer gl, @model.normals

      @drawtype = gl.TRIANGLES

      @initialized = true

class Pyramid extends Shape        
  constructor: (gl,center) ->
    super gl, center
    @vertices = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, @vertices
    @vertices.js =
      [
         # Front
         0, 1, 0,
         -1, -1, 1,
         1, -1, 1,
         # Right
         0, 1, 0,
         1, -1, 1,
         1, -1, -1,
         # Back
         0, 1, 0,
         1, -1, -1,
         -1, -1, -1,
         # Left
         0, 1, 0,
         -1, -1, -1,
         -1, -1, 1,
      ]
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array( @vertices.js ), gl.STATIC_DRAW
    @vertices.itemSize = 3
    @vertices.numItems = @vertices.js.length / @vertices.itemSize

    @normals = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, @normals
    div = 1 / Math.sqrt( 5 )
    @normals.js =
      [
         # Front
         0, 1 * div, 2 * div,
         0, 1 * div, 2 * div,
         0, 1 * div, 2 * div,
         # Right
         2 * div, 1 * div, 0,
         2 * div, 1 * div, 0,
         2 * div, 1 * div, 0,
         # Back
         0, 1 * div, -2 * div,
         0, 1 * div, -2 * div,
         0, 1 * div, -2 * div,
         # Left
         -2 * div, 1 * div, 0,
         -2 * div, 1 * div, 0,
         -2 * div, 1 * div, 0,
      ]
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array( @normals.js ), gl.STATIC_DRAW
    @normals.itemSize = 3
    @normals.numItems = @normals.js.length / @normals.itemSize
  
    @colors = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, @colors
    @colors.js =
      [
        # Front
        1, 0, 0, 1,
        0, 1, 0, 1,
        0, 0, 1, 1,
        # Right
        1, 0, 0, 1,
        0, 0, 1, 1,
        0, 1, 0, 1,
        # Back
        1, 0, 0, 1,
        0, 1, 0, 1,
        0, 0, 1, 1,
        # Left
        1, 0, 0, 1,
        0, 0, 1, 1,
        0, 1, 0, 1,
      ]
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array( @colors.js ), gl.STATIC_DRAW
    @colors.itemSize = 4
    @colors.numItems = @colors.js.length / @colors.itemSize

    @drawtype = gl.TRIANGLES

class Cube extends Shape        
  constructor: (gl,center) ->
    super gl, center
    @vertices = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, @vertices
    @vertices.js =
      [
        # Front
        1, 1, 1,
        -1, 1, 1,
        1, -1, 1,
        -1, -1, 1,
        # Back
        1, 1, -1,
        -1, 1, -1,
        1, -1, -1,
        -1, -1, -1,
        # Right
        1, 1, 1,
        1, -1, 1,
        1, 1, -1,
        1, -1, -1,
        # Left
        -1, 1, 1,
        -1, -1, 1,
        -1, 1, -1,
        -1, -1, -1,
        # Top
        1, -1, 1,
        -1, -1, 1,
        1, -1, -1,
        -1, -1, -1,
        # Bottom
        1, 1, 1,
        -1, 1, 1,
        1, 1, -1,
        -1, 1, -1,
      ]
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array( @vertices.js ), gl.STATIC_DRAW
    @vertices.itemSize = 3
    @vertices.numItems = @vertices.js.length / @vertices.itemSize

    @normals = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, @normals
    @normals.js =
      [
        # Front
        0, 0, 1,
        0, 0, 1,
        0, 0, 1,
        0, 0, 1,
        # Back
        0, 0, -1,
        0, 0, -1,
        0, 0, -1,
        0, 0, -1,
        # Right
        1, 0, 0,
        1, 0, 0,
        1, 0, 0,
        1, 0, 0,
        # Left
        -1, 0, 0,
        -1, 0, 0,
        -1, 0, 0,
        -1, 0, 0,
        # Top
        0, -1, 0,
        0, -1, 0,
        0, -1, 0,
        0, -1, 0,
        # Bottom
        0, 1, 0,
        0, 1, 0,
        0, 1, 0,
        0, 1, 0,
      ]
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array( @normals.js ), gl.STATIC_DRAW
    @normals.itemSize = 3
    @normals.numItems = @normals.js.length / @normals.itemSize
  
    @colors = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, @colors
    @colors.js =
      [
        # Front
        1, 0, 0, 1,
        1, 0, 0, 1,
        1, 0, 0, 1,
        1, 0, 0, 1,
        # Back
        1, 1, 0, 1,
        1, 1, 0, 1,
        1, 1, 0, 1,
        1, 1, 0, 1,
        # Right
        1, 0, 1, 1,
        1, 0, 1, 1,
        1, 0, 1, 1,
        1, 0, 1, 1,
        # Left
        0, 0, 1, 1,
        0, 0, 1, 1,
        0, 0, 1, 1,
        0, 0, 1, 1,
        # Top
        0, 1, 0, 1,
        0, 1, 0, 1,
        0, 1, 0, 1,
        0, 1, 0, 1,
        # Bottom
        1, 0.5, 0.5, 1,
        1, 0.5, 0.5, 1,
        1, 0.5, 0.5, 1,
        1, 0.5, 0.5, 1,
      ]
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array( @colors.js ), gl.STATIC_DRAW
    @colors.itemSize = 4
    @colors.numItems = @colors.js.length / @colors.itemSize

    @index = gl.createBuffer()
    gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, @index
    @index.js =
      [
        0, 1, 2,    1, 2, 3,     # Front
        4, 5, 6,    5, 6, 7,     # Back
        8, 9, 10,   9, 10, 11,   # Right
        12, 13, 14, 13, 14, 15,  # Left
        16, 17, 18, 17, 18, 19,  # Top
        20, 21, 22, 21, 22, 23,  # Bottom
      ]
    gl.bufferData gl.ELEMENT_ARRAY_BUFFER, new Uint16Array( @index.js ), gl.STATIC_DRAW
    @index.itemSize = 1
    @index.numItems = @index.js.length / @index.itemSize

    @drawtype = gl.TRIANGLES


class TextureCube extends Cube
  constructor: (gl,center,texture_url) ->
    super gl, center

    shape = this

    @texture = gl.createTexture()
    @texture.loaded = false;
    @texture.image = new Image();
    @texture.image.onload = -> shape.initTexture( gl )
    @texture.image.src = texture_url

    @texture_coord = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, @texture_coord
    @texture_coord.js =
      [
        # Front
        0, 0,
        1, 0,
        0, 1,
        1, 1,
        # Back
        1, 0,
        1, 1,
        0, 0,
        0, 1,
        # Right
        1, 0,
        1, 1,
        0, 0,
        0, 1,
        # Left
        0, 0,
        1, 0,
        0, 1,
        1, 1,
        # Top
        0, 1,
        0, 0,
        1, 1,
        1, 0,
        # Bottom
        1, 1,
        0, 1,
        1, 0,
        0, 0,
      ]
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array( @texture_coord.js ), gl.STATIC_DRAW
    @texture_coord.itemSize = 2
    @texture_coord.numItems = @texture_coord.js.length / @texture_coord.itemSize    

class Terrain extends Shape
    constructor: (gl,center,terrain_image_url) ->
      super gl, center

      shape = this

      @initialized = false

      @terrain_image = new Image()
      @terrain_image.onload = ->
        shape.buildHeight()
        shape.initialize( gl )
      @terrain_image.src = terrain_image_url

    buildHeight: ->
      canvas = document.createElement 'canvas'
      canvas.width = Math.min @terrain_image.width, 256
      canvas.height = Math.min @terrain_image.height, 256
      context = canvas.getContext( '2d' )
      context.drawImage( @terrain_image, 0, 0 )

      @width = canvas.width
      @height = canvas.height
      @heights = []

      for i in [ 0 .. canvas.width - 1 ]
        @heights[i] = []
        for j in [ 0 .. canvas.height - 1 ]
          @heights[i][j] = context.getImageData( i, j, 1, 1 ).data[0] / 16


    initialize: (gl) ->
      @vertices = gl.createBuffer()
      @vertices.js = []

      @normals = gl.createBuffer()
      @normals.js = []

      @colors = gl.createBuffer()
      @colors.js = []

      @index = gl.createBuffer()
      @index.js = []

      for i in [ 0 .. @width - 1 ]
        for j in [ 0 .. @height - 1 ]
          height = @heights[i][j]
          @vertices.js.push i, @heights[i][j], j

          prev_i = if i > 0 then i - 1 else i
          next_i = if i < @width - 1 then i + 1 else i
          prev_j = if j > 0 then j - 1 else j
          next_j = if j < @height - 1 then j + 1 else j

          vec_di = vec3.create [ next_i - prev_i, @heights[next_i][j] - @heights[prev_i][j], 0 ]
          vec_dj = vec3.create [ 0, @heights[i][next_j] - @heights[i][prev_j], next_j - prev_j ]

          normal = vec3.create( [ 0, 0, 0 ] )
          vec3.cross vec_dj, vec_di, normal
          vec3.normalize normal

          @normals.js.push normal[0], normal[1], normal[2]

          if height > 10
            @colors.js.push 1, 1, 1, 1 # White
          else if height > 5
            @colors.js.push 0.30, 0.20, 0.08, 1 # Brown
          else
            @colors.js.push 0.25, 0.6, 0.04, 1 # Green

          if i < @width - 1 && j < @height - 1
            base = i * @height + j
            @index.js.push base, base + 1, base + @height
            @index.js.push base + @height, base + 1, base + @height + 1

      gl.bindBuffer gl.ARRAY_BUFFER, @vertices
      gl.bufferData gl.ARRAY_BUFFER, new Float32Array( @vertices.js ), gl.STATIC_DRAW
      @vertices.itemSize = 3
      @vertices.numItems = @vertices.js.length / @vertices.itemSize

      gl.bindBuffer gl.ARRAY_BUFFER, @normals
      gl.bufferData gl.ARRAY_BUFFER, new Float32Array( @normals.js ), gl.STATIC_DRAW
      @normals.itemSize = 3
      @normals.numItems = @normals.js.length / @normals.itemSize

      gl.bindBuffer gl.ARRAY_BUFFER, @colors
      gl.bufferData gl.ARRAY_BUFFER, new Float32Array( @colors.js ), gl.STATIC_DRAW
      @colors.itemSize = 4
      @colors.numItems = @colors.js.length / @colors.itemSize

      gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, @index
      gl.bufferData gl.ELEMENT_ARRAY_BUFFER, new Uint16Array( @index.js ), gl.STATIC_DRAW
      @index.itemSize = 1
      @index.numItems = @index.js.length / @index.itemSize

      @drawtype = gl.TRIANGLES

      @initialized = true


class Axes extends Shape
  constructor: (gl,center) ->
    super gl, center

    @grid_points = []
    @grid_points.push [ 0, 0, -20 ]
    @grid_points.push [ 0, 0, 20 ]
    @grid_points.push [ 0, -20, 0 ]
    @grid_points.push [ 0, 20, 0 ]
    @grid_points.push [ -20, 0, 0 ]
    @grid_points.push [ 20, 0, 0 ]
    for i in [ -10 .. 10 ]
      @grid_points.push [ i, 0, -10 ]
      @grid_points.push [ i, 0, 10 ]
      @grid_points.push [ -10, 0, i ]
      @grid_points.push [ 10, 0, i ]

    @grid = @buildBuffer gl, @grid_points

  drawSolid: (gl,pMatrix,mvMatrix,shader) ->

  drawWire: (gl,pMatrix,mvMatrix,shader) ->
      gl.useProgram shader

      gl.uniform4f shader.uniforms["uAmbientColor"], 1, 1, 1, 1

      gl.bindBuffer gl.ARRAY_BUFFER, @grid
      gl.vertexAttribPointer shader.attributes["aVertexPosition"], @grid.itemSize, gl.FLOAT, false, 0, 0

      gl.uniformMatrix4fv shader.uniforms["uPMatrix"], false, pMatrix
      gl.uniformMatrix4fv shader.uniforms["uMVMatrix"], false, mvMatrix

      gl.drawArrays gl.LINES, 0, @grid.numItems
