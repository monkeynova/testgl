# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-
$ ->
  canvas = document.getElementById 'viewport'
  status_box = $ '#status'
  gl = canvas.getContext 'experimental-webgl' if canvas.getContext
  program = null
  ticks = 0
  startDate = null
  paused = 0

  shapes = []
  pMatrix = null
  mMatrix = null

  matrixStack = []

  status = ( str ) ->
    status_box.empty()
    status_box.append str

  pushMatrix = ( m ) ->
    new_m = mat4.create()
    mat4.set m, new_m
    matrixStack[ m ] = [] if ! matrixStack[m]
    matrixStack[ m ].push new_m

  popMatrix = ( m ) ->
    throw "invalid pop" if matrixStack[m].length <= 0
    mat4.set matrixStack[m].pop(), m

  initialize = ->
    if ! gl
      status 'Init failed...'
      return

    gl.enable gl.DEPTH_TEST
    gl.clearColor 0.1, 0.1, 0.1, 1

    fragmentShader = getShader gl, 'shader-fs'
    vertexShader = getShader gl, 'shader-vs'

    program = gl.createProgram()
    gl.attachShader program, vertexShader
    gl.attachShader program, fragmentShader
    gl.linkProgram program

    if ( ! gl.getProgramParameter program, gl.LINK_STATUS )
      status 'Shader link failed'
      return;

    gl.useProgram program
    program.vertexPositionAttribute = gl.getAttribLocation program, "aVertexPosition"
    gl.enableVertexAttribArray program.vertexPositionAttribute

    program.vertexColorAttribute = gl.getAttribLocation program, "aVertexColor"
    gl.enableVertexAttribArray program.vertexColorAttribute

    program.pMatrixUniform = gl.getUniformLocation program, "uPMatrix"
    program.mvMatrixUniform = gl.getUniformLocation program, "uMVMatrix"

    startDate = new Date()

    shapes.push( new Pyramid gl )
    shapes.push( new Cube gl )

    status 'Initialized...'
    render()

  pause = -> paused = 1
  unpause = -> paused = 0; render

  render = ->
    return if paused

    reshape()
    gl.clear gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT

    now = new Date()

    elapsed = (now.getTime() - startDate.getTime()) / 1000;

    ticks++

    for s in shapes
      s.update elapsed

      pushMatrix mMatrix
      s.draw gl, pMatrix, mMatrix, program
      popMatrix mMatrix

    status 'Running... fps=' + Math.floor(ticks  / elapsed)

    requestAnimFrame render

  reshape = ->
    return if canvas.clientWidth == canvas.width && canvas.clientHeight == canvas.height
    canvas.width = canvas.clientWidth
    canvas.height = canvas.clientHeight
    gl.viewport 0, 0, canvas.width, canvas.height

    pMatrix = mat4.create()
    mat4.perspective 45, canvas.width / canvas.height, 0.1, 100, pMatrix

    mMatrix = mat4.create()
    mat4.identity mMatrix

  getShader = (gl, id) ->
    shaderScript = document.getElementById id
    return if ! shaderScript

    if ( shaderScript.type == "x-shader/x-fragment" )
      shader = gl.createShader( gl.FRAGMENT_SHADER )
    else if ( shaderScript.type == "x-shader/x-vertex" )
      shader = gl.createShader( gl.VERTEX_SHADER )
    else
      alert( "unknown type: " + shaderScript.type + " for id " + id )
      return

    gl.shaderSource shader, shaderScript.innerHTML
    gl.compileShader shader

    if ( ! gl.getShaderParameter( shader, gl.COMPILE_STATUS ) )
      alert gl.getShaderInfoLog( shader )
      return

    return shader      


  initialize()

class Shape
  constructor: (gl) ->

  update: (elapsed) ->

  position: (m) ->

  draw: (gl,pMatrix,mMatrix,color_shader) ->
    @position mMatrix

    gl.bindBuffer gl.ARRAY_BUFFER, @vertices
    gl.vertexAttribPointer color_shader.vertexPositionAttribute, @vertices.itemSize, gl.FLOAT, false, 0, 0

    gl.bindBuffer gl.ARRAY_BUFFER, @colors
    gl.vertexAttribPointer color_shader.vertexColorAttribute, @colors.itemSize, gl.FLOAT, false, 0, 0

    if @index
      gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, @index

      gl.uniformMatrix4fv color_shader.pMatrixUniform, false, pMatrix
      gl.uniformMatrix4fv color_shader.mvMatrixUniform, false, mMatrix

      gl.drawElements @drawtype, @index.numItems, gl.UNSIGNED_SHORT, 0
    else
      gl.uniformMatrix4fv color_shader.pMatrixUniform, false, pMatrix
      gl.uniformMatrix4fv color_shader.mvMatrixUniform, false, mMatrix

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
