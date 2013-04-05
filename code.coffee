# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-
$ ->
  canvas = document.getElementById 'viewport'
  status_box = $ '#status'
  gl = canvas.getContext 'experimental-webgl' if canvas.getContext
  program = null
  ticks = 0
  startDate = null

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
    gl.clearColor 0.3, 0.3, 0.3, 1

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

    status 'Initialized...'
    render()

  render = ->
    reshape()
    gl.clear gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT

    ticks++

    triangle = new Triangle gl
    square = new Square gl

    pMatrix = mat4.create()
    mat4.perspective 45, canvas.width / canvas.height, 0.1, 100, pMatrix

    mMatrix = mat4.create()
    mat4.identity mMatrix

    pushMatrix mMatrix

    triangle.draw gl, pMatrix, mMatrix, program, ticks

    popMatrix mMatrix

    pushMatrix mMatrix

    square.draw gl, pMatrix, mMatrix, program, ticks

    popMatrix mMatrix

    status 'Running... fps=' + Math.floor(ticks * 1000 / ((new Date).getTime() - startDate.getTime()));

    requestAnimFrame render

  reshape = ->
    return if canvas.clientWidth == canvas.width && canvas.clientHeight == canvas.height
    canvas.width = canvas.clientWidth
    canvas.height = canvas.clientHeight
    gl.viewport 0, 0, canvas.width, canvas.height

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

  update: ->

  draw: (gl,pMatrix,mMatrix,color_shader,ticks) ->

class Triangle extends Shape        
  constructor: (gl) ->
    @vertices = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, @vertices
    @vertices.js = [ 0, 1, 0,   -1, -1, 0,   1, -1, 0 ]
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array( @vertices.js ), gl.STATIC_DRAW
    @vertices.itemSize = 3
    @vertices.numItems = 3
  
    @colors = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, @colors
    @colors.js = [ 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 1 ]
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array( @colors.js ), gl.STATIC_DRAW
    @colors.itemSize = 4
    @colors.numItems = 3

  update: ->

  draw: (gl,pMatrix,mMatrix,color_shader,ticks) ->
    mat4.translate mMatrix, [ -1.5, 0, -7 ]

    mat4.rotate mMatrix, 2 * Math.PI * ticks / 180, [ 0, 1, 0 ]

    gl.bindBuffer gl.ARRAY_BUFFER, @vertices
    gl.vertexAttribPointer color_shader.vertexPositionAttribute, @vertices.itemSize, gl.FLOAT, false, 0, 0

    gl.bindBuffer gl.ARRAY_BUFFER, @colors
    gl.vertexAttribPointer color_shader.vertexColorAttribute, @colors.itemSize, gl.FLOAT, false, 0, 0

    gl.uniformMatrix4fv color_shader.pMatrixUniform, false, pMatrix
    gl.uniformMatrix4fv color_shader.mvMatrixUniform, false, mMatrix
    gl.drawArrays gl.TRIANGLES, 0, @vertices.numItems

class Square extends Shape        
  constructor: (gl) ->
    @vertices = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, @vertices
    @vertices.js = [ 1, 1, 0,   -1, 1, 0,   1, -1, 0, -1, -1, 0 ]
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array( @vertices.js ), gl.STATIC_DRAW
    @vertices.itemSize = 3
    @vertices.numItems = 4
  
    @colors = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, @colors
    @colors.js = [ 1, 0.5, 1, 1, 1, 0.5, 1, 1, 1, 0.5, 1, 1, 1, 0.5, 1, 1 ]
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array( @colors.js ), gl.STATIC_DRAW
    @colors.itemSize = 4
    @colors.numItems = 4

  update: ->

  draw: (gl,pMatrix,mMatrix,color_shader,ticks) ->
    mat4.translate mMatrix, [ 1.5, 0, -7 ]

    mat4.rotate mMatrix, 2 * Math.PI * ticks / 360, [ 1, 0, 0 ]

    gl.bindBuffer gl.ARRAY_BUFFER, @vertices
    gl.vertexAttribPointer color_shader.vertexPositionAttribute, @vertices.itemSize, gl.FLOAT, false, 0, 0

    gl.bindBuffer gl.ARRAY_BUFFER, @colors
    gl.vertexAttribPointer color_shader.vertexColorAttribute, @colors.itemSize, gl.FLOAT, false, 0, 0

    gl.uniformMatrix4fv color_shader.pMatrixUniform, false, pMatrix
    gl.uniformMatrix4fv color_shader.mvMatrixUniform, false, mMatrix
    gl.drawArrays gl.TRIANGLE_STRIP, 0, @vertices.numItems
