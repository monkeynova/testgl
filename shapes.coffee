# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-
class Shape
  constructor: (gl) ->

  update: (elapsed) ->

  position: (m) ->

  initTexture: (gl) ->
    gl.bindTexture gl.TEXTURE_2D, @texture
    gl.pixelStorei gl.UNPACK_FLIP_Y_WEBGL, true
    gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, @texture.image
    gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST
    gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST
    gl.bindTexture gl.TEXTURE_2D, null
    @texture.loaded = true

  draw: (gl,pMatrix,mMatrix,color_shader,texture_shader) ->
    @position mMatrix

    shader = null

    if @texture
      shader = texture_shader
      gl.useProgram shader

      gl.bindBuffer gl.ARRAY_BUFFER, @texture_coord
      gl.vertexAttribPointer shader.vertexTextureAttribute, @texture_coord.itemSize, gl.FLOAT, false, 0, 0

      if @texture.loaded
        gl.activeTexture gl.TEXTURE0
        gl.bindTexture gl.TEXTURE_2D, @texture
        gl.uniform1i shader.samplerUniform, 0

    else
      shader = color_shader
      gl.useProgram shader

      gl.bindBuffer gl.ARRAY_BUFFER, @colors
      gl.vertexAttribPointer shader.vertexColorAttribute, @colors.itemSize, gl.FLOAT, false, 0, 0

    gl.bindBuffer gl.ARRAY_BUFFER, @vertices
    gl.vertexAttribPointer shader.vertexPositionAttribute, @vertices.itemSize, gl.FLOAT, false, 0, 0

    gl.uniformMatrix4fv shader.pMatrixUniform, false, pMatrix
    gl.uniformMatrix4fv shader.mvMatrixUniform, false, mMatrix

    if @index
      gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, @index
      gl.drawElements @drawtype, @index.numItems, gl.UNSIGNED_SHORT, 0
    else
      gl.drawArrays @drawtype, 0, @vertices.numItems

class Triangle extends Shape        
  constructor: (gl) ->
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
    @vertices.numItems = 3
  
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

  position: (m) ->
    mat4.translate m, [ -1.5, 0, -7 ]
    mat4.rotate m, @angle, [ 0, 1, 0 ]

  update: (elapsed) ->
    @angle = 2 * Math.PI * elapsed / 3

class Square extends Shape        
  constructor: (gl) ->
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

  update: (elapsed) ->
    @angle = 2 * Math.PI * elapsed / 5

  position: (m) ->
    mat4.translate m, [ 1.5, 0, -7 ]
    mat4.rotate m, @angle, [ 1, 0, 0 ]

class Pyramid extends Shape        
  constructor: (gl) ->
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

  position: (m) ->
    mat4.translate m, [ -1.5, 0, -8 ]
    mat4.rotate m, @angle, [ 0, 1, 0 ]

  update: (elapsed) ->
    @angle = 2 * Math.PI * elapsed / 3

class Cube extends Shape        
  constructor: (gl) ->
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

  update: (elapsed) ->
    @angle = 2 * Math.PI * elapsed / 5

  position: (m) ->
    mat4.translate m, [ 1.5, 0, -8 ]
    mat4.rotate m, @angle, [ 1, 1, 1 ]


class TextureCube extends Cube
  constructor: (gl,texture_url) ->
    super( gl )

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
