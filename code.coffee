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
    requestAnimFrame render
    reshape()
    gl.clear gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT

    ticks++

    triangle = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, triangle
    tVertices = [ 0, 1, 0,   -1, -1, 0,   1, -1, 0 ]
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array( tVertices ), gl.STATIC_DRAW
    triangle.itemSize = 3
    triangle.numItems = 3

    tri_colors = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, tri_colors
    tColors = [ 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 1 ]
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array( tColors ), gl.STATIC_DRAW
    tri_colors.itemSize = 4
    tri_colors.numItems = 4

    square = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, square
    sVertices = [ 1, 1, 0,   -1, 1, 0,   1, -1, 0, -1, -1, 0 ]
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array( sVertices ), gl.STATIC_DRAW 
    square.itemSize = 3
    square.numItems = 4

    sq_colors = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, sq_colors
    sColors = [ 1, 0.5, 1, 1, 1, 0.5, 1, 1, 1, 0.5, 1, 1, 1, 0.5, 1, 1 ]
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array( sColors ), gl.STATIC_DRAW
    sq_colors.itemSize = 4
    sq_colors.numItems = 4

    pMatrix = mat4.create()
    mat4.perspective 45, canvas.width / canvas.height, 0.1, 100, pMatrix

    mMatrix = mat4.create()
    mat4.identity mMatrix

    pushMatrix mMatrix

    mat4.translate mMatrix, [ -1.5, 0, -7 ]

    mat4.rotate mMatrix, 2 * Math.PI * ticks / 180, [ 0, 1, 0 ]

    gl.bindBuffer gl.ARRAY_BUFFER, triangle
    gl.vertexAttribPointer program.vertexPositionAttribute, triangle.itemSize, gl.FLOAT, false, 0, 0

    gl.bindBuffer gl.ARRAY_BUFFER, tri_colors
    gl.vertexAttribPointer program.vertexColorAttribute, tri_colors.itemSize, gl.FLOAT, false, 0, 0

    gl.uniformMatrix4fv program.pMatrixUniform, false, pMatrix
    gl.uniformMatrix4fv program.mvMatrixUniform, false, mMatrix
    gl.drawArrays gl.TRIANGLES, 0, triangle.numItems

    popMatrix mMatrix

    pushMatrix mMatrix

    mat4.translate mMatrix, [ 1.5, 0, -7 ]

    mat4.rotate mMatrix, 2 * Math.PI * ticks / 360, [ 1, 0, 0 ]

    gl.bindBuffer gl.ARRAY_BUFFER, square
    gl.vertexAttribPointer program.vertexPositionAttribute, square.itemSize, gl.FLOAT, false, 0, 0

    gl.bindBuffer gl.ARRAY_BUFFER, sq_colors
    gl.vertexAttribPointer program.vertexColorAttribute, sq_colors.itemSize, gl.FLOAT, false, 0, 0

    gl.uniformMatrix4fv program.pMatrixUniform, false, pMatrix
    gl.uniformMatrix4fv program.mvMatrixUniform, false, mMatrix
    gl.drawArrays gl.TRIANGLE_STRIP, 0, square.numItems

    popMatrix mMatrix

    status 'Running... fps=' + Math.floor(ticks * 1000 / ((new Date).getTime() - startDate.getTime()));

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
